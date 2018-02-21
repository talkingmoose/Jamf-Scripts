#!/bin/sh

<<ABOUT_THIS_SCRIPT
-----------------------------------------------------------------------

	Written by: William Smith
	Professional Services Engineer
	JAMF Software
	bill.smith@jamf.com

	Originally posted: November 6, 2017

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
	2) Copy / paste the tab-delimited columns (no headers)
	   into the removeList variable at the beginning of the script.
	3) Add the Script to Jamf Pro under:
	   Settings > Computer Management > Scripts
	4) Create a Smart Group of devices with SentinelOne installed.
	5) Add the script to a Policy.
	6) Set the Policy to trigger as needed (Login or Recurring Check-in).
	7) Set the Policy to Ongoing Frequency.
	8) Set the Policy to Update Inventory when done.
	9) Scope the policy to the Smart Group.

-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT

# script parameters set in Jamf Pro
jamfAPIUser="$4"
jamfAPIpassword="$5"
usageDays="$6" # 60 days by default
dataFolder="$7" # e.g. Talking Moose Industries (created in /Library)

# get device's Jamf Pro Server URL
jssURL=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url )

# get device UUID/UDID
deviceUDID=$( system_profiler SPHardwareDataType | grep "Hardware UUID" | awk -F ": " '{ print $2 }' )

# get start date - Today minus usageDays
startDate=$( date -v-${usageDays}d "+%Y-%m-%d" )

# get end date - Today
endDate=$( date "+%Y-%m-%d" )

# get application usage once per day and write to a local file
lastCheck=$( defaults read "/Library/${dataFolder}/applicationusage.plist" LastCheck )

if [ "$lastCheck" != "$endDate" ] ; then

	# retrieve usage XML from Jamf Pro server
	usageXML=$( /usr/bin/curl -s "$jssURL/JSSResource/computerapplicationusage/udid/$deviceUDID/${startDate}_${endDate}" --user "$jamfAPIUser:$jamfAPIpassword" -H "Accept: text/xml" -X GET)

	# format usage XML for readability and parsing
	formattedXML=$( echo "$usageXML" | xmllint --format - )
	
	defaults write "/Library/${dataFolder}/applicationusage.plist" LastCheck -string "$endDate"
	defaults write "/Library/${dataFolder}/applicationusage.plist" Days -string "$usageDays"
	echo "$formattedXML" > "/Library/${dataFolder}/latestXML.txt"
	
fi

exit 0
