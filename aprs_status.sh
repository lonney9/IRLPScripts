#!/bin/bash
#-----------------------------------------------------------------------
#              D O   N O T   E D I T   T H I S   F I L E 
# U N L E S S   Y O U   R E A L L Y   K N O W   W H A T   Y O U   A R E
#    D O I N G .   I F   Y O U   B R E A K   I T   Y O U ' R E   O N
#                         Y O U R   O W N ! ! !
#-----------------------------------------------------------------------
# irlp_aprs_status IRLP beacon script
#
# V1.0 - 26 Apr 03
# V2.0 12Jan05  ZL1AMW  Re-written from origonal (by VK2XJG?)
#                       Now uses TCP connection to APRS server
#                       Allows user configuration of icon and server details
#                       Sends icon as an object
# v2.1 14Jun05  ZL1AMW  update from sugestions received, 
#                       added D7 mode, improve README
# v2.2 25Jun05  ZL1AMW  further improvement to README
#                       bugfix for simplex frequency
# v2.3 26Jun05  ZL1AMW  improved enviro variable loading
# V2.4 01Jul05  ZL1AMW  fix bug with date format
# V2.5 05Jul05  ZL1AMW  fix for 3 digit node numbers
# V2.6 11Sep05  KC6HUR  Added EchoLink compatibility;
#                       Added BUSY status indicators;
#                       Now allows greater flexability in configuration
# V4.0 10Apr07  KC6HUR  Completely did away with the perl script
#               VE7LTD  used to transmit the data to the APRS-IS
#                       network. Now uses netcat (nc) to perform
#                       data transfers.
# V4.1 06Jan13  KL3NO   Made changes suggested by VE7GDH
#                       http://groups.yahoo.com/group/irlp-embedded/message/883
#-----------------------------------------------------------------------
# APRS Object Report Format
#    EL-xxxxxx
# +-+---------+-+-------+--------+-+---------+-+-------+------//-------+
# |;|IRLP-xxxx|*|DDHHMMz|  LAT   | |   LON   | |PHGphgd|COMMENT 36 Chrs|
# +-+---------+-+-------+--------+-+---------+-+-------+------//-------+
#  1 234567891 1 1111111 12222222 2 223333333 3 3344444 444455--7777778
#            0 1 2345678 90123456 7 890123456 7 8912345 678901--4567890
#
# CHARS   DESCRIPTION
# -----   --------------------------------------------------------------
#     1 - The APRS Data Type Identifier; ";" = Object Report
#  2-10 - Object Name; 9 characters, space padded on the right
#    11 - * = Live Object; _ = Killed Object
# 12-18 - Timestamp: DDHHMMz - DD=DOM; HH=Hours; MM=Minutes; z=Zulu
# 19-26 - Latitude: DDMM.MMH - DD=Degrees (00-90); MM=Minutes (00-59);
#                              .MM=Fractional Minutes (00-99);
#                              H=Hemisphere (N or S)
#    27 - Symbol Table ID (Alternate Symbol Table Overlay char)
# 28-36 - Longitude: DDDMM.MMH - DDD=Degrees (000-179);
#                                MM=Minutes (00-59);
#                                .MM=Fractional Minutes (00-99);
#                                H=Hemisphere (E or W)
#    37 - Symbol Code
# 38-45 - Power Height Gain 
# 46-80 - Comments: This is where the Node status goes
#-----------------------------------------------------------------------
# AVRS - Packet Format
#
# ;nnnnnnnnn*DDHHMMzDDMM.mmHxDDMM.mmHLPHGphgdFFFFFF+pppyyyyyyyyyyzzzzzzzz
#
# ;		The APRS Data Type Identifier; ";" = Object Report
# nnnnnnnnn	Object Name: IRLP-xxxx or EL-xxxxxx (node number)
# *		* = Live Object; _ = Killed Object
# DDHHMMz	Timestamp: DD=DOM; HH=Hours; MM-Minutes; z=Zulu
# DDMM.mmH	Latitude: DD=Degrees; MM=Minutes; mm=Decimal minutes
#			H=Hemisphere ([N]orth or [S]outh)
# x		Over Character: I=IRLP; E=EchoLink
#               Alternate Chars:  C=Connected; B=Busy; O=Offline
# DDDMM.mmH	Longitude: DDD=Degrees; MM=Minutes; mm=Decimal minutes
#			H=Hemisphere ([E]ast or [W]est)
# c		Symbol Code
# PHGphgd	"PHG" as shown indicating:
#		p = power
#		h = height
#		g = gain
#		d = direction
# FFFFFFoppp	Frequency in KHz, offset, PL freq in Hz (integer)
# yyyyyyyyyy	10 Status bytes  (visible on D7)
# zzzzzzzz	8 optional bytes (visible on D700)
# tttttttt      8 optional bytes (visible on APRS software)
#

