#!/bin/zsh

cd /opt/cisco/anyconnect/bin
vpn_uninstall.sh
dart_uninstall.sh
isecompliance_uninstall.sh
iseposture_uninstall.sh
rm -Rf /opt/cisco/anyconnect
jamf Policy -trigger install_secure_client
