#!/bin/sh

# DownloadNetworkSegments.sh
# By William Smith
# Professional Services Engineer
# JAMF Software
# July 9, 2016
# bill@talkingmoose.net

# Except where otherwise noted, this work is licensed under
# http://creativecommons.org/licenses/by/4.0/

# INSTRUCTIONS

# 1) Modify URL, USERNAME and PASSWORD below to access your source JSS.
# 2) Save and run this script via Terminal or an editor with a "run script" feature.
# 3) Review the XML files in the JSS_Output folder and Trash any you do not wish to upload to your destination JSS.
# 4) Run the UploadNetworkSegments.sh script to populate your destination JSS.

URL="https://jss.talkingmoose.net:8443"
USERNAME="casperadmin"
PASSWORD="password"

# create the output directory and log file
# in the same directory as this script

# path to this script
CURRENTDIRECTORY=$( /usr/bin/dirname "$0" )

# name of this script
CURRENTSCRIPT=$( /usr/bin/basename -s .sh "$0" )

# create the JSS_Output directory in the same directory as script
OUTPUTDIRECTORY="$CURRENTDIRECTORY/JSS_Output"

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
STARTTIME=$( /bin/date '+%s' )

# start the log
logresult "--------------------- Begin Script ---------------------"

# create a working directory on the desktop
if [ -d "$OUTPUTDIRECTORY" ] ; then

	rm -R "$OUTPUTDIRECTORY"
	logresult "Removed old $OUTPUTDIRECTORY directory." "Failed removing old $OUTPUTDIRECTORY directory."
	
	mkdir -p "$OUTPUTDIRECTORY"
	logresult "Created new $OUTPUTDIRECTORY directory." "Failed creating new $OUTPUTDIRECTORY directory."
	
else
	mkdir -p "$OUTPUTDIRECTORY"
	logresult "Created $OUTPUTDIRECTORY directory." "Failed creating $OUTPUTDIRECTORY directory."
fi

# download a list of network segment IDs
NSIDS=$( /usr/bin/curl -k $URL/JSSResource/networksegments --user "$USERNAME:$PASSWORD" -H "Content-Type: text/xml" -X GET | /usr/bin/perl -lne 'BEGIN{undef $/} while (/<id>(.*?)<\/id>/sg){print $1}' )

logresult "Created Network Segments ID list." "Failed to create Network Segments ID list."

# download XML for each network segment and prepare for upload
while IFS= read ALINE
do
	# get the full XML for a network segment
	ITEMXML=$( /usr/bin/curl -k $URL/JSSResource/networksegments/id/$ALINE --user "$USERNAME:$PASSWORD" -H "Content-Type: text/xml" -X GET  | xmllint --format - )
	
	NSNAME=$( echo "$ITEMXML" | awk -F "[><]" '/name/{print $3;exit}' )
	
	logresult "Retrieved XML for network segment \"$NSNAME\"." "Failed to retrieve XML for network segment \"$NSNAME\"."
	
	# modify the returned XML and write to a file
	echo "$ITEMXML" > "$OUTPUTDIRECTORY/$NSNAME.xml"

	logresult "Created XML file for network segment \"$NSNAME\"." "Failed to create XML file for network segment \"$NSNAME\"."
	
	DOWNLOAD=$((DOWNLOAD+1))

done <<< "$NSIDS"

# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Processed $DOWNLOAD network segments."

# the time right now
STOPTIME=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
DIFF=$(($STOPTIME-$STARTTIME))
logresult "Script operations took $DIFF seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0