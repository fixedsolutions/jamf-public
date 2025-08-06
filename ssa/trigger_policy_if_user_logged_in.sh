#!/bin/bash

# mac@SSA
# Trigger Policy if User Logged In
# Dheeraj Vasishta, Fixed Solutions/ISSI/Leidos/SSA, 2025
# fixed.works  |  github.com/fixedsolutions
# Version 1.0

### RELEASE NOTES ###
# Release History:
# - 1.0:  Initial release.

### KNOWN BUGS AND ISSUES ###
# - None at present.

### OVERVIEW ###
# This script checks to see if a user is logged in to the machine. If not, it
# quits; if so, then it triggers whatever policy name has been passed to it.

### VARIABLES ###

policyTrigger=$4
loggedInUser=$( stat -f '%Su' /dev/console )

if [ $loggedInUser = "root" ];
then
	echo "No user is currently logged in; exiting."
	exit 1
else
	jamf policy -trigger $policyTrigger
fi

exit 0
