#!/bin/sh

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 
# Written by: William Smith
# Professional Services Engineer
# Jamf
# bill@talkingmoose.net
# https://github.com/talkingmoose/Jamf-Scripts
#
# Originally posted: November 20, 2016
# Last updated: August 13, 2018
#
# Purpose: Shell script for Jamf Pro Extension Attribute to report SIP status
# as Enabled, Disabled or Not Supported.
#
# Except where otherwise noted, this work is licensed under
# http://creativecommons.org/licenses/by/4.0/
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Instructions:
# In the Jamf Pro server, create a new Extension Attribute:
# Display Name: SIP Status
# Description: Report whether System Integrity Protection is Enabled or Disabled.
# Data Type: String
# Inventory Display: Operating System
# Input Type: Script
# Script: Contents of this script 

#!/bin/sh

# run command to report SIP status
status=$( /usr/bin/csrutil status 2>/dev/null )

case "$status" in
	
	# SIP is enabled
	"System Integrity Protection status: enabled.")
		echo "<result>Enabled</result>";;
		
	# SIP is disabled
	"System Integrity Protection status: disabled.")
		echo "<result>Disabled</result>";;
	
	# SIP is not supported
	"")
		echo "<result>Not Supported</result>";;
esac

exit 0