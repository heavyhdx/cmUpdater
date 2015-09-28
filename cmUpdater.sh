#!/bin/bash

#VARIABLES:

#------------------------------------------------------------------------------------------------------------------------------------------
DEVICE=victara		#put your Device-ID here, for example 'hammerhead' for Nexus 5 (without quotes)
#------------------------------------------------------------------------------------------------------------------------------------------
CMVERSION=12.1		#The CyanogenMod-Version you'd like to search for. Example: '11' (without quotes)
#------------------------------------------------------------------------------------------------------------------------------------------
UPDATECHANNEL=NIGHTLY	#Select the update channel you want

			#Most up-to-date (nightly updates)

			# NIGHTLY

			#Less frequently updated

			# STABLE
			# RC		(Release Candidate)
			# SNAPSHOT
			# MILESTONE
			# TEST		(Experimental)
#------------------------------------------------------------------------------------------------------------------------------------------
FILEPATH="./"		#The path where the script will download CyanogenMod and store backups
			#If you leave './' everything will go in the directory in which your terminal is opened
			# !! You NEED to make sure your path ends with / and you keep the quotes !!
#------------------------------------------------------------------------------------------------------------------------------------------
TWRPoptions=SDB 	#Options for the TWRP-backup/restore
			#Add partitions and options to your liking.

			#Make sure there are only upper case letters and no spaces, numbers or symbols!

			#Partitions:

			# S = System
			# D = Data
			# C = Cache
			# R = Recovery
			# B = Boot
			# A = Android secure
			# E = SD-Ext

			#Options:

			# O = use compression
			
			#Note: There is an option "M" that skips the MD5-generation when creating a backup
			#For some reason that same letter will enable MD5-verification when restoring a backup
			#So for safety's sake, MD5-generation and verification are ENABLED
			#If for some reason you want to disable it, add the letter M here and remove it at line 256 column 47
#------------------------------------------------------------------------------------------------------------------------------------------

#You can only search for updates if your device currently has the same device ID, CyanogenMod-version and update channel as specified above

#Check the end of the script for all other variables with comments

#------------------------------------------------------------------------------------------------------------------------------------------


start(){
clear
echo
read -p "___________________________________________________

What would you like to do?

-Search for CyanogenMod-updates ............... (1)

-Create a TWRP-backup ......................... (2)

-Restore a TWRP-backup ........................ (3)

-Update CyanogenMod in TWRP ................... (4)

-Clear Cache & Dalvik-Cache in TWRP ........... (5)

-Reboot your device ........................... (6)

-Remove old updates from your PC .............. (7)

-Exit ......................................... (e)

___________________________________________________

" -n 1 -r
		echo 
			if [[ $REPLY =~ ^[1]$ ]]; then
				versionVerifier
			fi
			if [[ $REPLY =~ ^[2]$ ]]; then
				backupCreator
			fi
			if [[ $REPLY =~ ^[3]$ ]]; then
				twrpRestorer
			fi
			if [[ $REPLY =~ ^[4]$ ]]; then
				cmUpdater
			fi
			if [[ $REPLY =~ ^[5]$ ]]; then
				read -p "This will wipe /cache/ and /data/dalvik-cache/, are you sure? (y/n)" -n 1 -r
				echo 
					if [[ $REPLY =~ ^[Yy]$ ]]; then
    						adb reboot recovery
						clearCache
					else
						start
					fi
				
			fi
			if [[ $REPLY =~ ^[6]$ ]]; then
				adb reboot
				start
			fi
			if [[ $REPLY =~ ^[7]$ ]]; then
				read -p "This will remove all updates from your PC, are you sure? (y/n)" -n 1 -r
				echo 
					if [[ $REPLY =~ ^[Yy]$ ]]; then
    						updateRemover
					else
						start
					fi
			fi
			if [[ $REPLY =~ ^[Ee]$ ]]; then
				echo
				echo "Exiting. Have a nice day!"
				exit
			fi
}

versionVerifier(){
clear
echo
	if [[ -n ${ADB} ]]; then
		echo "Update channel: $UPDATECHANNEL"
		echo
		echo "Installed: CM $ADB"
		updateChecker
	else
		echo 'error: Your specified CyanogenMod-version and the device-version differ. Exiting'
		exit
	fi
}


updateChecker(){
echo
	if [[ ${ADB} < ${CURL} ]]; then
		echo "Available: CM ${CURL}"
		echo
		echo "Update sha1: $SHA1"
		echo
		echo "Update URL: $WGETURL"
		echo
		
		read -p "Do you want to download the update? (y/n)" -n 1 -r
		echo 
			if [[ $REPLY =~ ^[Yy]$ ]]; then
    				updateDownloader
			else
				start
			fi
	else	
		echo
		echo 'No update is available.'
		sleep 5
		start
	fi
}

updateDownloader(){
echo
	if [ -f "${FILEPATH}cm-${CURL}.zip" ]; then
		read -p "Update found at ${FILEPATH} (cm-${CURL}.zip). Do you want to overwrite?" -n 1 -r
		echo 
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			updateDownloader2
		else
			start
		fi
	else
		mkdir -p ${FILEPATH}
		updateDownloader2
	fi
}

updateDownloader2(){
echo
wget ${WGETURL} -O "${FILEPATH}cm-${CURL}.zip"
#echo ${MD5} > "${FILEPATH}cm-${CURL}.zip.md5"
echo "Update downloaded!"
sleep 5
start
}

