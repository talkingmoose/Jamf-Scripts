#!/bin/sh

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 
# Written by: William Smith
# Professional Services Engineer
# JAMF Software
# bill@talkingmoose.net
# https://github.com/talkingmoose/Jamf-Scripts
#
# Originally posted: July 9, 2016
# Last updated: August 13, 2018
#
# Purpose: Downloads each network segment from your JSS and saves it as
# an XML file in the JSS_Output directory. When used with
# UploadNetworkSegments.sh, a JSS administrator can start with a list
# from an old JSS, delete unwanted network segment files and then upload
# the remaining files to another JSS.
#
# The script creates a log file in the same folder as the script.
#
# Except where otherwise noted, this work is licensed under
# http://creativecommons.org/licenses/by/4.0/
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# INSTRUCTIONS

# 1) Modify URL, userName and passWord below to access your source JSS.
# 2) Save and run this script via Terminal or an editor with a "run script" feature.
# 3) Review the XML files in the JSS_Output folder and Trash any you do not wish to upload to your destination JSS.
# 4) Run the UploadNetworkSegments.sh script to populate your destination JSS.

URL="https://jss.talkingmoose.net:8443"
userName="JSSAPI-Auditor"
passWord="password"

# define the output directory and log file
# in the same directory as this script

# path to this script
currentDirectory=$( /usr/bin/dirname "$0" )

# name of this script
currentScript=$( /usr/bin/basename -s .sh "$0" )

# set the JSS_Output directory in the same directory as script
outputDirectory="$currentDirectory/JSS_Output"

# set the log file in same directory as script
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

# create a working directory on the desktop
if [ -d "$outputDirectory" ] ; then

	/bin/rm -R "$outputDirectory"
	logresult "Removed old $outputDirectory directory." "Failed removing old $outputDirectory directory."
	
	/bin/mkdir -p "$outputDirectory"
	logresult "Created new $outputDirectory directory." "Failed creating new $outputDirectory directory."
	
else
	/bin/mkdir -p "$outputDirectory"
	logresult "Created $outputDirectory directory." "Failed creating $outputDirectory directory."
fi

# download a list of network segment IDs
nsIDs=$( /usr/bin/curl -k $URL/JSSResource/networksegments --user "$userName:$passWord" -H "Accept: text/xml" -X GET | /usr/bin/perl -lne 'BEGIN{undef $/} while (/<id>(.*?)<\/id>/sg){print $1}' )

logresult "Created Network Segments ID list." "Failed to create Network Segments ID list."

# download XML for each network segment and prepare for upload
while IFS= read aLine
do
	# get the full XML for a network segment
	ITEMXML=$( /usr/bin/curl -k $URL/JSSResource/networksegments/id/$aLine --user "$userName:$passWord" -H "Accept: text/xml" -X GET  | /usr/bin/xmllint --format - )
	
	nsName=$( echo "$ITEMXML" | /usr/bin/awk -F "[><]" '/name/{print $3;exit}' )
	
	logresult "Retrieved XML for network segment \"$nsName\"." "Failed to retrieve XML for network segment \"$nsName\"."
	
	# modify the returned XML and write to a file
	echo "$ITEMXML" > "$outputDirectory/$nsName.xml"

	logresult "Created XML file for network segment \"$nsName\"." "Failed to create XML file for network segment \"$nsName\"."
	
	downLoad=$((downLoad+1))

done <<< "$nsIDs"

# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Processed $downLoad network segments."

# the time right now
stopTime=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
DIFF=$(($stopTime-$startTime))
logresult "Script operations took $DIFF seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0