#!/bin/sh

<<ABOUT_THIS_SCRIPT
-----------------------------------------------------------------------

	Written by: William Smith
	Professional Services Engineer
	JAMF Software
	bill.smith@jamf.com
	https://github.com/talkingmoose/Jamf-Scripts

	Originally posted: November 7, 2017
	Update: August 13, 2018

	Purpose: Jamf Policy script to collection application usage stats
	over a period of time. Stats are stored locally on each Mac. Use
	a Jamf Extension Attribute to collect the stats.

INSTRUCTIONS

	1) Create a new script in Jamf Pro:
	   Name: Collect application usage
	   Parameter 4: Jamf API user
	   Parameter 5: Jamf API user password
	   Parameter 6: Usage days to collect
	   Parameter 7: Data folder
	2) Add the script to a policy set to run once per day.
	3) Set values for each of the script parameters.
	4) Scope the policy to the Smart Group.
	5) Create an Extension Attribute for each application to report.
	   See applicationUsageEA.sh.

-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT

# script parameters set in Jamf Pro
jamfAPIUser="$4"
jamfAPIpassword="$5"
usageDays="$6" # 60 days by default
dataFolder="$7" # e.g. Talking Moose Industries (created in /Library)

# get device's Jamf Pro Server URL
jssURL=$( /usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url )

# get device UUID/UDID
deviceUDID=$( /usr/sbin/system_profiler SPHardwareDataType | /usr/bin/grep "Hardware UUID" | /usr/bin/awk -F ": " '{ print $2 }' )

# get start date - Today minus usageDays
startDate=$( /bin/date -v-${usageDays}d "+%Y-%m-%d" )

# get end date - Today
endDate=$( /bin/date "+%Y-%m-%d" )

# get application usage once per day and write to a local file
lastCheck=$( /usr/bin/defaults read "/Library/${dataFolder}/applicationusage.plist" LastCheck )

if [ "$lastCheck" != "$endDate" ] ; then

	# retrieve usage XML from Jamf Pro server
	usageXML=$( /usr/bin/curl -s "$jssURL/JSSResource/computerapplicationusage/udid/$deviceUDID/${startDate}_${endDate}" --user "$jamfAPIUser:$jamfAPIpassword" -H "Accept: text/xml" -X GET)

	# format usage XML for readability and parsing
	formattedXML=$( echo "$usageXML" | xmllint --format - )
	
	/usr/bin/defaults write "/Library/${dataFolder}/applicationusage.plist" LastCheck -string "$endDate"
	/usr/bin/defaults write "/Library/${dataFolder}/applicationusage.plist" Days -string "$usageDays"
	echo "$formattedXML" > "/Library/${dataFolder}/latestXML.txt"
	
fi

exit 0
