#!/bin/sh

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 
# Written by: William Smith
# Professional Services Engineer
# Jamf
# bill@talkingmoose.net
# https://github.com/talkingmoose/Jamf-Scripts
#
# Originally posted: October 29, 2016
# Last updated: August 13, 2018
#
# Purpose: Updates a Site name in parsed XML from the JSS Migration
# Utility: https://github.com/igeekjsc/JSSAPIScripts. Useful for
# migrating to new sites in a different Jamf Pro server.
#
# The script creates a log file in the same folder as the script.
#
# Except where otherwise noted, this work is licensed under
# http://creativecommons.org/licenses/by/4.0/
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# INSTRUCTIONS

# 1) Modify the siteName variable below.
# 2) Run the jssMigrationUtility.bash script to download the source XML files.
# 3) Move the script to the same level as the parsed_xml folder in the JSS_Migration folder.
# 4) Run the script via Terminal or an editor with a "run script" feature.
# 5) Review the XML files in the parsed_xml folder and verify Site nodes are changed.

siteName="New Site Name"

# path to this script
currentDirectory=$( /usr/bin/dirname "$0" )

# name of this script
currentScript=$( /usr/bin/basename -s .sh "$0" )

# set the parsed_xml directory in the same directory as script
outputDirectory="$currentDirectory/parsed_xml"

# set the log file in same directory as script
logFile="$currentDirectory/$currentScript - $( /bin/date '+%y-%m-%d' ).log"

# functions
function logresult()	{
	if [ $? = 0 ] ; then
	  /bin/date "+%Y-%m-%d %H:%M:%S	$1" >> "$logFile"
	else
	  /bin/date "+%Y-%m-%d %H:%M:%S	$2" >> "$logFile"
	  continue
	fi
}

# the time right now
startTime=$( /bin/date '+%s' )

# start the log
logresult "--------------------- Begin Script ---------------------"

# get list of XML files
fileList=$( /bin/ls "$outputDirectory" )
logresult "Creating XML file list." "Failed creating XML file list."

while IFS= read aFile
do
	XMLContent=$( /bin/cat "$currentDirectory/parsed_xml/$aFile" )
	
	logresult "Reading file \"$aFile\"." "Failed reading file \"$aFile\"."
	
	unwrappedXML=$( echo "$XMLContent" | /usr/bin/xmllint --noblanks - )
	
	logresult "Unwrapping XML from file \"$aFile\"." "Failed unwrappingXML from file \"$aFile\"."
	
	updatedXML=$( echo "$unwrappedXML" | /usr/bin/sed "s/<site><name>.*<\/name><\/site>/<site><name>$siteName<\/name><\/site>/g" )
	
	logresult "Replacing site in XML from file \"$aFile\"." "Failed replacing site in XML from file \"$aFile\"."
	
	newXML=$( echo "$updatedXML" | /usr/bin/xmllint --format - )
	
	logresult "Rewrapping XML from file \"$aFile\"." "Failed rewrapping XML from file \"$aFile\"."
	
	echo "$newXML" > "$currentDirectory/parsed_xml/$aFile"
	
	logresult "Writing modified XML to file \"$aFile\"." "Failed writing modified XML to file \"$aFile\"."
	
	fileCount=$((fileCount+1))

done <<< "$fileList"

# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Modified $fileCount files."

# the time right now
stopTime=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
diff=$(($stopTime-$startTime))
logresult "Script operations took $diff seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0
