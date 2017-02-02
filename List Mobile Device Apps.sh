#!/bin/sh

<<ABOUT_THIS_SCRIPT
-----------------------------------------------------------------------

	Written by:William Smith
	Professional Services Engineer
	Jamf
	bill@talkingmoose.net
	https://github.com/talkingmoose/Casper-Scripts
	
	Originally posted: January 14, 2017
	Last updated: January 14, 2017

	Purpose: Retrieve list of mobile device apps in the JSS and report
	name, category and App Store link in .js files named from scopes.

	Except where otherwise noted, this work is licensed under
	http://creativecommons.org/licenses/by/4.0/

	"We're at our best when faced with limitations."

INSTRUCTIONS

	1) Copy this script to an OS X system and verify it is executable.
	2) Create a launchd daemon to run the script periodically.
	3) The script creates a log file in the same directory.
	
-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT

URL="https://jss.talkingmoose.net:8443"
userName="JSSAPI-Auditor"
password="password"

# define the output directory and log file
# in the same directory as this script

# path to this script
currentDirectory=$( /usr/bin/dirname "$0" )

# name of this script
currentScript=$( /usr/bin/basename -s .sh "$0" )

# set the JSS_Output directory in the same directory as script
outputDirectory="$currentDirectory/Mobile Device Apps"

# set the log file in same directory as script
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

# create a working directory
if [ -d "$outputDirectory" ] ; then

	/bin/rm -R "$outputDirectory"
	logresult "Removed old $outputDirectory directory." "Failed removing old $outputDirectory directory."
	
	/bin/mkdir -p "$outputDirectory"
	logresult "Created new $outputDirectory directory." "Failed creating new $outputDirectory directory."
	
else
	/bin/mkdir -p "$outputDirectory"
	logresult "Created $outputDirectory directory." "Failed creating $outputDirectory directory."
fi

# download a list of mobile device app IDs
appIDs=$( /usr/bin/curl -ks $URL/JSSResource/mobiledeviceapplications --user "$userName:$password" -H "Accept: text/xml" -X GET | /usr/bin/xmllint --format - | /usr/bin/grep "<id>" | /usr/bin/awk -F "(<id>|</id>)" '{ print $2 }' | /usr/bin/sort )
logresult "Created mobile apps ID list." "Failed to create mobile apps ID list."

# download XML for each mobile device app
while IFS= read aLine
do
	# get the full XML for a mobile app
	/usr/bin/curl -ks $URL/JSSResource/mobiledeviceapplications/id/$aLine --user "$userName:$password" -H "Accept: text/xml" -X GET > "$outputDirectory/$aLine.xml"
	logresult "Retrieving XML for mobile device app ID $aLine." "Failed retrieving XML for mobile device app ID $aLine."
	
	# write the XML to a file and rename the file to the mobile device app name
	appName=$( /usr/bin/xmllint --xpath 'string(/mobile_device_application/general/name)' "$outputDirectory/$aLine.xml" )
				
	# remove any colons, forward slashes and back slashes from the object's name
	cleanedName=$( echo "$appName" | sed 's/[:\/\\]//g' )
	
	/bin/mv "$outputDirectory/$aLine.xml" "$outputDirectory/$cleanedName.xml"
	logresult "Name for mobile device app ID $aLine is \"$cleanedName\"." "Failed reading name for mobile device app ID $aLine."

done <<< "$appIDs"

# get a list of the XML files
xmlFiles=$( /bin/ls "$outputDirectory" )

# process each XML file
while IFS= read aFile
do
	# get a list of scopes from the XML file
	appScopes=$( /usr/bin/xmllint --xpath '/mobile_device_application/scope/*/*/name' "$outputDirectory/$aFile"  | /usr/bin/perl -00pe 's/<\/name><name>/\n/g' | /usr/bin/sed 's/<name>// ; s/<\/name>//' )
	
	# start a file for each scope if necessary
	while IFS= read aScope
	do
		if [ "$aScope" = "" ] ; then
			aScope="All Mobile Devices"	
		fi
		
		if [[ ! -f "$outputDirectory/$aScope.js" ]] ; then
			# begin js file
			/bin/echo "getData(
{
  \"mobile_device_applications\": {" > "$outputDirectory/$aScope.js"
  		logresult "Creating file \"$aScope.js\"." "Failed creating file \"$aScope.js\"."
		fi
		
		# begin new mobile device application
		/bin/echo "    \"mobile_device_application\": {" >> "$outputDirectory/$aScope.js"
		logresult "Starting mobile device application record in file \"$aScope\"."  "Failed starting mobile device application record in file \"$aScope\"."
		
		# write mobile device application category to js file
		appCategory=$( /usr/bin/xmllint --xpath 'string(/mobile_device_application/general/category/name)' "$outputDirectory/$aFile" )
		/bin/echo "      \"category\": \"$appCategory\"," >> "$outputDirectory/$aScope.js"
		logresult "Adding category \"$appCategory\" to mobile device application record \"$appName\" in file \"$aScope\"."  "Failed adding category \"$appCategory\" to mobile device application record \"$appName\" in file \"$aScope\"."
		
		# write mobile device application URL to js file
		appURL=$( /usr/bin/xmllint --xpath 'string(/mobile_device_application/general/itunes_store_url)' "$outputDirectory/$aFile" )
		/bin/echo "      \"itunes_store_url\": \"$appURL\"," >> "$outputDirectory/$aScope.js"
		logresult "Adding URL \"$appURL\" to mobile device application record \"$appName\" in file \"$aScope\"."  "Failed adding URL \"$appURL\" to mobile device application record \"$appName\" in file \"$aScope\"."
		
		# write mobile device application name to js file - no comma
		appName=$( /usr/bin/xmllint --xpath 'string(/mobile_device_application/general/name)' "$outputDirectory/$aFile" )
		/bin/echo "      \"name\": \"$appName\"" >> "$outputDirectory/$aScope.js"
		logresult "Adding name \"$appName\" to mobile device application record \"$appName\" in file \"$aScope\"."  "Failed adding name \"$appName\" to mobile device application record \"$appName\" in file \"$aScope\"."
		
		# end new mobile device application
		/bin/echo "    }" >> "$outputDirectory/$aScope.js"
		logresult "Ending mobile device application record in file \"$aScope\"."  "Failed ending mobile device application record in file \"$aScope\"."
		
	done <<< "$appScopes"
	
	# count each XML file for the log
	appCount=$((appCount+1))
	
done <<< "$xmlFiles"

# get a list of js files
jsFiles=$( /bin/ls -1 "$outputDirectory/"*.js )

# write closing informaiton to each js file
while IFS= read aFile
do
	/bin/echo "});" >> "$aFile"
	logresult "Completing js file \"$aFile\"." "Failed completing js file \"$aFile\"."
done <<< "$jsFiles"

# delete working XML files
/bin/rm -R "$outputDirectory"/*.xml
logresult "Deleting working XML files." "Failed deleting working XML files."

# delete unwanted js files
/usr/bin/find "$outputDirectory" ! -name "_All Student 1 to 1 iPads.js" ! -name "All Cart Based iPads - DEP.js" ! -name "*.xml" -delete
logresult "Deleting unwanted js files." "Failed deleting unwanted js files."

# stop the timer
# calculate how long the script ran

logresult "Completing script."
logresult "Processed $appCount apps."

# the time right now
stopTime=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
duration=$(($stopTime-$startTime))
logresult "Script operations took $duration seconds to complete."

logresult "---------------------- End Script ----------------------

"

exit 0