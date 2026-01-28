#!/bin/zsh

# mac@SSA
# Post-Enrollment Welcome Doc Provisioning
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
# This is a simple script that copies the "Welcome to Your Mac" document from
# its standard distribution point (within in the top-lvel Library folder) to
# the Desktop of the currently logged in user. It's designed to be launched by
# Outset as run-once, privileged (root) policy.

### SCRIPT CONTENTS ###
jamf policy -trigger postSetup

exit 0
