#!/bin/bash

# mac@SSA
# IP Geolocation for Jamf Pro
# Dheeraj Vasishta, Fixed Solutions/ISSI/Leidos/SSA, 2025
# www.fixed.works
# Version 1.0

# Based on original code by La Clémentine and William Smith
# See their original credits below.

# Modified by Dheeraj Vasishta to deal with being in a proxied environment (SSAnet) and tweaking
# some code to reflect OS evolution and the use of nscurl instead of curl.
# Works as of macOS Sequoia 15.4.

### RELEASE NOTES ###
# Release History:
# - 1.0:  First release

### FIXES/ENHANCEMENTS ###
# This section intentionally left blank.

### KNOWN BUGS AND ISSUES ###
# This section intentionally left blank.

### OVERVIEW ###
# This script grabs the machine's current public IP address, then runs a query to find the
# geographic location of the computer.

### ORIGINAL CREDITS FROM THE LA CLEMENTINE SCRIPT THIS WAS BASED ON
#
#            Created by : La Clémentine · https://medium.com/@laclementine/
#         Original code : William Smith · https://gist.github.com/talkingmoose/7d1bf4f884ca08f95fd3baf0014fc639
#         Last Modified : 2023-08-19
#               Version : 1.0
#           Tested with : macOS Ventura 13.5.1
#
###

# The xpath tool changed in Big Sur
xpath() {
 if [[ $( /usr/bin/sw_vers -buildVersion) > "20A" ]]; then
  /usr/bin/xpath -e "$@"
 else
  /usr/bin/xpath "$@"
 fi
}

# Get public IP 
echo "Fetching IP from AWS"
PUBLIC_IP=$(nscurl --max-time 5 -L https://checkip.amazonaws.com)

if [ "$PUBLIC_IP" = "" ]; then
 echo "Fetching IP from v4.ipv6-test.com"
 PUBLIC_IP=$(nscurl --max-time 5 -L http://v4.ipv6-test.com/api/myip.php)
fi

if [ "$PUBLIC_IP" = "" ]; then
 echo "Fetching IP from ipinfo.io"
 PUBLIC_IP=$(nscurl --max-time 5 -L https://ipinfo.io/ip)
fi

if [ "$PUBLIC_IP" = "" ]; then
 echo "Fetching IP from ifconfig.me"
 PUBLIC_IP=$(nscurl --max-time 5 -L ifconfig.me)
fi

if [ "$PUBLIC_IP" = "" ]; then
 echo "Fetching IP has failed. Abort, Abort!"
 exit 1
else
 echo "Public IP is $PUBLIC_IP"
fi

# Read old IP
if [ -e "/Users/Shared/ip_location.plist" ]; then
 OLD_PUBLIC_IP=$(defaults read "/Users/Shared/ip_location.plist" "ip")
 echo "Old public IP is $OLD_PUBLIC_IP"
else
 echo "There is no old records"
fi

if [ "$PUBLIC_IP" = "$OLD_PUBLIC_IP" ]; then
 echo "IPs are the same. Saving an API query. Exit."
 exit 0
else 
 echo "IPs are different. Proceed."
fi

# Get GeoIP data
locationData=$( /usr/bin/nscurl http://ip-api.com/xml/$PUBLIC_IP \
--max-time 10  )

locationPieces=( "query country countryCode regionName city zip lat lon timezone isp org as" )

for anItem in $locationPieces
do
 export $anItem="$(xpath "/query/$anItem/text()" 2>/dev/null <<< "$locationData")"
done

echo "Query is $query"
defaults write "/Users/Shared/ip_location.plist" ip -string "$query"

echo "Country is $country"
defaults write "/Users/Shared/ip_location.plist" country -string "$country"

echo "CountryCode is $countryCode"
defaults write "/Users/Shared/ip_location.plist" countryCode -string "$countryCode"

echo "Region Name is $regionName"
defaults write "/Users/Shared/ip_location.plist" regionName -string "$regionName"

echo "City is $city"
defaults write "/Users/Shared/ip_location.plist" city -string "$city"

echo "ZIP is $zip"
defaults write "/Users/Shared/ip_location.plist" zip -string "$zip"

echo "Latitude is $lat"
defaults write "/Users/Shared/ip_location.plist" latitude -string "$lat"

echo "Longitude is $lon"
defaults write "/Users/Shared/ip_location.plist" longitude -string "$lon"

echo "Timezone is $timezone"
defaults write "/Users/Shared/ip_location.plist" timezone -string "$timezone"

echo "ISP is $isp"
defaults write "/Users/Shared/ip_location.plist" isp -string "$isp"

echo "Organization is $org"
defaults write "/Users/Shared/ip_location.plist" org -string "$org"

echo "AS is $as"
defaults write "/Users/Shared/ip_location.plist" as -string "$as"

# Optional : Hide file and make it readable
# chflags hidden "/Users/Shared/ip_location.plist"
chmod 444 "/Users/Shared/ip_location.plist"

exit 0
