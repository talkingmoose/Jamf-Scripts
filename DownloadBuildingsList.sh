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
# Purpose: Downloads a list of buildings from your Jamf Pro server and
# saves the list in a buildingsList.txt file. When used with
# UploadBuildingsList.sh, a Jamf Pro administrator can start with a list from
# an old Jamf Pro server, clean up the text and then upload the text to
# another Jamf Pro server.
#
# The script creates a log file in the same folder as the script.
#
# Except where otherwise noted, this work is licensed under
# http://creativecommons.org/licenses/by/4.0/
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# INSTRUCTIONS

# 1) Modify URL, userName and passWord below to access your Jamf Pro server.
# 2) Save and run this script via Terminal or an editor with a "run script" feature.
# 3) Review the "buildingsList.txt" file in the JSS_Output folder.

URL="https://jamfpro.talkingmoose.net:8443"
userName="API-Auditor"
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

# create the output directory if necessary
/bin/mkdir -p "$outputDirectory"
logresult "Created $outputDirectory directory." "Failed creating $outputDirectory directory or it already exists."

# download building XML file from Jamf Pro server
buildingXML=$( /usr/bin/curl -k $URL/JSSResource/buildings --user "$userName:$passWord" -H "Accept: text/xml" -X GET  | /usr/bin/xmllint --format - )

logresult "Downloaded building XML information." "Failed downloading building XML information."

# parse the list for just building names
buildingsList=$( /bin/echo "$buildingXML" | /usr/bin/perl -lne 'BEGIN{undef $/} while (/<name>(.*?)<\/name>/sg){print $1}' )

logresult "Parsed building XML information for building names." "Failed parsing building XML information for building names."

# write the list to the output file
echo "$buildingsList" > "$outputDirectory/buildingsList.txt"

logresult "Wrote building information to JSS_Output directory." "Failed to write building information to JSS_Output directory."

# count the buildings
buildingCount=$( echo "$buildingsList" | /usr/bin/grep -c ^ )

logresult "Counted number of buildings." "Failed to count number of buildings."

# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Listed $buildingCount buildings."

# the time right now
stopTime=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
DIFF=$(($stopTime-$startTime))
logresult "Script operations took $DIFF seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0
