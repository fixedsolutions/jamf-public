#!/bin/bash

# mac@SSA
# JSS Machine Record Population Script
# Dheeraj Vasishta, Fixed Solutions/ISSI/Leidos/SSA, 2025
# fixed.works  |  github.com/fixedsolutions
# Version 1.0.1

### RELEASE NOTES ###
# Release History:
# - 1.0.1:  Minor cleanup and refinement.
# - 1.0:  Initial release.

### KNOWN BUGS AND ISSUES ###
# - This script relies on the admin correctly entering the user's real name when
#   creating their account on the machine. If there's a misspelling, or the name
#   is far too common to come up in a simple query of the OrgChart database, then
#   it will fail to pull the additional details. Being able to query the PIN, for
#   instance, would be a guaranteed method, but at present there's no apparent way
#   to grab the user's PIN from their PIV card.

### OVERVIEW ###
# This script polls the user's PIV card to grab information about their identity,
# then leverages SSA's Org Chart website API to pull additional inforation about
# them based on their PIV details. It then processes the text and populates the
# user's computer record on the Jamf Pro server with these details.

### VARIABLES ###
pivStatus=$(security list-smartcards)

### FUNCTIONS ###

function FetchLocalAccountDetails {
	echo "Fetching local account details."
	userFullName="$(id -P $(stat -f%Su /dev/console) | cut -d : -f 8)"
	userShortName="$(id -P $(stat -f%Su /dev/console) | cut -d : -f 1)"
	echo "- Local account is $userFullName ($userShortName)."
}

function FetchPIVDetails {
	echo "Fetching PIV details."
	pivFirstName="$(sc_auth identities | grep "Certificate For PIV Authentication" | awk -F ' ' '{print $6}')"
	if sc_auth identities | grep -q 'Paired identities which are used for authentication:';
	then
		pivFirstName="$(sc_auth identities | grep "Certificate For PIV Authentication" | awk -F ' ' '{print $8}')"
		pivFirstName="${pivFirstName:1}"
		pivLastName="$(sc_auth identities | grep "Certificate For PIV Authentication" | awk -F ' ' '{print $9}')"
	else
		pivFirstName="${pivFirstName:1}"
		pivLastName="$(sc_auth identities | grep "Certificate For PIV Authentication" | awk -F ' ' '{print $7}')"
	fi

	pivFullName="$pivFirstName $pivLastName"

	userFullNameForQuery="$pivFirstName%20$pivLastName"
	orgchartFullDetail=$(curl -X GET "https://orgchart.ssa.gov/api/v1/people/caprs/$userFullNameForQuery")
	userPIN=$(echo $orgchartFullDetail | jq -r '.pin')
	userFullName=$(echo $orgchartFullDetail | jq -r '.full_name')
	userEmail=$(echo $orgchartFullDetail | jq -r '.email')
	userOfficeCode=$(echo $orgchartFullDetail | jq -r '.office_code')
	userParentOfficeTree=$(echo $orgchartFullDetail | jq -r '.office_code_tree')
	officeFullDetail=$(curl -X GET "https://orgchart.ssa.gov/api/v1/offices/$userOfficeCode" -H  "accept: */*")
	userOfficeName=$(echo $officeFullDetail | jq -r '.name')
	userParentOfficeCode=$(echo $userParentOfficeTree | rev | cut -d'\' -f2 | rev)
	parentOfficeFullDetail=$(curl -X GET "https://orgchart.ssa.gov/api/v1/offices/$userParentOfficeCode" -H  "accept: */*")
	userParentOfficeName=$(echo $parentOfficeFullDetail | jq -r '.name')

	echo "PIV card gives the following additional details:"
	echo "- Full user name is $userFullName."
	echo "- PIN is $userPIN."
	echo "- Email address is $userEmail."
	echo "- Office name is $userOfficeName."
	echo "- Parent of that office is $userParentOfficeName."
}


### SCRIPT CONTENTS ###

FetchLocalAccountDetails
# Determine if a PIV card is inserted. If not, proceed with local user information only.
if [[ "$pivStatus" == "" ]] ; then
	userEmail="Waiting for OrgChart API query"
	userOfficeName="Waiting for OrgChart API query"
	userParentOfficeName="Waiting for OrgChart API query"
	userPIN="Waiting for OrgChart API query"
	echo "PIV card is not present; will proceed with local account information only."
	/usr/local/bin/jamf \
		recon \
		-endUsername "$userShortName" \
		-realname "$userFullName" \
		-email "$userEmail" \
		-department "$userOfficeName" \
		-building "$userParentOfficeName" \
		-room "$userPIN"
	exit 1
else
	FetchPIVDetails
fi

# We're using Jamf Pro's built-in categories, so "department" will be the user's
# actual office/division, "building 'will be the office/division above that, and
# "room" will have to be used for the user's PIN. While we could create EAs for
# each of these, we wouldn't be able to update them with the jamf binary, and
# using the Jamf API to update it only works when off SSAnet (due to the proxy
# requirement, curl not playing nice with the proxy, and nscurl not supporting
# HTTP PATCH.

/usr/local/bin/jamf \
	recon \
	-endUsername "$userShortName" \
	-realname "$userFullName" \
	-email "$userEmail" \
	-department "$userOfficeName" \
	-building "$userParentOfficeName" \
	-room "$userPIN"
exit 0
