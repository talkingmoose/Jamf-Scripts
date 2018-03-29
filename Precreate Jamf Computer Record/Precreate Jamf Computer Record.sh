#!/bin/sh

<<ABOUT_THIS_SCRIPT
-----------------------------------------------------------------------

	Written by:William Smith
	Professional Services Engineer
	Jamf
	bill@talkingmoose.net
	https://gist.github.com/talkingmoose/?
	
	Originally posted: March 28, 2018

	Purpose: Reads a list of computer information with tab-separated
	details and pre-creates computer records in Jamf Pro. This enables
	a Jamf Pro admin to pre-assign sites or static groups before
	deploying devices.
	
	Instructions: Edit the associated tab-delimited file "Precreate
	Jamf Computer Record List.txt" and with serial number, MAC address
	and Site names. (Site names must already exist in Jamf Pro.) You
	may need to use a plain text editor such as BBEdit to ensure the
	.txt file is saved with UNIX line endings (LF).
	
	This script creates a log file in the same directory as the script.

	Except where otherwise noted, this work is licensed under
	http://creativecommons.org/licenses/by/4.0/

	"How do you keep an administrator in suspense?"
	
-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT

# uRL="https://jss.talkingmoose.net:8443"
# username="JSSAPI-Editor"
# password="password"

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

# read the list of computers
computersList=$( cat "Precreate Jamf Computer Record List.txt" )
logresult "Reading computer record list." "Failed to read computer record list."

# precreate computers, one at a time
while IFS= read aComputer
do
	# parse the computer's information
	serialNumber=$( echo "$aComputer" | awk -F \t '{ print $1 }' )
	macAddress=$( echo "$aComputer" | awk -F \t '{ print $2 }' )
	site=$( echo "$aComputer" | awk -F \t '{ print $3 }' )
	
	# create XML to upload
	theXML="<computer><general><name>$serialNumber</name><mac_address>$macAddress</mac_address><serial_number>$serialNumber</serial_number><site><name>$site</name></site></general></computer>"
	
	# upload the XML to create a new computer record
	/usr/bin/curl -k $uRL/JSSResource/computers --user "$username:$password" -H "Content-Type: text/xml" -X POST -d "$theXML"
	logresult "Processing computer: $serialNumber." "Failed to process computer: $serialNumber."
	
	# keep count of processed records
	uploadCount=$((uploadCount+1))

done <<< "$computersList"

# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Processed $uploadCount computers."

# the time right now
stopTime=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
diff=$(($stopTime-$startTime))
logresult "Script operations took $diff seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0
