#!/bin/bash
                            
<<ABOUT_THIS_SCRIPT
-----------------------------------------------------------------------

	Written by: William Smith
	Professional Services Engineer
	JAMF Software
	bill@talkingmoose.net
	https://github.com/talkingmoose/Casper-Scripts

	Originally posted: January 1, 2017
	Last updated: January 1, 2017

	Purpose: When used with Self Service, enables a non-admin user
	to change time zone on his or her Mac.
	
	• The script will offer to set the time zone automatically
	  if it detects the time zone is set manually.
	• Otherwise, the script will first present a short list
	  of commonly used time zones.
	• If selected, the script will present a full set choices
	  based on UNIX time zones.

	The script creates a log file in the user's ~/Library/Logs folder.

	Except where otherwise noted, this work is licensed under
	http://creativecommons.org/licenses/by/4.0/

	"To script is admin.
	To comment divine."

INSTRUCTIONS

	1) Below, create a short list of common time zones. Include as many
	   as needed to make the script easier to use.
	2) Numbers for each time zone in the short listmust be unique
	   and sequential beginning with "1".
	3) Add this script to your Jamf server.
	4) Create an ongoing Self Service item with the script and
	   enabled for offline use.
	
-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT

# short time zone list

name[1]="London (+0:00)"
zone[1]="Europe/London"

name[2]="US Atlantic (-5:00)"
zone[2]="America/New_York"

name[3]="US Central (-6:00)"
zone[3]="America/Chicago"

name[4]="US Mountain (-7:00)"
zone[4]="America/Denver"

name[5]="US Pacific (-8:00)"
zone[5]="America/Los_Angeles"

name[6]="Chennai (+5:30)"
zone[6]="Asia/Colombo"

# set up logging

# name of this script
currentScript=$( /usr/bin/basename -s .sh "$0" )

# get path to the current user's home folder
currentUserFolder=$( eval /bin/echo ~$( logname ) )

# set log file path
logFile="$currentUserFolder/Library/Logs/$currentScript.log"

# functions
function logresult()	{
	if [ $? = 0 ] ; then
	  /bin/date "+%Y-%m-%d %H:%M:%S	$1" >> "$logFile"
	else
	  /bin/date "+%Y-%m-%d %H:%M:%S	$2" >> "$logFile"
	fi
}

# use this icon (Date & Time preference pane icon) in dialogs
dialogIcon="/System/Library/PreferencePanes/DateAndTime.prefPane/Contents/Resources/DateAndTime.icns"


# determine whether time zone is set automatically
setAutomatically=$( /usr/bin/defaults read /Library/Preferences/com.apple.timezone.auto Active )

if [ "$setAutomatically" = 0 ]; then # time zone is set manually, offer to set it automatically

	logresult "Time zone is set manually." "Time zone is set automatically."
	
	userResponse=$( /usr/bin/osascript -e "button returned of (display dialog \"Your Mac's time zone was manually set to $( date +%Z ). Would you like to try automatically setting it?\" buttons {\"Manual\", \"Automatic\"} default button {\"Automatic\"} with title \"Set Time Zone\" with icon file POSIX file \"$dialogIcon\")" )

else

	logresult "Time zone is set manually." "Time zone is set automatically."
	
fi


if [ "$userResponse" = "Automatic" ]; then # set the time zone to update automatically

	logresult "User has chosen to set time zone automatically."
	
	# modify the time zone plist to update automatically
	/usr/bin/defaults write /Library/Preferences/com.apple.timezone.auto Active -bool TRUE
	logresult "Setting time zone automatically." "Failed setting time zone automatically."
	
	# open the date & time system preference for the user to verify settings
	# this is a workaround to force the Mac to update settings after changing the plist
	/usr/bin/open "/System/Library/PreferencePanes/DateAndTime.prefPane"
	
	/bin/sleep 2 # allow time to change settings
	
	# notify the user time zone is set to update automatically
	theCommand="display dialog \"Your system is now set to $( date +%Z ) timezone. Opening the Time Zone preference pane for you to verify settings.\" with title \"Set Time Zone\" with icon file POSIX file \"$dialogIcon\" buttons {\"OK\"} default button {\"OK\"}"
	/usr/bin/osascript -e "$theCommand"
	
	exit 0
	
fi


# if user chooses to manually set a time zone

logresult "User has chosen to set time zone manually."

# present the user the short list of time zones

listNames=$( /usr/bin/printf '%s\n' "${name[@]}" )

theCommand="choose from list (every paragraph of \"$listNames\") with prompt \"Choose your current time zone.\" OK button name \"OK\" cancel button name \"More Choices\" with title \"Set Time Zone\""
listChoice=$( /usr/bin/osascript -e "$theCommand" )

# determine which time zone the user selected from the list
choiceIndex=$( /usr/bin/sdiff <(/bin/echo "$listNames") <(/bin/echo "$listChoice") | /bin/cat -n | /usr/bin/grep -v "<" | /usr/bin/awk '{ print $1 }' )

if [[ "$listChoice" != false ]]; then # user has chosen a time zone from the short list

	chosenTimeZone="${zone[$choiceIndex]}"
	
else # user has requested to see more time zones
	
	# read system time zone list
	timeZoneList=$( /usr/sbin/systemsetup -listtimezones )

	# parse and list regions from time zone list
	timeZoneRegion=$( /bin/echo "$timeZoneList" | /usr/bin/grep / | /usr/bin/awk -F '( |/)' '{ print $2 }' | /usr/bin/sort | /usr/bin/uniq )
	theCommand="choose from list (every paragraph of \"$timeZoneRegion\") with prompt \"Choose your current world region.\" with title \"Set Time Zone\""
	selectedRegion=$( /usr/bin/osascript -e "$theCommand" )

	# parse and list cities for chosen region in time zone list
	timeZoneCity=$( /bin/echo "$timeZoneList" | /usr/bin/grep "$selectedRegion" | /usr/bin/awk -F '(\/)' '{ print $2 }' | /usr/bin/sort | /usr/bin/uniq )
	theCommand="choose from list (every paragraph of \"$timeZoneCity\") with prompt \"Choose the nearest city to you for world region $selectedRegion.\" with title \"Set Time Zone\""
	selectedCity=$( /usr/bin/osascript -e "$theCommand" )
	
	# set new time zone to Region/City format
	chosenTimeZone="$selectedRegion/$selectedCity"
	
fi


# disable setting time zone automatically
/usr/bin/defaults write /Library/Preferences/com.apple.timezone.auto Active -bool False

# set the time zone manually to chosen time zone
/usr/sbin/systemsetup -settimezone "$chosenTimeZone"

logresult "Setting time zone to $chosenTimeZone." "Failed setting time zone to $chosenTime."

# open the date & time system preference for the user to verify settings
/usr/bin/open "/System/Library/PreferencePanes/DateAndTime.prefPane"
/bin/sleep 2 # allow time to change settings

# notify the user time zone has been set
theCommand="display dialog \"Your system is now set to $( date +%Z ) timezone. Opening the Time Zone preference pane for you to verify settings.\" with title \"Set Time Zone\" with icon file POSIX file \"$dialogIcon\" buttons {\"OK\"} default button {\"OK\"}"
/usr/bin/osascript -e "$theCommand"

exit 0