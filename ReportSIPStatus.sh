#!/bin/sh

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 
# Written by: William Smith
# Professional Services Engineer
# JAMF Software
# bill@talkingmoose.net
# https://github.com/talkingmoose/Casper-Scripts
#
# Originally posted: November 20, 2016
# Last updated: November 20, 2016
#
# Purpose: Shell script for JSS Extension Attribute to report SIP status
# as Enabled, Disabled or Not Supported.
#
# Except where otherwise noted, this work is licensed under
# http://creativecommons.org/licenses/by/4.0/
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Instructions:
# In the JSS, create a new Extension Attribute:
# Display Name: SIP Status
# Description: Report whether System Integrity Protection is Enabled or Disabled.
# Data Type: Sting
# Inventory Display: Operating System
# Input Type Script
# Script: Contents of this script 

# get current OS build number

buildVersion=$( sw_vers -buildVersion | cut -c 1,2 )	# get first two characters of build
														# 16 = 10.12
														# 15 = 10.11
														# 14 = 10.10
														# ...

# if current OS is 10.10 or less,
# then report "Not Supported" and stop

if [ $buildVersion -le 14 ]; then						# evaluate build version
	echo "<result>Not Supported</result>"				# report "Not Supported"
	exit 0												# and stop the script
fi

# otherwise, report SIP status

status=$( csrutil status | grep 'enabled' )				# get SIP enabled status

if [[ "$status" ]]; then								# evaluate SIP status
	echo "<result>Enabled</result>"						# report "Enabled"
else
	echo "<result>Disabled</result>"					# or report "Disabled"
fi

exit 0