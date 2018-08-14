#!/bin/sh

<<ABOUT_THIS_SCRIPT
-----------------------------------------------------------------------

	Written by: William Smith
	Professional Services Engineer
	JAMF Software
	bill@talkingmoose.net
	https://github.com/talkingmoose/Jamf-Scripts

	Originally posted: July 7, 2017
	Last updated: August 13, 2018

	Purpose: Synchronizes Jamf distribution points from Master.
	Reads a list of servers supporting ssh and rsyncs over ssh. Then
	reads a list of servers supporting smb and rsyncs files.

	The script creates a log file in the same folder as the script.

	Except where otherwise noted, this work is licensed under
	http://creativecommons.org/licenses/by/4.0/

	"My voice is my password."

INSTRUCTIONS

	1) This script assumes remote locations follow the same path.
	2) Save this script to your Master DP (Mac or linux) and edit the
	   pathToPackages value below.
	3) Edit each .txt file accompanying this script. Follow the
	   instructions in each file.
	4) Create a launchd or crontab to run the script on a periodic
	   schedule.

-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT



# create the output directory and log file
# in the same directory as this script

# path to this script
currentDirectory=$( /usr/bin/dirname "$0" )

# name of this script
currentScript=$( /usr/bin/basename -s .sh "$0" )

pathToPackages="/Users/jamfadmin/CasperShare/Packages"

# create log file in same directory as script
logFile="$currentDirectory/$currentScript - $( /bin/date '+%y-%m-%d' ).log"



# functions
function logresult()	{
	if [ $? = 0 ] ; then
	  /bin/date "+%Y-%m-%d %H:%M:%S	$1" >> "$logFile"
	else
	  /bin/date "+%Y-%m-%d %H:%M:%S	$2" >> "$logFile"
	fi
}



# the time right now
startTime=$( /bin/date '+%s' )

# start the log
logresult "--------------------- Begin Script ---------------------"

# rotate logs -- delete all but the five most recent log files
deleteOldLogs=$( /bin/ls -1t "$currentDirectory/$currentScript"*.log | /usr/bin/tail -n +6 )

while IFS= read -r aLog
do
	logFileName=$( /usr/bin/basename "$aLog" )
	/bin/rm "$aLog"
	logresult "Deleting old log file: $logFileName."
done <<< "$deleteOldLogs"



# read list of servers using rsync
rsyncServers=$( /usr/bin/grep -v \# "$currentDirectory/rsync-servers.txt")

# read list of servers using smb
smbServers=$( /usr/bin/grep -v \#  "$currentDirectory/smb-servers.txt" )



# rsync each server in the rsyncServer file
while IFS= read aServer
do
	# parse each line for address, username and password
	sshAddress=$( echo "$aServer" | /usr/bin/awk '{ print $1 }' )
	sshUsername=$( echo "$aServer" | /usr/bin/awk '{ print $2 }' )
	sshPath=$( echo "$aServer" | /usr/bin/awk '{ print $3 }' )
	
	/usr/bin/rsync --archive --human-readable --verbose -e "ssh -i $HOME/.ssh/id_rsa" --exclude=".*" --delete --progress --stats "$pathToPackages" "$sshUsername@$sshAddress:$sshPath" >> $logFile
	logresult "Completed Rsync to $aServer server." "Failed Rsync to $aServer server."
done <<< "$rsyncServers"



# rsync each server in the smbServer file
while IFS= read aServer
do
	# parse each line for address, username and password
	smbAddress=$( echo "$aServer" | /usr/bin/awk '{ print $1 }' )
	smbUsername=$( echo "$aServer" | /usr/bin/awk '{ print $2 }' )
	smbPassword=$( echo "$aServer" | /usr/bin/awk '{ print $3 }' )
	smbShare=$( echo "$aServer" | /usr/bin/awk '{ print $4 }' )
	smbPath=$( echo "$aServer" | /usr/bin/awk '{ print $5 }' )
	
	# mount remote SMB server.
	/bin/mkdir "/Volumes/$smbShare"
	/sbin/mount_smbfs "//$smbUsername:$smbPassword@$smbAddress/$smbShare" "/Volumes/$smbAddress"
	logresult "Mounted SMB server $smbAddress." "Failed mount SMB server $smbAddress."
	
	/usr/bin/rsync --archive --human-readable --verbose --exclude=".*" --delete --progress --stats "$pathToPackages" "/Volumes/$smbShare$smbPath" >> $logFile
	logresult "Completed Rsync to $aServer server." "Failed Rsync to $aServer server."
	
	# unmount SMB Volume
	/sbin/umount "/Volumes/$smbShare"
	logresult "Unmounted $aServer server." "Failed unmount $aServer server."
	
done <<< "$smbServers"



# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Processed $printerCount printers."

# the time right now
stopTime=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
timer=$(($stopTime-$startTime))
logresult "Script operations took $timer seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0