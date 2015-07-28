#!/bin/bash

#VARIABLES:


DEVICE=victara		#put your Device-ID here, for example 'hammerhead' for Nexus 5 (without quotes)



CMVERSION=12.1		#The CyanogenMod-Version you'd like to search for. Example: '11' (without quotes).
			#Note: If the version you put here differs from the one on your device, you'll get an error to protect your device.



FILEPATH="./"		#The path where the script will download CyanogenMod
			#If you leave './' everything will go in the directory in which your terminal is opened.
			#The script will automatically check if the update is already present in the specified directory
			#!! You NEED to make sure your path ends with / !!
			#Added quotation marks in case your path has spaces in it



TWRPoptions=SDB 	#Options for the TWRP-backup/restore
			#Add partitions and options to your liking. Make sure there are only upper case letters and no spaces or symbols!

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
			#So for safety's sake MD5-generation and verification are ENABLED.
			#If for some reason you want to disable it, add the letter M here and remove it at line 216 column 47


#------------------------------------------------------------------------------------------------------------------------------------------


adb start-server #Starts the adb-server before reading the variables so that they are loaded correctly

ADB=$(adb shell grep -o ${CMVERSION}'-........-NIGHTLY-'${DEVICE} /system/build.prop | head -n1) #Reads the currently installed CM-version from your device's /system/build.prop

WAITFORDEVICE="adb wait-for-device" #Added this as a variable because otherwise it would always mess up the coloring in gedit due to the word "for".

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
				read -p "This will remove all updates and MD5-files from your PC, are you sure? (y/n)" -n 1 -r
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
echo
	if [[ -n ${ADB} ]]; then
		echo 'Your current CyanogenMod-version is' ${ADB} 
		updateChecker
	else
		echo 'error: Your specified CyanogenMod-version and the device-version differ, or your device is not connected properly. Exiting'
		exit
	fi
}


updateChecker(){
CURL=$(curl -s 'https://download.cyanogenmod.org/?device='${DEVICE} | grep -o ${CMVERSION}'-........-NIGHTLY-'${DEVICE} | head -n1 | grep ${CMVERSION}'-........-NIGHTLY-'${DEVICE} ) #Searches the CyanogenMod-website of your device for the latest update

MD5=$(curl -s 'https://download.cyanogenmod.org/?device='${DEVICE} | grep -o 'md5sum: ................................' | cut -c 8-40 | head -n1) #Gets the MD5-hash for the latest update

WGETURL=$(curl -s 'https://download.cyanogenmod.org/?device='${DEVICE} | grep -v 'jen' | grep -o -m1 'http://get.cm/get/...' | head -n1) #Selects the most recent direct-link to the CyanogenMod-zip

echo
	if [[ ${ADB} < ${CURL} ]]; then
		read -p "An updated version is available (cm-${CURL}). Do you want to download it? (y/n)" -n 1 -r
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
echo ${MD5} > "${FILEPATH}cm-${CURL}.zip.md5"
echo "Update and MD5 downloaded!"
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
		rebooter
	else
		rebooter
		
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
		rebooter
	else
		rebooter
	fi
}

rebooter(){
echo
read -p "Do you want to reboot your device? (y/n)" -n 1 -r
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				adb reboot
				echo
				echo "Exiting. Have a nice day!"
				exit
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
		echo "Pushing MD5 to /sdcard/..."
		adb push ${FILEPATH}cm-${CURL}.zip.md5 /sdcard/cm-${CURL}.zip.md5
		echo "Pushing 'cm-${CURL}.zip' to /sdcard/..."
		adb push ${FILEPATH}cm-${CURL}.zip /sdcard/cm-${CURL}.zip
		adb shell twrp install /sdcard/cm-${CURL}.zip
		adb shell rm /sdcard/cm-${CURL}.zip
		adb shell rm /sdcard/cm-${CURL}.zip.md5
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

start
