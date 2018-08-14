#!/bin/sh

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 
# Written by: William Smith
# Professional Services Engineer
# Jamf
# bill@talkingmoose.net
# https://github.com/talkingmoose/Jamf-Scripts
#
# Originally posted: July 9, 2016
# Last updated: August 13, 2018
#
# Purpose: Uploads network segment XML files to your Jamf Pro server.
# When used with DownloadNetworkSegments.sh, a Jamf Pro administrator can
# start with a list from an old server, delete unwanted network segment
# files and then upload the remaining files to another server.
#
# The script creates a log file in the same folder as the script.
#
# Except where otherwise noted, this work is licensed under
# http://creativecommons.org/licenses/by/4.0/
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# INSTRUCTIONS

# 1) Run the DownloadNetworkSegments.sh script against your source Jamf Pro server to create a list of network segment XML files.
# 2) Review the XML files in the JSS_Output folder and Trash any you do not wish to upload to your destination Jamf Pro server.
# 3) Modify URL, userName and passWord below to access your destination Jamf Pro server.
# 4) Save and run this script via Terminal or an editor with a "run script" feature.
# 5) Verify network segments in your destination Jamf Pro server.

# the time right now
startTime=$( /bin/date '+%s' )

URL="https://jamfpro.talkingmoose.net:8443"
userName="API-Editor"
passWord="password"

# create the output directory and log file
# in the same directory as this script

# path to this script
currentDirectory=$( /usr/bin/dirname "$0" )

# name of this script
currentScript=$( /usr/bin/basename -s .sh "$0" )

# create the JSS_Output directory in the same directory as script
outputDirectory="$currentDirectory/JSS_Output"

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

# verify the working directory on the desktop
if [ ! -d "$outputDirectory" ] ; then
	echo "Output directory at $outputDirectory does not exist. Fix this path first."
	logresult "Output directory $outputDirectory does not exist. Fix this path first."
	exit 0
fi

# create a list of network segment XML files to upload
nsFiles=$( ls "$outputDirectory" )
logresult "Created list of network segment XML files from $outputDirectory." "Failed to create list of network segment XML files from $outputDirectory."

# upload XML files to create network segments
while IFS= read aLine
do
	# read the XML file and remove formatting
	nsXML=$( /bin/cat "$outputDirectory/$aLine"  | /usr/bin/xmllint --noblanks - )
	logresult "Reading XML file \"$aLine\"" "Failed to read XML file \"$aLine\""
	
	/usr/bin/curl -k $URL/JSSResource/networksegments --user "$userName:$passWord" -H "Content-Type: text/xml" -X POST -d "$nsXML"
	logresult "Uploaded XML file \"$aLine\"" "Failed to upload XML file \"$aLine\""
	
	upload=$((upload+1))

done <<< "$nsFiles"

# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Processed $upload network segment XML files."

# the time right now
stopTime=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
DIFF=$(($stopTime-$startTime))
logresult "Script operations took $DIFF seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0