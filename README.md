# cmUpdater v0.6

#What is this?

This is a Bash-script that allows you to backup, restore and update your CyanogenMod-device from your PC.

![alt tag](http://i.imgur.com/0m7lb5t.png)

![alt tag](http://i.imgur.com/Xiwoile.png)

#Features

-Updating works with every device that is officialy supported by CyanogenMod, backup and restore works with every Android-Device with a recent version of TWRP.

-Checks for available updates by comparing the CyanogenMod-verison on your device with the newest one available

-Switch update-channels (Thanks to github-user oliv5 for implementing this!)

-If the latest CyanogenMod-update version differs from that on your device, you'll get an error to prevent you from getting the wrong files.

 Example: Flashing CM11 over CM12 or changing update-channels.

-Downloads the update

-Creates a backup of /system, /data and /boot and moves it to your PC (TWRP required, can be altered to include other partitions)

-Restores said update from your PC

-Automatic installation of the downloaded update (TWRP required)

-MD5-generation and verification for backups in TWRP

-Path of work environment can be changed

-Asks you exactly what you want to do

#Requirements

-Your device needs to be connected to your PC via USB

-Android ADB-tools have to be installed and set up properly (meaning globally available on Windows)

-USB-debugging and must be enabled (you can do that in the Developer-Options)

-Should run out of the box on OS X after you've installed the Android tools

-On Windows you need to make sure that your drivers are working properly, both in the system and in the recovery

-On Windows 10 you can run this by installing the "Windows subsystem for Linux (beta)" from the "Turn Windows features on or off" menu.
 You probably need to enable Windows Insider builds until it leaves beta.

-You need Cygwin to run this on Windows <10 (Base-package, curl from "Net" and wget from "Web" in the installation-process)

-You need TWRP for installing the .zip remotely on your device and making/restoring backups

-You need CyanogenMod for updating CyanogenMod (duh)

-DO NOT unplug your device at any part of the process

#Limitations

-TWRP names the backup-folder differently for every single device (the path is /sdcard/TWRP/BACKUPS/RandomDeviceID/).

 I have to delete BACKUPS/ to make sure there's no backup already there.

 That means that if you have other backups there, they will be removed! So make sure you save them before running this, if you have any.

-Same thing with the backup-folder in your specified directory on your PC:

 It will get deleted if you pull a new backup from your device, so if you want to keep old backups you'll have to move them to another location.

#How to use

Make sure you meet all requirements and then replace my device-information in the cmUpdater.sh file with yours, set all options to your liking and then run the file via the terminal.

It may be necessary to mark it as executable, you can do that by running `$ chmod +x cmUpdater.sh`.

# -

Obligatory "I'm not responsible if you fry your device". I have tested this thoroughly with various different devices (victara, condor, m7) and have implemented many failsafe-functions, but there can still be problems I'm not aware of, even if it seems unlikely.
