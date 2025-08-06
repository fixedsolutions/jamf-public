#!/bin/bash

# mac@SSA
# Xcode Runtime Post-Processing Script
# Dheeraj Vasishta, Fixed Solutions/ISSI/Leidos/SSA, 2025
# www.fixed.works
# Version 1.0

# Based on Apple's documentation for command-line installation (https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components#Install-downloaded-packages-from-the-command-line)

### RELEASE NOTES ###
# Release History:
# - 1.0:  Initial release.

### FIXES/ENHANCEMENTS ###
# This section intentionally left blank.

### KNOWN BUGS AND ISSUES ###
# This section intentionally left blank.

### OVERVIEW ###
# This is a quick and dirty script to process the Apple DMG file for iOS, tvOS, Vision OS,
# tvOS, or other runtime and install it within Xcode. This is necessary because SSA's firewall
# rules make it miserable (if not entirely impossible) to install the components from within
# the Xcode app's preferences. This should work until DOGE finishes ripping the copper out
# of the walls and puts us all out on the street.

### SCRIPT CONTENTS ###

# VARIABLES
DISKIMAGE=/Library/Application\ Support/JAMF/Waiting\ Room/$4

echo "Installing runtime from $DISKIMAGE"
xcodebuild -importPlatform "$DISKIMAGE"
exit 0
