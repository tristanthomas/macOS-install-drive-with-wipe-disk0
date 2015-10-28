#!/bin/sh

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# This script creates a bootable OS X USB install drive and downloads the wipe-disk0.sh script to the USB drive.

# WARNING: The wipe-disk0.sh script wipes disk0 if executed. It should only be executed under OS X Recovery from a bootable OS X USB install drive.

# Verify that the Install OS X app exists
CODENAME=El\ Capitan
OSX_INSTALLER=$(ls /Applications| grep -s Install\ OS\ X\ "$CODENAME" | sed 's/.app//')
if [[  "${OSX_INSTALLER}" == "" ]] ; then
	CODENAME_CLEAN=$(echo "$CODENAME" | sed 's/\\//g')
	echo "\nPlease download the Install OS X "$CODENAME_CLEAN" app from the App Store then run this script again."
	exit 134
fi

# List of attached drives
DRIVE_LIST=$(diskutil list | grep /dev/disk)

# Locate attached USB drives
USB_COUNT=0
for DRIVE in $DRIVE_LIST ; do
	CURRENT_DRIVE=$(diskutil info $DRIVE | grep Protocol | grep USB | awk '{print $2}')
	if [[ "${CURRENT_DRIVE}" == "USB" ]] ; then
		((USB_COUNT++))
		TARGET=$(echo $DRIVE)
	fi
done

# This script will exit if there isn't only one USB drive attached
case "$USB_COUNT" in
	0)
	echo "\nUSB drive not detected.\n"
	exit 135
	;;
	1)
	echo "\nDetected USB drive $TARGET\n"
	;;
	*)
	echo "\nPlease make sure there's only one USB drive attached then run this script again.\n"
	exit 136
	;;
esac

# Display the target USB drive name, size, and partitions
diskutil info $TARGET | grep -A 14 "Device / Media Name:" | sed '/Volume\ Name/,/SMART\ Status/d' | head -n 4 | awk '$1=$1' | sed G
diskutil list $TARGET | tail -n +2

# Confirm to proceed with formatting the target USB drive
echo "\nWARNING: Formatting will erase all data on $TARGET. Type \"YES\" to format this USB drive.\n"
read CONTINUE
if [[ "${CONTINUE}" == "YES" ]] ; then
	diskutil partitionDisk $TARGET GPT JHFS+ "wipe" 0b || {
		echo "Failed to format the target USB drive ${TARGET[$SELECT]}"
		exit 137
	}
	echo "\nTo proceed, enter your password.\n"
	sudo /Applications/Install\ OS\ X\ "$CODENAME".app/Contents/Resources/createinstallmedia --volume /Volumes/wipe --applicationpath /Applications/Install\ OS\ X\ "$CODENAME".app --nointeraction || {
		echo "\nFailed to create a bootable OS X USB install drive. Please try again."
		exit 138
	}
	curl -s -o /Volumes/Install\ OS\ X\ "$CODENAME"/wipe-disk0.sh https://raw.githubusercontent.com/tristanthomas/mac-wipe-disk0/master/wipe-disk0.sh || {
		echo "\nFailed to download the wipe-disk0.sh script. Please connect to the Internet then run this script again."
		exit 139
	}
	chmod +x /Volumes/Install\ OS\ X\ "$CODENAME"/wipe-disk0.sh
else
	echo "\nA confirmation to proceed was not provided. The USB drive ${TARGET[$SELECT]} was not modified.\n"
	exit 140
fi
