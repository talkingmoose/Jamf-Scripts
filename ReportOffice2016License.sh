#!/bin/sh

<<ABOUT_THIS_SCRIPT
-----------------------------------------------------------------------

	Written by:William Smith
	Professional Services Engineer
	Jamf
	bill@talkingmoose.net
	https://github.com/talkingmoose/Jamf-Scripts
	
	Adapted from a script by: Paul Bowden
	Software Engineer
	Microsoft Corporation
	pbowden@microsoft.com
	https://github.com/pbowden-msft/Unlicense

	Originally posted: January 7, 2017
	Last updated: August 13, 2018

	Purpose: Use this script as part of an extension attribute in Jamf
	to report the type of Microsoft Office 2016 licensing in use.

	Except where otherwise noted, this work is licensed under
	http://creativecommons.org/licenses/by/4.0/

	"Communication happens when I know that you know what I know."

INSTRUCTIONS

	1) Log in to the Jamf Pro server.
	2) In Jamf Pro navigate to Settings > Computer Management > Extension Attributes.
	3) Click the " + " button to create a new extension attribute with these settings:
	   Display Name: Office 2016 License
	   Description: Reports Office 2016 licenses in use.
	   Data Type: String
	   Inventory Display: Extension Attributes
	   Input Type: Script
	   Script: < Copy and paste this entire script >
	4) Save the extension attribute.
	5) Use Recon.app or "sudo jamf recon" to inventory a Mac with Office 2016.
	6) View the results under the Extension Attributes payload
	   of the computer's record or include the extension attribute
	   when adding criteria to an Advanced Computer Search or Smart Group.
	
-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT


# Functions
function DetectVolumeLicense {
	volumeLicense="/Library/Preferences/com.microsoft.office.licensingV2.plist"
	
	# checks to see if a volume license file is present
	if [ -f "$volumeLicense" ]; then
		/bin/echo "Yes"
	else
		/bin/echo "No"
	fi
}

function DetectO365License {
	# creates a list of local usernames with UIDs above 500 (not hidden)
	userList=$( /usr/bin/dscl /Local/Default -list /Users uid | /usr/bin/awk '$2 >= 501 { print $1 }' )
	
	while IFS= read aUser
	do
		# get the user's home folder path
		homePath=$( eval /bin/echo ~$aUser )
	
		# list of potential Office 365 activation files
		O365SUBMAIN="$homePath/Library/Group Containers/UBF8T346G9.Office/com.microsoft.Office365.plist"
		O365SUBBAK1="$homePath/Library/Group Containers/UBF8T346G9.Office/com.microsoft.e0E2OUQxNUY1LTAxOUQtNDQwNS04QkJELTAxQTI5M0JBOTk4O.plist"
		O365SUBBAK2="$homePath/Library/Group Containers/UBF8T346G9.Office/e0E2OUQxNUY1LTAxOUQtNDQwNS04QkJELTAxQTI5M0JBOTk4O" # hidden file
	
		# checks to see if an O365 subscription license file is present for each user
		if [[ -f "$O365SUBMAIN" || -f "$O365SUBBAK1" || -f "$O365SUBBAK2" ]]; then
			activations=$((activations+1))
		fi
	done <<< "$userList"
	
	# returns the number of activations to O365ACTIVATIONS
	/bin/echo $activations
}

## Main

VLPRESENT=$(DetectVolumeLicense)
O365ACTIVATIONS=$(DetectO365License)

if [ "$VLPRESENT" == "Yes" ] && [ "$O365ACTIVATIONS" ]; then
	/bin/echo "<result>Volume and Office 365 licenses detected. Only the volume license will be used.</result>"

elif [ "$VLPRESENT" == "Yes" ]; then
	/bin/echo "<result>Volume license</result>"
	
elif [ "$O365ACTIVATIONS" ]; then
	/bin/echo "<result>Office 365 activations: $O365ACTIVATIONS</result>"
	
elif [ "$VLPRESENT" == "No" ] && [ ! "$O365ACTIVATIONS" ]; then
	/bin/echo "<result>No licenses</result>"
fi

exit 0