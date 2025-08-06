#!/bin/bash

# mac@SSA
# PIV Pairing Script - Self Service
# Dheeraj Vasishta, Fixed Solutions/ISSI/Leidos/SSA, 2025
# www.fixed.works
# Version 1.1

### RELEASE NOTES ###
# Release History:
# - 1.1:  Added pairing status check and username identification, as well as more user feedback.
# - 1.0:  Initial release.

### KNOWN BUGS AND ISSUES ###
# This section intentionally left blank.

### OVERVIEW ###
# This script allows the user to manually initiate the smart card pairing prompt.
# Because admin access is required to do so, and we do not generally give admin
# access to end users, this script temporarily elevates the user to admin, allows
# the pairing process to run, then demotes them back to a standard user afterwards.
# Meanwhile, if the user DID have admin access beforehand, it notes this and does
# NOT demote them afterwards.

### SCRIPT CONTENTS ###

### Parameters###
userToModify=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

###Variables###
adminGroup="admin"
pivFirstName="$(sc_auth identities | grep "Certificate For PIV Authentication" | awk -F ' ' '{print $6}')"
pivFirstName="${pivFirstName:1}"
pivLastName="$(sc_auth identities | grep "Certificate For PIV Authentication" | awk -F ' ' '{print $7}')"
pivFullName="$pivFirstName $pivLastName"
localFullName="$(id -P $(stat -f%Su /dev/console) | cut -d : -f 8)"

declare demoteUserAfter="YES"

###Functions###

function DetermineCurrentAdminStatus {

	demoteUserAfter="YES"

	echo "Checking if ${userToModify} is currently a member of ${adminGroup}."
	/usr/sbin/dseditgroup -o checkmember -m "${userToModify}" "${adminGroup}" &> /dev/null
	currentAdminStatus=$?
	
	if [[ ${currentAdminStatus} == 0 ]] ; then
		echo "${userToModify} is currently an admin; will NOT demote after pairing."
			demoteUserAfter="NO"
	elif [[ ${currentAdminStatus} == 67 ]] ; then
		echo "${userToModify} is not an admin; WILL demote after pairing."
			demoteUserAfter="YES"
	elif [[ ${currentAdminStatus} == 64 ]] ; then
		echo "ERROR - Unable to locate user record for ${userToModify}."
		
	else
		echo "An unknown error occurred when checking Administrator status of ${userToModify}; exiting"
	fi
	
}

function PromoteUserToAdmin {

	echo "Starting promote workflow." ;
	DetermineCurrentAdminStatus
	
	if [[ ${currentAdminStatus} == 0 ]] ; then
		echo "${userToModify} is already a member of ${adminGroup}; no promotion action to take."
		
	elif [[ ${currentAdminStatus} == 67 ]] ; then
		echo "${userToModify} is not a member of ${adminGroup}; promoting user now."
		/usr/sbin/dseditgroup -o edit -a "${userToModify}" -t user "${adminGroup}" &> /dev/null
		/usr/sbin/dseditgroup -o checkmember -m "${userToModify}" "${adminGroup}" &> /dev/null
		updatedGroupMembership=$?
		
		if [[ ${updatedGroupMembership} == 0 ]] ; then
			echo "${userToModify} is now a member of ${adminGroup} via promotion."
		else
			echo "Error adding ${userToModify} to the ${adminGroup} group."
		fi
		
	fi
	
	echo "Completed Promote Account Workflow." ;
	
}

function DemoteUserToStandard {

	echo "Starting Demote Account Workflow." ;
	DetermineCurrentAdminStatus
	
	if [[ ${currentAdminStatus} == 67 ]] ; then
		echo "${userToModify} is not a member of ${adminGroup}; no demotion actions taken."
		
	elif [ ${currentAdminStatus} == 0 ] && [ $demoteUserAfter == "YES" ] ; then
		echo "${userToModify} is currently a member of ${adminGroup}; demoting user now."
		/usr/sbin/dseditgroup -o edit -d "${userToModify}" -t user "${adminGroup}" &> /dev/null
		/usr/sbin/dseditgroup -o checkmember -m "${userToModify}" "${adminGroup}" &> /dev/null
		updatedGroupMembership=$?
		
		if [[ ${updatedGroupMembership} == 67 ]] ; then
			echo "${userToModify} successfully removed from ${adminGroup} via demotion."
		else
			echo ${updatedGroupMembership}
			echo "Error removing ${userToModify} from ${adminGroup}."
		fi
		
	fi
	
	echo "Completed Demote Account Workflow." ;
	
}

function PairPIV {

	sudo -u "${userToModify}" sc_auth pairing_ui -v -f -s enable
	
	while [[ -z $(sc_auth identities | grep "Paired") ]]
	do
		scPairingCheck=$(sc_auth identities | grep "Paired")
	done
	
	dialog --notification --title "Smart Card Pairing" --message "$pivFullName's PIV card identity has been paired with the local account $localFullName."

}

###Script Execution###

if sc_auth identities | grep -q 'Paired identities which are used for authentication:';
then
	pivFirstName="$(sc_auth identities | grep "Certificate For PIV Authentication" | awk -F ' ' '{print $8}')"
	pivFirstName="${pivFirstName:1}"
	pivLastName="$(sc_auth identities | grep "Certificate For PIV Authentication" | awk -F ' ' '{print $9}')"
	pivFullName="$pivFirstName $pivLastName"
	dialog --title none --icon none --messagefont "size=14" --height 100 --width 475 --message "The PIV identity **$pivFullName** is already paired to the current local account."
	exit 0
else
	DetermineCurrentAdminStatus
	PromoteUserToAdmin
	PairPIV
fi

if [[ $demoteUserAfter=="YES" ]] ;
then
	echo "Value is $demoteUserAfter"
	DemoteUserToStandard
else
	echo "Value is $demoteUserAfter"
	exit 0
fi

exit 0
