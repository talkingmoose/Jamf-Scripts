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
# Purpose: Reads a tab-delimited file (requires UNIX line-endings)
# to get the name of a building in a JSS and rename it. This lets a
# JSS administrator rename inconsistently named buildings to a consistent
# format. Because buildings are referenced in other parts of the JSS by
# ID rather than name, renaming buildings does not affect existing
# functionality.
#
# The script creates a log file in the same folder as the script.
#
# Except where otherwise noted, this work is licensed under
# http://creativecommons.org/licenses/by/4.0/
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# INSTRUCTIONS

# 1) Modify URL, userName and passWord below to access your JSS.
# 2) Edit the RenameBuildingsList.tab file.
#	 One set of names per line in the format:
#	 Old building name _tab_ New building name
#	 Use a quality text editor such as BBEdit or TextWranlger to save the file with Unix line endings.
# 3) Place the RenameBuildingsList.tab file in the same directory as this script.
# 4) Run this script via Terminal or an editor with a "run script" feature.
# 5) Verify buildings in your JSS.

# the time right now
startTime=$( /bin/date '+%s' )

URL="https://jss.talkingmoose.net:8443"
userName="JSSAPI-Editor"
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

renameBuildingsList=$( cat "$currentDirectory/RenameBuildingsList.tab" )

# verify the working directory on the desktop
if [ ! -f "$currentDirectory/RenameBuildingsList.tab" ] ; then
	echo "File \"$currentDirectory/RenameBuildingsList.tab\" does not exist. Fix this path first."
	logresult "File \"$currentDirectory/RenameBuildingsList.tab\" does not exist. Fix this path first."
	exit 0
fi

while IFS= read aLine
do
	oldBuilding=$( echo "$aLine" | awk -F \t '{print $1}' )
	newBuilding=$( echo "$aLine" | awk -F \t '{print $2}' )
	converted=${oldBuilding// /%20}
	putXML="<building><name>$newBuilding</name></building>"
	
	/usr/bin/curl -k $URL/JSSResource/buildings/name/$converted --user "$userName:$passWord" -H "Content-Type: text/xml" -X PUT -d "$putXML"
	
	logresult "Renamed building \"$oldBuilding\" to \"$newBuilding\"" "Failed renaming \"$oldBuilding\" to \"$newBuilding\""
	
	buildingCount=$((buildingCount+1))
	
done <<< "$renameBuildingsList"

# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Processed $buildingCount building name changes."

# the time right now
stopTime=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
DIFF=$(($stopTime-$startTime))
logresult "Script operations took $DIFF seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0
