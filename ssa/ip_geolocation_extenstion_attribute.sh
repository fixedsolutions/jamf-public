#!/bin/bash

# mac@SSA
# IP Geolocation Extension Attribute
# Dheeraj Vasishta, Fixed Solutions/ISSI/Leidos/SSA, 2025
# www.fixed.works
# Version 1.0

# Based on original code by La Clémentine (https://medium.com/@laclementine/get-users-location-based-on-their-public-ip-b6a19b70437a)
# Modified by Dheeraj Vasishta to concatenate all the values into one output string.

### RELEASE NOTES ###
# Release History:
# - 1.0:  First release

### FIXES/ENHANCEMENTS ###
# This section intentionally left blank.

### KNOWN BUGS AND ISSUES ###
# This section intentionally left blank.

### OVERVIEW ###
# This EA leverages the data gathered by the IP Geolocation script and policy.

if [ -e "/Users/Shared/ip_location.plist" ]; then
	LOCATIONDATA=("country regionName city zip latitude longitude isp")
	for GEOIPDATA in $LOCATIONDATA
	do
		GEOIPDATA=$(defaults read "/Users/Shared/ip_location.plist" "$GEOIPDATA")
		LOCATION+="$GEOIPDATA,"
	done
	echo "<result>$(awk '{print substr($0,1,length($0)-1)}' <<< "$LOCATION")</result>"
else
	echo "<result>Unknown</result>"
fi

exit 0
