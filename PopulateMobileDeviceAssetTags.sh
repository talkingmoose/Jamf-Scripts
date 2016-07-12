#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 
# Written by: William Smith
# Professional Services Engineer
# JAMF Software
# bill@talkingmoose.net
# https://github.com/talkingmoose/Casper-Scripts
#
# Originally posted: April 21, 2015
# Last updated: July 12, 2016
#
# Purpose: Searches a Casper JSS for mobile device assets
# with empty Asset Tag fields and populates those fields from lists
# provided by Apple. Script relies on the JSS API. Requires a text file
# of device serial numbers and asset tags in the format
# "SerialNumber > tab > AssetTag > return" and named FullList.txt in
# the same directory as the script.
#
# The script creates a log file in the same folder as the script.
#
# Except where otherwise noted, this work is licensed under
# http://creativecommons.org/licenses/by/4.0/
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


####################################
# start the timer
####################################


# the time right now
STARTTIME=$( /bin/date '+%s' )


####################################
# JSS URL and credentials
####################################


URL="https://jss.domain.com:8443"
USERNAME="JSSAPI-Editor"
PASSWORD="password"


####################################
# File locations
####################################


# path to this script
CURRENTDIRECTORY=$( /usr/bin/dirname "$0" )

# name of this script
CURRENTSCRIPT=$( /usr/bin/basename -s .sh "$0" )

# set the log file in same directory as script
LOGFILE="$CURRENTDIRECTORY/$CURRENTSCRIPT - $( /bin/date '+%y-%m-%d' ).log"

# store Apple-provided spreadsheets file in same directory as script
FULLLIST=$( /bin/cat "$CURRENTDIRECTORY/FullList.txt" )


####################################
# Functions
####################################


function stripreturns()	{
	STRIPPED=$( /bin/echo $1 | xmllint --noblanks - )
	/bin/echo $STRIPPED
}


function logresult()	{
	if [ $? = 0 ] ; then
	  /bin/date "+%Y-%m-%d %H:%M:%S	$1" >> "$LOGFILE"
	else
	  /bin/date "+%Y-%m-%d %H:%M:%S	$2" >> "$LOGFILE"
	fi
}


####################################
# Create list of computer
# serial numbers without asset tags
####################################


# start the log
logresult "--------------------- Begin Script ---------------------"

# rotate logs -- delete all but the five most recent log files
DELETEOLDLOGS=$( /bin/ls -1t "$CURRENTDIRECTORY/$CURRENTSCRIPT"*.log | /usr/bin/tail -n +6 )

while IFS= read -r ALINE
do
	LOGFILENAME=$( /usr/bin/basename "$ALINE" )
	/bin/rm "$ALINE"
	logresult "Deleting old log file: $LOGFILENAME."
done <<< "$DELETEOLDLOGS"

# creating a list of computers without asset tags
logresult "Gathering list of computers without asset tags."

# human-readable POST XML for a new search
TEHxml="<advanced_mobile_device_search>
		<name>Mobile Devices with no asset tags as of $( /bin/date )</name>
		<criteria>
			<criterion>
				<name>Asset Tag</name>
				<priority>0</priority>
				<and_or>and</and_or>
				<search_type>is</search_type>
				<value></value>
			</criterion>
		</criteria>
		<display_fields>
			<display_field>
				<name>Serial Number</name>
			</display_field>
		</display_fields>
	</advanced_mobile_device_search>"

# this strips the returns before POSTing the XML
POSTxml=$( stripreturns "$TEHxml" )

# create a temporary advanced computer search in the JSS using the criteria in the POST XML above		
CREATESEARCH=$( /usr/bin/curl -k -s 0 $URL/JSSResource/advancedmobiledevicesearches/id/0 --user "$USERNAME:$PASSWORD" -H "Content-Type: text/xml" -X POST -d "$POSTxml" )

# log the result
logresult "Created temporary Advanced Mobile Device Search in JSS at $URL." "Failed creating temporary Advanced Mobile Device Search in JSS at $URL."

# get temporary advanced computer search ID
SEARCHID=$( /bin/echo $CREATESEARCH | /usr/bin/awk -F "<id>|</id>" '{ print $2 }' )

# run the search and return serial numbers
SEARCH=$( /usr/bin/curl -k -s 0 $URL/JSSResource/advancedmobiledevicesearches/id/$SEARCHID --user "$USERNAME:$PASSWORD" -H "Accept: text/xml" -X GET )

# turn the returned list into a list of just serial numbers
SERIALNUMBERLIST=$( /bin/echo "$SEARCH" | /usr/bin/perl -lne 'BEGIN{undef $/} while (/<Serial_Number>(.*?)<\/Serial_Number>/sg){print $1}' )

# count the serial numbers and log the results
SERIALNUMBERCOUNT=$( /bin/echo $SERIALNUMBERLIST | /usr/bin/wc -w )
SERIALNUMBERCOUNT=$( stripreturns "$SERIALNUMBERCOUNT" )

# log the result
logresult "Found $SERIALNUMBERCOUNT mobile devices without asset tags." "Failed finding mobile devices without asset tags."

# delete the temporary advanced computer search
/usr/bin/curl -k -s 0 $URL/JSSResource/advancedmobiledevicesearches/id/$SEARCHID --user "$USERNAME:$PASSWORD" -X DELETE

# log the result
logresult "Deleted temporary Advanced Mobile Device Search." "Failed deleting temporary Advanced Computer Search."


####################################
# Compare Apple's list of serial
# numbers with the found list of
# serial numbers. Populate asset
# tags for serial numbers that
# have no asset tag.
####################################

for ALINE in $SERIALNUMBERLIST
do
	MATCHEDDEVICE=$( echo "$FULLLIST" | grep "$ALINE" )
	
	if [ "$MATCHEDDEVICE" = "" ] ; then
		# log the result
		logresult "Serial number $ALINE not found in the spreadsheet from Apple."
	else
		SERIALNUMBER=$( /bin/echo "$MATCHEDDEVICE" | /usr/bin/awk '{ print $1 }' )
		ASSETTAG=$( /bin/echo "$MATCHEDDEVICE" | /usr/bin/awk '{ print $2 }' )
		
		THExml="<mobile_device>
				<general>
					<asset_tag>$ASSETTAG</asset_tag>
				</general>
			</mobile_device>"
		
		PUTxml=$( stripreturns "$THExml" )
		
		/usr/bin/curl -k 0 $URL/JSSResource/mobiledevices/serialnumber/$SERIALNUMBER --user "$USERNAME:$PASSWORD" -H "Content-Type: text/xml" -X PUT -d "$PUTxml"
		
		# log the result
		logresult "Added asset tag $ASSETTAG to mobile device with serial number $SERIALNUMBER." "Failed to add asset tag $ASSETTAG to mobile device with serial number $SERIALNUMBER."
		
		# keep count of populated asset tags
		MATCHED=$((MATCHED+1))
	fi
	
done


####################################
# stop the timer
# calculate how long the script ran
####################################


logresult "Completing script."
logresult "Populated $MATCHED asset tags of $SERIALNUMBERCOUNT mobile devices without asset tags."

# the time right now
STOPTIME=$( /bin/date '+%s' )

# subtract start time from stop time and log the time in seconds
DIFF=$(($STOPTIME-$STARTTIME))
logresult "Script operations took $DIFF seconds to complete."


logresult "---------------------- End Script ----------------------

"

exit 0
