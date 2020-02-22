#!/bin/bash
# Jan-16-2017 - Initial script by KL3NO.
# April-29-2019 - Added variable for node/ref ID.
 
# Script to (re)connect node when idle to a preset node or reflector.
# custom.crons configured to run this script every 5 minutes so the node will reconnect after 15 to 20 minutes idle.
# Example: */5 * * * * (/home/irlp/custom/idle_recon >/dev/null 2>&1)
# custom_on and custom_off output status of node to custom_status. Script looks at modified time of that file.
# Configure/uncomment this in environment file:
# export CUSTOM_ON=YES
# export CUSTOM_OFF=YES
# You have to create script files in /home/irlp/custom called custom_on and custom_off.
# Example custom_on: echo ON > $CUSTOM/custom_status &
# Example custom_off: echo OFF > $CUSTOM/custom_status &
# Configure custom_decode to connect with no time out.
# Example: if [ "$1" = "9109" ] ; then "$SCRIPT"/end ; connect_to_reflector ref9109 notimeout ; exit 1 ; fi
# Could be tidier, something I threw together for my own use.
# If your internet connection public IP is dynamic, this script won't handle an IP change from router reset or unstable
# connection resets (E.g. DSL) resulting in a change of IP. Some additional logic to check for IP changes and to
# perform a reconnect would be needed.
# Edit your custom_decode, and NODEID reflector of choice.
 
NODEID="9109"
 
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
 
# If enabled, inactive and idle for 15 or more minutes then connect.
if [ -f ~/local/enable ] && [ ! -f ~/local/active ] && [ $(find ~/custom/custom_status -type f -mmin +15 2>/dev/null) ]; then
        echo "$LOGDATETIME Node Idle, reconnecting to $NODEID" >> ~/log/messages
    decode $NODEID
    fi
