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
# Purpose: Uploads a list of buildings to your Jamf Pro server by reading a
# BuildingsList.txt file or a list pasted into this script. When used
# with DownloadBuildingsList.sh, a Jamf Pro administrator can start with a list
# from an old Jamf Pro server, clean up the text and then upload the text
# to another Jamf Pro server.
#
# The script creates a log file in the same folder as the script.
#
# Except where otherwise noted, this work is licensed under
# http://creativecommons.org/licenses/by/4.0/
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# INSTRUCTIONS

# 1) Modify URL, userName and passWord below to access your Jamf Pro server.
# 2) Edit the buildingsList variable below or modify the script to "cat" a text file with the list.
# 3) Save and run this script via Terminal or an editor with a "run script" feature.
# 4) Verify buildings in your Jamf Pro server.

URL="https://jamfpro.talkingmoose.net:8443"
userName="API-Editor"
passWord="password"

# create the output directory and log file
# in the same directory as this script

# path to this script
currentDirectory=$( /usr/bin/dirname "$0" )

# name of this script
currentScript=$( /usr/bin/basename -s .sh "$0" )

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

# get list of buildings from a file or from text pasted below

# buildingsList=$( /bin/cat '/path/to/buildingslist.txt' )
# or
buildingsList="Dome of the Rock
La Pedrera
One World Trade Center
St Paul's Cathedral
Petronas Towers
The White House
Leaning Tower of Pisa
The Kaaba
The Shard
St Basil's Cathedral
Colosseum
Taj Mahal
Sydney Opera House
Space Needle
Pantheon
Turning Torso"

logresult "Reading buildings list." "Failed to read buildings list."

# upload building names, one at a time
# the script will not modify buildings that already exist in the Jamf Pro server

while IFS= read aLine
do
	THExml="<building><name>$aLine</name></building>"
	
	/usr/bin/curl -k $URL/JSSResource/buildings --user "$userName:$passWord" -H "Content-Type: text/xml" -X POST -d "$THExml"
	
	logresult "Uploaded builidng \"$aLine\"." "Failed to upload building \"$aLine\"."
	
	UPLOAD=$((UPLOAD+1))

done <<< "$buildingsList"

# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Processed $UPLOAD buildings."

# the time right now
stopTime=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
DIFF=$(($stopTime-$startTime))
logresult "Script operations took $DIFF seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0