# Make sure we are user repeater!!!
if [ `/usr/bin/whoami` != "repeater" ] ; then
  echo This program must be run as user REPEATER!
  exit 1
fi

# Make sure we have sourced the environment file
if [ "$RUN_ENV" != "TRUE" ] ; then
  . /home/irlp/custom/environment
fi

# Read in the node specific settings.
. $CUSTOM/irlp_aprs_status.conf

# Figure out which nc to use
if [ -f /bin/netcat ] ; then
   NC=/bin/netcat
else
   NC=$BIN/nc
fi

# Set the APRS symbol
SYMBOL=0
# Symbol Overlay characters
# Idle character
NODE_IDLE=I
# Connected character
NODE_CONN=C
# Node Offline Character
OFFLINE=O
# Node Busy Character
NODE_BUSY=B

#
# Make the APRS Object Name
#
# Determine our node ID STNxxxx
# If the length of the stantionid is 6 (old three digit), it adds a zero
if [ ${#STATIONID} = "6" ] ; then 
  CONVERTED_STATIONID="$STATIONID"0
else
  CONVERTED_STATIONID="$STATIONID"
fi
NODE_NUM=`echo $CONVERTED_STATIONID | cut -c 4-7`
OBJ_NAME="IRLP-${NODE_NUM}"		# MUST be 9 character long
#
# Format Message Fragments
#
if $VERBOSE ; then
  # If VERBOSE mode is selected, you will get "very" descriptive
  # status messages on the APRS programm running on a PC/MAC;
  # however, you will be totally screwing the guys using mobile
  # radios such as the D700 and D7 ht.
  CONNIRLP="CONNECTED TO IRLP "
  CONNECHO="CONNECTED TO ECHOLINK "
  FREQ_TXT=$FREQ"MHz"
  if [ "$OFFSET" = "SIMPLEX" ] || [ "$OFFSET" = "" ] ; then
    OFFSET_LBL=""
  else
    OFFSET_LBL=" ${OFFSET} offset"
  fi
  PL_LBL=" PL tone ${PL}"
else
  # If NOT VERBOSE mode, then the status messages will be greatly
  # reduced in length and will display completely on a D700 status
  # line and the D7 will only lose a small amount of data. This 
  # display will be usable by the greatest number of people though
  # may require a little thought to translate (just a tiny bit).
  CONNIRLP="C "					# Connected to IRLP
  CONNECHO="C EL"				# Connected to EchoLink
  USE_CALLSIGN=false				# Always use EL Node Number
  # FREQ_TXT=${FREQ%"."*[0-9]}${FREQ#[0-9]*"."}	# Convert MHz to KHz
  # Suggested change by VE7GDH.
  FREQ_TXT=${FREQ} # Don't Convert MHz to KHz
  if [ "$OFFSET" = "SIMPLEX" ] || [ "$OFFSET" = "" ] ; then
    OFFSET_LBL="s"				# Offset = "s"implex
  else
    OFFSET_LBL="${OFFSET}"			# Offest = +/-
  fi
  PL_LBL=${PL%"."[0-9]}				# Strip ".#" from PL
fi
# But if no PL tone is stated, Blank-Fill the field
if [ "$PL" = "" ]; then
  PL_LBL="   "
fi

#
# Make the APRS Object Timestamp
#
TIMESTAMP=`date -u +%d%H%M`z		# Format = DDHHMMz
#
# Assemble the Node Status
#
if [ ! -f $LOCAL/enable ] ; then
  NODE_STATUS=" OFFLINE"
  NODE_STATUS_CHAR=$OFFLINE
elif [ -f $LOCAL/active ] ; then	# $LOCAL/active = CONNected/BUSY
  if [ -s $LOCAL/active ] ; then	# Not Empty $LOCAL/active = CONNected
    if [ -s $LOCAL/echo_active ] ; then	# See if connected to EchoLink
      if $USE_CALLSIGN ; then
        NODE_STATUS="${CONNECHO}`cat $LOCAL/echo_call | tr [:lower:] [:upper:]`"
      else
        NODE_STATUS="${CONNECHO}`cat $LOCAL/echo_active`"
      fi
    else				# Must be an IRLP connection
#      NODE_STATUS="${CONNIRLP}`cat $LOCAL/active | cut -c 4-7`"
      NODE_STATUS="${CONNIRLP}`cat $LOCAL/active | tr [:lower:] [:upper:]`"
    fi
    NODE_STATUS_CHAR=$NODE_CONN
  else					# Empty $LOCAL/active = BUSY
    NODE_STATUS="BUSY"
    NODE_STATUS_CHAR=$NODE_BUSY
  fi
else 
  NODE_STATUS="IDLE"
  NODE_STATUS_CHAR=$NODE_IDLE
fi
NODE_STATUS=`echo "${NODE_STATUS}      " | cut -c 1-10`
#
# Assemble the COMMENT
#
# COMMENT="${FREQ_TXT}${OFFSET_LBL}${PL_LBL}${NODE_STATUS}"
# Suggested change by VE7GDH.
COMMENT="${FREQ_TXT}MHz T${PL_LBL} ${NODE_RANGE}  ${NODE_STATUS}"

#
# Assemble the APRS OBJECT
#
# NOTE: You can uncomment the next line, add in your values for the PHG
#       if you like. The Kenwood D7 and D700 get confused by these values.
#       You must also comment out the line after. ALSO, the PHGxxxx is
#       added to the object, you can no longer use:
#          http://www.findu.com/cgi-bin/find.cgi?call=IRLP-4494
#       but must use the sender callsign:
#          http://www/findu.com/cgi-bin/find.cgi?call=KC6HUR-13
#
#OBJECT=";${OBJ_NAME}*${TIMESTAMP}${LAT}${NODE_STATUS_CHAR}${LONG}${SYMBOL}PHG2130${COMMENT}"
# Suggested change by VE7GDH.
OBJECT=";${OBJ_NAME}*${TIMESTAMP}${LAT}${NODE_STATUS_CHAR}${LONG}${SYMBOL}${COMMENT}"
#
# Assemble the BTEXT line
#
BTEXT="$APRS_CALL>APVR30:${OBJECT}"
#
# Assemble the APRS-IS Login string
#
LOGIN="User $APRS_CALL pass $APRS_PASS vers IRLP-interface 1"
#
# Send the Beacon to the APRS-IS network
#
#  echo -e "${LOGIN}\n${BTEXT}" | $NC -w 10 rotate.aprs2.net 14580 &>/dev/null
# Suggested change by VE7GDH.
# echo -e "${LOGIN}\n${BTEXT}" | $NC -w 10 209.160.51.211 14580 &>/dev/null
echo -e "${LOGIN}\n${BTEXT}" | $NC -w 10 $APRS_SERVER $APRS_PORT &>/dev/null 

