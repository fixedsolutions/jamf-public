#!/bin/bash

# mac@SSA
# Cisco Secure Client Default VPN Entry
# Dheeraj Vasishta, Fixed Solutions/ISSI/Leidos/SSA, 2025
# www.fixed.works
# Version 1.0

### RELEASE NOTES ###
# Release History:
# - 1.0:  Initial release.

### KNOWN BUGS AND ISSUES ###
# - None.

### OVERVIEW ###
# This script creates a small settings file in the user's home directory that
# allows for the VPN field of Cisco Secure Client's VPN module to be pre-populated.
# The value of the VPN host is passed to this script through the variable in $4.

### VARIABLES ###
VPN_HOST=$4
LOGGED_IN_USER="$(id -P $(stat -f%Su /dev/console) | cut -d : -f 1)"

### FUNCTIONS ###

function createVPNDirectory {
	echo "Creating Cisco VPN settings directory in $LOGGED_IN_USER home directory."
	mkdir /Users/$LOGGED_IN_USER/.vpn
}

function createVPNFile {
	echo "Generating VPN settings file."
	echo "<?xml version="1.0" encoding="UTF-8"?>
<AnyConnectPreferences>
<DefaultHostName>$VPN_HOST</DefaultHostName>
</AnyConnectPreferences>" >> /Users/$LOGGED_IN_USER/.vpn/.anyconnect
	
}

function setPermissions {
	echo "Modifying file permissions."
	chown -R $LOGGED_IN_USER:staff /Users/$LOGGED_IN_USER/.vpn
	chmod a+r /Users/$LOGGED_IN_USER/.vpn/.anyconnect
}

### SCRIPT CONTENTS ###
createVPNDirectory
createVPNFile
setPermissions
exit 0
