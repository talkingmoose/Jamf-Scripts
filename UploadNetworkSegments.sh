#!/bin/sh

# UploadNetworkSegments.sh
# By William Smith
# Professional Services Engineer
# JAMF Software
# July 9, 2016
# bill@talkingmoose.net

# Except where otherwise noted, this work is licensed under
# http://creativecommons.org/licenses/by/4.0/

# INSTRUCTIONS

# 1) Run the DownloadNetworkSegments.sh script against your source JSS to create a list of network segment XML files.
# 2) Review the XML files in the JSS_Output folder and Trash any you do not wish to upload to your destination JSS.
# 3) Modify URL, USERNAME and PASSWORD below to access your destination JSS.
# 4) Save and run this script via Terminal or an editor with a "run script" feature.
# 5) Verify network segments in your destination JSS.

# the time right now
STARTTIME=$( /bin/date '+%s' )

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

# verify the working directory on the desktop
if [ ! -d "$OUTPUTDIRECTORY" ] ; then
	echo "Output directory at $OUTPUTDIRECTORY does not exist. Fix this path first."
	logresult "Output directory $OUTPUTDIRECTORY does not exist. Fix this path first."
	exit 0
fi

# create a list of network segment XML files to upload
NSFILES=$( ls "$OUTPUTDIRECTORY" )
logresult "Created list of network segment XML files from $OUTPUTDIRECTORY." "Failed to create list of network segment XML files from $OUTPUTDIRECTORY."

# upload XML files to create network segments
while IFS= read ALINE
do
	# read the XML file and remove formatting
	NSXML=$( cat "$OUTPUTDIRECTORY/$ALINE"  | xmllint --noblanks - )
	logresult "Reading XML file \"$ALINE\"" "Failed to read XML file \"$ALINE\""
	
	/usr/bin/curl -k $URL/JSSResource/networksegments --user "$USERNAME:$PASSWORD" -H "Content-Type: application/xml" -X POST -d "$NSXML"
	logresult "Uploaded XML file \"$ALINE\"" "Failed to upload XML file \"$ALINE\""
	
	UPLOAD=$((UPLOAD+1))

done <<< "$NSFILES"

# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Processed $UPLOAD network segment XML files."

# the time right now
STOPTIME=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
DIFF=$(($STOPTIME-$STARTTIME))
logresult "Script operations took $DIFF seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0