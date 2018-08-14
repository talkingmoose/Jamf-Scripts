#!/bin/sh

<<ABOUT_THIS_SCRIPT
-----------------------------------------------------------------------

	Written by:William Smith
	Professional Services Engineer
	Jamf
	bill@talkingmoose.net
	https://github.com/talkingmoose/Jamf-Scripts
	
	Originally posted: Feburary 21, 2017
	Last updated: August 13, 2018

	Purpose: Run this script as part of a Jamf Pro policy to delete
	unwanted local user accounts from a Mac. The script will not affect
	Active Directory mobile accounts.

	Except where otherwise noted, this work is licensed under
	http://creativecommons.org/licenses/by/4.0/

	"If candy is dandy but liquor is quicker, may I recommend NyQuil?"

INSTRUCTIONS

	1) Log in to the Jamf Pro server.
	2) In your Jamf Pro server navigate to Settings > Computer Management
	   > Scripts.
	3) Click the " + " button to create a new script with these settings:
	   Display Name: Office 2016 License
	   Category: <your choice>
	   Notes: Deletes local non-mobile and non-Active Directory user accounts.
	   Script: < Copy and paste this entire script >
	4) Save the script.
	5) Add the script to a policy or run using Casper Remote.
	6) Consult the Jamf Pro policy log for results of the script.
	
-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT

# EDIT LIST: local user accounts to keep, separating them with a space
keepUsers="talkingmoose mmoose"
echo "Keeping users: $keepUsers."

# get currently logged in user
# cannot delete an active user
currentUser=$( /usr/bin/stat -f "%Su" /dev/console )
echo "Currently logged in user: $currentUser."

# create a list of local usernames (non-AD) with UIDs between 500 and 1024
userList=$( /usr/bin/dscl /Local/Default -list /Users uid | /usr/bin/awk '$2 >= 501 && $2 <= 1024 { print $1 }' )
echo "Local non-AD users with UIDs between 500 and 1024:\n$userList"

while IFS= read aUser
do

	# checks to see if an O365 subscription license file is present for each user
	if [[ "$keepUsers" != *"$aUser"* && "$aUser" != "$currentUser" ]] ; then
		/usr/bin/dscl . delete "/Users/$aUser" # comment this line to get results of the script without making changes
		echo "Deleted user: $aUser."
	fi
done <<< "$userList"

exit 0
