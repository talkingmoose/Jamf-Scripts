#!/bin/sh

# PopulateBuildingsList.sh
# By William Smith
# Professional Services Engineer
# JAMF Software
# July 9, 2016
# bill@talkingmoose.net

# Except where otherwise noted, this work is licensed under
# http://creativecommons.org/licenses/by/4.0/

# INSTRUCTIONS

# 1) Modify URL, USERNAME and PASSWORD below to access your JSS.
# 2) Edit the BUILDINGSLIST variable below or modify the script to "cat" a text file with the list.
# 3) Save and run this script via Terminal or an editor with a "run script" feature.
# 4) Verify buildings in your JSS.

URL="https://jss.talkingmoose.net:8443"
USERNAME="casperadmin"
PASSWORD="password"

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
STARTTIME=$( /bin/date '+%s' )

# start the log
logresult "--------------------- Begin Script ---------------------"

# get list of buildings from a file or from text pasted below

# BUILDINGSLIST=$( cat '/path/to/buildingslist.txt' )
# or
BUILDINGSLIST="Dome of the Rock
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
# the script will not modify buildings that already exist in the JSS

while IFS= read ALINE
do
	THExml="<building><name>$ALINE</name></building>"
	
	/usr/bin/curl -k $URL/JSSResource/buildings --user "$USERNAME:$PASSWORD" -H "Content-Type: application/xml" -X POST -d "$THExml"
	
	logresult "Uploaded builidng \"$ALINE\"." "Failed to upload building \"$ALINE\"."
	
	UPLOAD=$((UPLOAD+1))

done <<< "$BUILDINGSLIST"

# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Processed $UPLOAD buildings."

# the time right now
STOPTIME=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
DIFF=$(($STOPTIME-$STARTTIME))
logresult "Script operations took $DIFF seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0
