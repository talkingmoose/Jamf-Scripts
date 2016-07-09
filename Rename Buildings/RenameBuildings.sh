#!/bin/sh

# RenameBuildings.sh
# By William Smith
# Professional Services Engineer
# JAMF Software
# July 9, 2016
# bill@talkingmoose.net

# Except where otherwise noted, this work is licensed under
# http://creativecommons.org/licenses/by/4.0/

# INSTRUCTIONS

# 1) Modify URL, USERNAME and PASSWORD below to access your JSS.
# 2) Edit the RenameBuildingsList.tab file.
#	 One set of names per line in the format:
#	 Old building name _tab_ New building name
#	 Use a quality text editor such as BBEdit or TextWranlger to save the file with Unix line endings.
# 3) Place the RenameBuildingsList.tab file in the same directory as this script.
# 4) Run this script via Terminal or an editor with a "run script" feature.
# 5) Verify buildings in your JSS.

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

RENAMEBUILDINGSLIST=$( cat "$CURRENTDIRECTORY/RenameBuildingsList.tab" )

# verify the working directory on the desktop
if [ ! -f "$CURRENTDIRECTORY/RenameBuildingsList.tab" ] ; then
	echo "File \"$CURRENTDIRECTORY/RenameBuildingsList.tab\" does not exist. Fix this path first."
	logresult "File \"$CURRENTDIRECTORY/RenameBuildingsList.tab\" does not exist. Fix this path first."
	exit 0
fi

while IFS= read ALINE
do
	OLDBUILDING=$( echo "$ALINE" | awk -F \t '{print $1}' )
	NEWBUILDING=$( echo "$ALINE" | awk -F \t '{print $2}' )
	CONVERTED=${OLDBUILDING// /%20}
	PUTXML="<building><name>$NEWBUILDING</name></building>"
	
	/usr/bin/curl -k $URL/JSSResource/buildings/name/$CONVERTED --user "$USERNAME:$PASSWORD" -H "Content-Type: application/xml" -X PUT -d "$PUTXML"
	
	logresult "Renamed building \"$OLDBUILDING\" to \"$NEWBUILDING\"" "Failed renaming \"$OLDBUILDING\" to \"$NEWBUILDING\""
	
	BUILDINGCOUNT=$((BUILDINGCOUNT+1))
	
done <<< "$RENAMEBUILDINGSLIST"

# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Processed $BUILDINGCOUNT building name changes."

# the time right now
STOPTIME=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
DIFF=$(($STOPTIME-$STARTTIME))
logresult "Script operations took $DIFF seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0
