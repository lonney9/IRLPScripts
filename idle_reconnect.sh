#!/bin/bash


# IRLP script to (re)connect node when idle to a preset reflector or node with notimeout
# notimeout is handled by custom/custom_decode when the node is dialed by the script or user


# Jan-16-2017 - Initial script - KL3NO.
# Apr-29-2019 - Added variable for node/ref ID - K1LH (upgraded from KL3NO).
# Fed-07-2025 - Updated comment with the setup commands to run - K1LH.


# Set Reflector or Node ID
# Prefix with special character if needed, this is configured in custom/custom_decode with the notimeout line

# East Coast Reflector ( https://www.eastcoastreflector.com/ )
NODE_ID="C9050"

# Set the idle timeout in minutes
IDLE_TIME="60"


## README ##
## Configure the system for the script ##
## $CUSTOM is usually /home/irlp/custom/ ## 
## Unless NOTED all files should be created/edited as user repeater ##

# EDIT  $CUSTOM/custom_decode  to connect with no time out
# Example: This will only connect to 9050 with notimeout when C9050 is dialed by the script or a radio user
# Add this line with out the leading "#" to $CUSTOM/custom_decode under
# any node control (enable/disable) commands but above the exit 0 at the bottom:
# "if [ "$1" = "C9050" ] ; then "$SCRIPT"/end ; connect_to_reflector ref9109 notimeout ; exit 1 ; fi"


# EDIT  $CUSTOM/environment  (NOTE as root) add or uncomment (remove the "#") the following lines:
# export CUSTOM_ON=YES
# export CUSTOM_OFF=YES

# CREATE scripts in $CUSTOM (/home/irlp/custom) called "custom_on" and "custom_off"
# Each contain the following:
# Example custom_on: echo ON > $CUSTOM/custom_status &
# Example custom_off: echo OFF > $CUSTOM/custom_status &
# Create the initial custom_status file: touch $CUSTOM/custom_status
# This script looks at modified time of custom_status to know when last active

# EDIT  $CUSTOM/custom.crons to run this script every 5 minutes
# The node will reconnect after $IDLE_TIME (minutes)
# Example: */5 * * * * (/home/irlp/custom/idle_reconnect.sh >/dev/null 2>&1)

# If the internet connection public IP is dynamic (Ex DSL) this script won't handle an IP change from router reset
# or unstable connection resets resulting in a change of IP. Some additional logic to check for IP changes and to
# perform a reconnect would be needed.

## END README ##
## NO EDITS below here should be needed ##


# Current time in human format for log file.
LOGDATETIME=`date +"%b %d %Y %T %z"`
 
# Make sure we are user repeater.
if [ `/usr/bin/whoami` != "repeater" ] ; then
    echo This program must be run as user REPEATER!
    exit 1
    fi
 
# Make sure we have sourced the environment file.
if [ "$RUN_ENV" != "TRUE" ] ; then
    . /home/irlp/custom/environment
    fi
 
# If enabled, inactive and idle for $IDLE_TIME or more minutes then connect.
if [ -f ~/local/enable ] && [ ! -f ~/local/active ] && [ $(find ~/custom/custom_status -type f -mmin +${IDLE_TIME} 2>/dev/null) ]; then
        echo "$LOGDATETIME Node Idle, reconnecting to $NODE_ID" >> ~/log/messages
    decode $NODE_ID
    fi
