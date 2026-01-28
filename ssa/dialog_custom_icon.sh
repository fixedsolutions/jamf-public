#!/bin/bash

# mac@SSA
# swiftDialog Icon Replacement
# Dheeraj Vasishta, Fixed Solutions/ISSI/Leidos/SSA, 2025
# www.fixed.works
# Version 1.0

### RELEASE NOTES ###
# Release History:
# - 1.0:  Initial release.

### FIXES/ENHANCEMENTS ###
# This section intentionally left blank.

### KNOWN BUGS AND ISSUES ###
# This section intentionally left blank.

### OVERVIEW ###
# This is a simple script that grabs the icon for the Self Service application
# (which is customized to the SSA logo, at the time of this writing) and processes
# it to fit the requirements for swiftDialog to use it as its default alert icon.
# It must run before swiftDialog is installed in order to work, per the developer's
# docs. Script adapted from:
# https://github.com/swiftDialog/swiftDialog/wiki/Notifications#updating-the-default-notification-icon

### SCRIPT CONTENTS ###
temp_file=$(/usr/bin/mktemp)
/usr/bin/xxd -p -s 260 "$(defaults read /Library/Preferences/com.jamfsoftware.jamf self_service_app_path)"/Icon$'\r'/..namedfork/rsrc | /usr/bin/xxd -r -p > "$temp_file"
/bin/mkdir -p /Library/Application\ Support/Dialog
/usr/bin/sips -s format png "$temp_file" --out /Library/Application\ Support/Dialog/Dialog.png