backupCreator(){
adb reboot recovery
echo
echo 'Waiting for device...'
${WAITFORDEVICE} shell twrp backup ${TWRPoptions} cmbackup
twrpBackup
}

twrpBackup(){
echo
read -p "Backup finished. Do you want to copy it to your PC and remove it from the device? (y/n)" -n 1 -r
echo 
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		rm -r ${FILEPATH}backup/
    		adb pull /sdcard/TWRP/BACKUPS/ "${FILEPATH}backup/"
		echo "This backup was created at" $(date) > ${FILEPATH}backup/date.txt
		adb shell rm -r /sdcard/TWRP/BACKUPS/
		echo
		echo 'Moved backups to the PC and removed them from the device.'
		sleep 2
		start
	else
		start
		
	fi
}

twrpRestorer(){
echo
	if [ -d "${FILEPATH}backup" ]; then
		echo "Backup found at ${FILEPATH}backup "
		cat "${FILEPATH}backup/date.txt"
		read -p "Are you sure you want to restore this backup? (y/n)" -n 1 -r
		echo 
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				twrpRestorer1
			else
				start
			fi
	else
		echo "No Backup found at ${FILEPATH}backup !"
		sleep 3
		start
	fi
}

twrpRestorer1(){
adb reboot recovery
echo "Waiting for device..."
echo
echo "Pushing backup to device..."
echo
${WAITFORDEVICE} push ${FILEPATH}backup/ /sdcard/TWRP/BACKUPS/
adb shell twrp restore cmbackup ${TWRPoptions}M
echo
echo "Backup restored."
read -p "Do you want to remove it from your device? (y/n)" -n 1 -r
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		adb shell rm -r /sdcard/TWRP/BACKUPS/
		echo
		echo 'Removed backup from the device.'
		sleep 3
		start
	else
		start
	fi
}

cmUpdater(){
	if [[ -f "${FILEPATH}cm-${CURL}.zip" ]]; then
		adb reboot recovery
		echo
		echo 'Waiting for device...'
		${WAITFORDEVICE} shell exit
		sleep 5
		#echo "Pushing MD5 to /sdcard/..."
		#adb push ${FILEPATH}cm-${CURL}.zip.md5 /sdcard/cm-${CURL}.zip.md5
		echo "Pushing 'cm-${CURL}.zip' to /sdcard/..."
		adb push ${FILEPATH}cm-${CURL}.zip /sdcard/cm-${CURL}.zip
		adb shell twrp install /sdcard/cm-${CURL}.zip
		adb shell rm /sdcard/cm-${CURL}.zip
		#adb shell rm /sdcard/cm-${CURL}.zip.md5
		read -p "Installation finished. Do you want clear cache and dalvik-cache? (recommended) (y/n)" -n 1 -r
		echo 
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				clearCache
			else
				start
			fi
	else
		echo
		echo "Update not found at ${FILEPATH}cm-${CURL}.zip! Did you download it?"
		sleep 5
		start
	fi
}

updateRemover(){
echo
	if ls ${FILEPATH}cm-* 1> /dev/null 2>&1; then
	#Checks if files are present and then redirects the command so that it doesn't generate any output.
		rm ${FILEPATH}cm-*
		echo "Updates removed!"
		sleep 2
		start
	else
		echo "No updates found."
		sleep 2
		start
	fi
}

clearCache(){
${WAITFORDEVICE} shell twrp wipe cache
adb shell twrp wipe dalvik
start
}

if adb shell cd /; then 
#Checks if your device is connected.
#If "adb shell cd /" returns an error, it will exit. If it doesn't, it will set all variables and continue.

	echo "Retrieving information. Please wait ..."
	
	URL='https://download.cyanogenmod.org/?device='${DEVICE}'&type='${UPDATECHANNEL}
	#Gets the URL of your device's CyanogenMod-page

	VERSION_REGEX="${CMVERSION}-........-${UPDATECHANNEL}(-[^-]*){0,1}-${DEVICE}"
	#Puts together your options to form a string that is used to search for updates.
	
	ADB="$(adb shell grep ${CMVERSION}-........-${UPDATECHANNEL}-${DEVICE} /system/build.prop | head -n1 | cut -c 15-50)"
	#Reads the currently installed CM-version from your device's /system/build.prop

	WAITFORDEVICE="adb wait-for-device" 
	#Added this as a variable because otherwise it would always mess up the coloring in gedit due to the word "for".

	CURL="$(curl -s "$URL" | grep -Eo "$VERSION_REGEX" | head -n1)" 
	#Searches the CyanogenMod-website of your device for the latest update

	SHA1="$(curl -s "$URL" | grep -o 'sha1: ........................................' | head -n1 | cut -c 7-47)"
	#Gets the SHA1 hash for the latest update

	#MD5="$(curl -s "${URL}" | grep -o 'md5: ................................' | head -n1 | cut -c 5-37)"
	#Gets the MD5-hash for the latest update

	WGETURL="https://download.cyanogenmod.org$(curl -s "$URL" |  grep -o -m1 /get/jenkins/....../cm-$CMVERSION-........-$UPDATECHANNEL-$DEVICE.zip)"
	#Selects the most recent direct-link to the CyanogenMod-zip

	start
else
	echo
	echo "Could not communicate with your device."
	echo "Make sure it is connected and that your drivers and ADB tools are set up properly."
	exit
fi
