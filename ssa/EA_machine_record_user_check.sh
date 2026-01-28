#!/bin/zsh

# mac@SSA
# Extension Attribute - User Record Population Status
# Dheeraj Vasishta, Fixed Solutions/ISSI/Leidos/SSA, 2025
# fixed.works  |  github.com/fixedsolutions
# Version 1.0

### RELEASE NOTES ###
# Release History:
# - 1.0:  Initial release.

### KNOWN BUGS AND ISSUES ###
# This section intentionally left blank

### OVERVIEW ###
# This script checks the machine record on the JSS to determine whether it has
# been populated with their user data, or is still in "stock" condition (with no
# user data).

### FUNCTIONS ###

function checkResponseCode()	{
	httpErrorCodes="000 No HTTP code received
200 Request successful
201 Request to create or update object successful
400 Bad request
401 Authentication failed
403 Invalid permissions
404 Object/resource not found
409 Conflict
500 Internal server error"
	
	responseCode=${1: -3}
	code=$( /usr/bin/grep "$responseCode" <<< "$httpErrorCodes" )
# nscurl -i https://www.jamf.com | head -n 1 | sed 's/^HTTP\/2\.0 //'
	echo "$code"
}

function apiGET	{
	apiGetResponse=$( /usr/bin/nscurl \
	--header "Authorization: Bearer $token" \
	--header "$1" \
	--get \
	--output "%{http_code}" \
	"$2"
)
	
	codeCheck=$( checkResponseCode "$apiGetResponse" )
	
	if [[ $codeCheck != 2* ]]; then
		echo "Error while attempting to retrieve password."
		#kill -s TERM $TOP_PID
	else
		echo "${apiGetResponse%???}"
	fi
}


### VARIABLES ###

jamfProURL="https://desei.jamfcloud.com"
jamfProClientID="dheeraj"
jamfProClientSecret="juxNWtS33"

# put auth token stuff into a temporary file
echo "client_id=$jamfProClientID grant_type=client_credentials client_secret=$jamfProClientSecret" > /tmp/jamfProLogin.txt

# request auth token - Modified from Jamf's original script to use API v2 and API role/client instead of user/pass
authTokenResponse=$( /usr/bin/nscurl \
	--post \
	--upload /tmp/jamfProLogin.txt \
	"$jamfProURL/api/oauth/token/" )

checkResponseCode "$authTokenResponse"

# extract data from result
echo "Token is:  $token"
echo "Auth token is:  $authToken"
echo "Auth token response is:  $authTokenResponse"
authToken=${authTokenResponse%???}

# parse auth token
token=$( /usr/bin/plutil -extract access_token raw - <<< "$authToken" )
echo "Token is:  $token"

# get computer serial number so we can get its Jamf Pro ID in the next step
serialNumber=$( /usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk -F": " /"Serial Number"/'{ print $2 }' )

# get computer Jamf Pro ID so we can get computer management ID in the next step
computerGeneralXML=$( apiGET "Accept: text/xml" "$jamfProURL/JSSResource/computers/serialnumber/$serialNumber" )
jamfProComputerID=$( /usr/bin/xpath -e "/computer/general/id/text()" 2>/dev/null <<< "$computerGeneralXML" )








jamfProEmailAddress=$( nscurl '$jamfProURL/api/v1/computers-inventory-detail/$jamfProComputerID' -H 'accept: application/json' -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdXRoZW50aWNhdGVkLWFwcCI6IkdFTkVSSUMiLCJhdXRoZW50aWNhdGlvbi10eXBlIjoiSlNTIiwiZ3JvdXBzIjpbXSwic3ViamVjdC10eXBlIjoiSlNTX1VTRVJfSUQiLCJ0b2tlbi11dWlkIjoiMjliZTc3NTctZDMyZS00MWFmLThkYTUtODE1YzQyM2UwZjRlIiwibGRhcC1zZXJ2ZXItaWQiOi0xLCJzdWIiOiIxIiwiZXhwIjoxNzQ3NDEwNTk1fQ.wT2_t1QWv5-62kcdgJZeQE2-wt7gt_eArapMVJqZVJ0' | jq -r '.userAndLocation.email' )
