#!/bin/sh

<<ABOUT_THIS_SCRIPT
-----------------------------------------------------------------------

	Written by: William Smith
	Professional Services Engineer
	Jamf
	bill@talkingmoose.net
	https://github.com/talkingmoose/Jamf-Scripts
	
	Originally posted: February 6, 2017
	Last updated: August 13, 2018

	Purpose: uploads a list of departments to your Jamf Pro server
	by reading a DepartmentsList.txt file or a list pasted into this script.

	Except where otherwise noted, this work is licensed under
	http://creativecommons.org/licenses/by/4.0/

	"Keep your eye on the ball, but move out of the way
	when it comes too close."

INSTRUCTIONS

	1) Copy this script to an OS X system and verify it is executable.
	2) Create a launchd daemon to run the script periodically.
	3) The script creates a log file in the same directory.
	
-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT

URL="https://jamfpro.talkingmoose.net:8443"
userName="API-Editor"
password="password"

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

# departmentsList=$( /bin/cat '/path/to/departmentsList.txt' )
# or
departmentsList="Accounting
Sales
Department of Redundancy
Parks
Recreation"

logresult "Reading departments list." "Failed to read departments list."

# upload department names, one at a time
# the script will not modify departments that already exist in the Jamf Pro server

while IFS= read aLine
do
	THExml="<department><name>$aLine</name></department>"
	
	/usr/bin/curl -k $URL/JSSResource/departments --user "$userName:$password" -H "Content-Type: text/xml" -X POST -d "$THExml"
	
	logresult "uploaded departments \"$aLine\"." "Failed to upload departments \"$aLine\"."
	
	upload=$((upload+1))

done <<< "$departmentsList"

# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Processed $upload departments."

# the time right now
stopTime=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
difference=$(($stopTime-$startTime))
logresult "Script operations took $difference seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0
