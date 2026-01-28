#!/bin/bash

# mac@SSA
# Network Location Creation Script
# Dheeraj Vasishta, Fixed Solutions/ISSI/Leidos/SSA, 2021-2025
# www.fixed.works
# Version 1.0

### RELEASE NOTES ###
# Release History:
# - 1.0:  First release (5/1/25)

### FIXES/ENHANCEMENTS ###
# This section intentionally left blank.

### KNOWN BUGS AND ISSUES ###
# This section intentionally left blank.

### OVERVIEW ###
# This script is triggered at enrollment to populate the default network settings with
# SSA's proxy information. It then creates a new network location with generic/factory
# settings that can be used when using the computer on any non-SSA connection or VPN.
# Afterwards, it examines the value passed to it in $4 to determine whether to switch the
# network location back to what it was before the script ran, or to explicitly switch to
# the newly created (non-SSA) location. (For enrollment, it'll be necessary to continue
# on a non-SSA connection.)


### VARIABLES ###
initiallocation=$(networksetup -getcurrentlocation)
servicesfile="/tmp/networkservices"
locationsresult=$(networksetup -listlocations | grep "Telework/Off-Net")
proxy="access.lb.ssa.gov"
proxybypass="10.* *.*.ssa.gov 172.16.*.* 172.17.*.* 172.18.*.* 172.19.*.* 172.20.*.* 172.21.*.* 172.22.*.* 172.23.*.* 172.24.*.* 172.25.*.* 172.26.*.* 172.27.*.* 172.28.*.* 172.29.*.* 172.30.*.* 172.31.*.* cmwas* localhost Sharepoint.ssa.gov datamart-login.nbc.gov *.apps-local.haivision.com *.staging.purple.us *.staging.purplevrs.com *.prod.purple.us cloudvp.purplevrs.com"
endinglocation=$4


### FUNCTIONS ###
function GrabNetworkServicesInfo {

	echo "Finding local network interfaces."
	networksetup -listallnetworkservices > $servicesfile
	sed -i -e '1d' $servicesfile

}

function AddProxyInformation {

	echo "Switching to Default network location."
	networksetup -switchtolocation "Default"

	while IFS= read -r line || [ -n "$line" ]; do
		networksetup -setwebproxy "$line" $proxy 80
		networksetup -setsecurewebproxy "$line" $proxy 80
		networksetup -setproxybypassdomains "$line" "$proxybypass"
		echo "Configured proxy settings for: $line"
	done < $servicesfile

	rm $servicesfile

}

function CreateOffNetLocation {

	if [[ -z "$locationsresult" ]]; then
		echo "Creating offnet network location."
		networksetup -createlocation "Telework/Off-Net" populate
	else
		echo "Offnet network location already exists."
	fi
}

function SwitchLocationBack {

	if [[ $endinglocation == "RETURN" ]] || [[ -z "$endinglocation" ]]; then
		echo "Switching back to initial network location."
		networksetup -switchtolocation $initiallocation
	elif [[ $endinglocation == "OFF" ]]; then
		echo "Switching to off-net/stock settings network location."
		networksetup -switchtolocation "Telework/Off-Net"
	elif [[ $endinglocation == "SSA" ]]; then
		echo "Switching to SSA (Default) location."
		networksetup -switchtolocation "Default"
	fi

}

### SCRIPT EXECUTION ###
GrabNetworkServicesInfo
AddProxyInformation
CreateOffNetLocation
SwitchLocationBack
