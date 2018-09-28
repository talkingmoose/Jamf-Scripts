#!/bin/sh

<<ABOUT_THIS_SCRIPT
-----------------------------------------------------------------------
	Written by: William Smith
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
	Last updated: September 22, 2018
	
	Purpose: Use this script as part of an extension attribute in Jamf
	to report the type of Microsoft Office licensing in use.
	
	Except where otherwise noted, this work is licensed under
	http://creativecommons.org/licenses/by/4.0/
	
	"Communication happens when I know that you know what I know."
	
INSTRUCTIONS

	1) Log in to the Jamf Pro server.
	2) In Jamf Pro navigate to Settings > Computer Management > Extension Attributes.
	3) Click the " + " button to create a new extension attribute with these settings:
	   Display Name: Microsoft Office for Mac License
	   Description: Reports Microsoft Office for Mac licenses in use.
	   Data Type: String
	   Inventory Display: Extension Attributes
	   Input Type: Script
	   Script: < Copy and paste this entire script >
	4) Save the extension attribute.
	5) Use Recon.app or "sudo jamf recon" to inventory a Mac with Office 2016 or 2019.
	6) View the results under the Extension Attributes payload
	   of the computer's record or include the extension attribute
	   when adding criteria to an Advanced Computer Search or Smart Group.
	
-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT


# Functions
function DetectPerpetualLicense {
	perpetualLicense="/Library/Preferences/com.microsoft.office.licensingV2.plist"
	
	# checks to see if a perpetual license file is present and what kind
	if [[ $( /bin/cat "$perpetualLicense" | grep "A7vRjN2l/dCJHZOm8LKan11/zCYPCRpyChB6lOrgfi" ) ]]; then
		echo "Office 2019 Volume"
	elif [[ $( /bin/cat "$perpetualLicense" | grep "Bozo+MzVxzFzbIo+hhzTl4JKv18WeUuUhLXtH0z36s" ) ]]; then
		echo "Office 2019 Preview Volume"
	elif [[ $( /bin/cat "$perpetualLicense" | grep "A7vRjN2l/dCJHZOm8LKan1Jax2s2f21lEF8Pe11Y+V" ) ]]; then
		echo "Office 2016 Volume"
	elif [[ $( /bin/cat "$perpetualLicense" | grep "DrL/l9tx4T9MsjKloHI5eX" ) ]]; then
		echo "Office 2016 Home and Business"
	elif [[ $( /bin/cat "$perpetualLicense" | grep "C8l2E2OeU13/p1FPI6EJAn" ) ]]; then
		echo "Office 2016 Home and Student"
	elif [[ $( /bin/cat "$perpetualLicense" | grep "Bozo+MzVxzFzbIo+hhzTl4m" ) ]]; then
		echo "Office 2019 Home and Business"
	elif [[ $( /bin/cat "$perpetualLicense" | grep "Bozo+MzVxzFzbIo+hhzTl4j" ) ]]; then
		echo "Office 2019 Home and Student"
	else	
		echo "No"
	fi
}

function DetectO365License {
	# creates a list of local usernames with UIDs above 500 (not hidden)
	userList=$( /usr/bin/dscl /Local/Default -list /Users uid | /usr/bin/awk '$2 >= 501 { print $1 }' )
	
	while IFS= read aUser
	do
		# get the user's home folder path
		homePath=$( eval echo ~$aUser )
	
		# list of potential Office 365 activation files
		O365SUBMAIN="$homePath/Library/Group Containers/UBF8T346G9.Office/com.microsoft.Office365.plist"
		O365SUBBAK1="$homePath/Library/Group Containers/UBF8T346G9.Office/com.microsoft.e0E2OUQxNUY1LTAxOUQtNDQwNS04QkJELTAxQTI5M0JBOTk4O.plist"
		O365SUBBAK2="$homePath/Library/Group Containers/UBF8T346G9.Office/e0E2OUQxNUY1LTAxOUQtNDQwNS04QkJELTAxQTI5M0JBOTk4O" # hidden file
		O365SUBMAINB="$homePath/Library/Group Containers/UBF8T346G9.Office/com.microsoft.Office365V2.plist"
		O365SUBBAK1B="$homePath/Library/Group Containers/UBF8T346G9.Office/com.microsoft.O4kTOBJ0M5ITQxATLEJkQ40SNwQDNtQUOxATL1YUNxQUO2E0e.plist"
		O365SUBBAK2B="$homePath/Library/Group Containers/UBF8T346G9.Office/O4kTOBJ0M5ITQxATLEJkQ40SNwQDNtQUOxATL1YUNxQUO2E0e"
	
		# checks to see if an O365 subscription license file is present for each user
		if [[ -f "$O365SUBMAIN" || -f "$O365SUBBAK1" || -f "$O365SUBBAK2" || -f "$O365SUBMAINB" || -f "$O365SUBBAK1B" || -f "$O365SUBBAK2B" ]]; then
			activations=$((activations+1))
		fi
	done <<< "$userList"
	
	# returns the number of activations to O365Activations
	echo $activations
}

## Main

PLPresent=$(DetectPerpetualLicense)
O365Activations=$(DetectO365License)

if [ "$PLPresent" != "No" ] && [ "$O365Activations" ]; then
	echo "<result>$PLPresent and Office 365 licenses detected. Only the $PLPresent license will be used.</result>"

elif [ "$PLPresent" != "No" ]; then
	echo "<result>$PLPresent license</result>"
	
elif [ "$O365Activations" ]; then
	echo "<result>Office 365 activations: $O365Activations</result>"
	
elif [ "$PLPresent" == "No" ] && [ ! "$O365Activations" ]; then
	echo "<result>No licenses</result>"
fi

exit 0