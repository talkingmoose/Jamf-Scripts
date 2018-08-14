#!/bin/sh

<<ABOUT_THIS_SCRIPT
-----------------------------------------------------------------------

	Written by: William Smith
	Professional Services Engineer
	Jamf
	bill@talkingmoose.net
	https://github.com/talkingmoose/Jamf-Scripts

	Originally posted: November 7, 2017
	Updated: August 13, 2018

	Purpose: Jamf Pro Extension Attribute to collect application usage stats
	from raw data is stored locally on each Mac. Use a Jamf Pro Script/Policy
	to read and store the stats on each Mac.

INSTRUCTIONS

	1) Create a new extension attribute in Jamf Pro:
	   Name: Slack.app usage
	   Data Type: String
	   Inventory Display: Extension Attributes
	   Input Type: Script
	   Script: Entire contents of this script
	2) Set the application name in this script.
	3) Set the data folder name in this script.
	4) Create a script and policy to collect usage data daily.
	   See applicationUsage.sh.

-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT

# full application name
application="Safari.app"

# data folder name set in the policy "Data folder" script parameter
dataFolder="Talking Moose Industries"

# read locally stored XML for listed application and get list of open seconds
openSecondsList=$( /usr/bin/grep "$application" -A 3 "/Library/${dataFolder}/latestXML.txt" | /usr/bin/grep "<open>" | /usr/bin/awk -F "<open>|</open>" '{ print $2 }' )

# sum open seconds
openSeconds=$( echo "$openSecondsList" | /usr/bin/paste -sd+ - | /usr/bin/bc )

# calculate open minutes
openMinutes=$((openSeconds/60))

# read locally stored application usage file for number of days in report
usageDays=$( /usr/bin/defaults read "/Library/${dataFolder}/applicationusage.plist" Days )

# return app usage to JSS
echo "<result>$openMinutes minutes over $usageDays days</result>"

exit 0