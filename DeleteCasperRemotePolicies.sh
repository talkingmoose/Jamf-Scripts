#!/bin/sh

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 
# Written by: William Smith
# Professional Services Engineer
# JAMF Software
# bill@talkingmoose.net
# https://github.com/talkingmoose/Casper-Scripts
#
# Originally posted: October 26, 2016
# Last updated: October 26, 2016
#
# Purpose: each run of Casper Remote generates a new policy that's
# stored in the JSS. However, those policies are not visible and
# the JSS has no means to allow administrators to delete them. This
# script identifies all JSS policies with names in the format:
#    '2013-08-07 at 4:18 PM | jsanchez | 1 Computer'
# and deletes them.
#
# The script creates a log file in the same folder as the script.
#
# Except where otherwise noted, this work is licensed under
# http://creativecommons.org/licenses/by/4.0/
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# INSTRUCTIONS

# 1) Modify URL, userName and password below to access your JSS.
# 2) Save and run this script via Terminal or an editor with a "run script" feature.
# 3) Verify policies in your JSS or by appending /api to your JSS URL.

URL="https://jss.talkingmoose.net:8443"
userName="JSSAPI-Editor"
password="password"

# create the output directory and log file
# in the same directory as this script

# path to this script
CURRENTDIRECTORY=$( /usr/bin/dirname "$0" )

# name of this script
CURRENTSCRIPT=$( /usr/bin/basename -s .sh "$0" )

# create log file in same directory as script
LOGFILE="$CURRENTDIRECTORY/$CURRENTSCRIPT - $( /bin/date '+%y-%m-%d' ).log"

# functions
function logresult()	{
	if [ $? = 0 ] ; then
	  /bin/date "+%Y-%m-%d %H:%M:%S	$1" >> "$LOGFILE"
	else
	  /bin/date "+%Y-%m-%d %H:%M:%S	$2" >> "$LOGFILE"
	fi
}

# the time right now
startTime=$( /bin/date '+%s' )

# start the log
logresult "--------------------- Begin Script ---------------------"

# get list of existing policies in the JSS

policyXML=$( /usr/bin/curl -k $URL/JSSResource/policies --user "$userName:$password" -H "Accept: text/xml" -X GET | xmllint --format - )

logresult "Reading policy XML." "Failed to read policy XML."

# create a list of IDs to delete
idList=$( echo "$policyXML" | egrep -B1 '<name>[0-9]+-[0-9]{2}-[0-9]{2} at [0-9]{1,2}:[0-9]{2,2} [AP]M \| .* \| .*</name>' | grep '<id>' | awk -F '[><]' '{print $3}' )

while IFS= read aLine
do
	/usr/bin/curl -k "$URL/JSSResource/policies/id/$aLine" --user "$userName:$password" -X DELETE
	
	logresult "Deleted ID \"$aLine\"." "Failed to delete ID \"$aLine\"."
	
	idCount=$((idCount+1))

done <<< "$idList"

# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Processed $idCount policies."

# the time right now
stopTime=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
DIFF=$(($stopTime-$startTime))
logresult "Script operations took $DIFF seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0
