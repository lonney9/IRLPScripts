# irlp_aprs_status  IRLP node status reporting via APRS
#
# v1.0 26APR03  VK2XJG  Original Release
# v1.1 15MAY03  ZL1AMW  Added node callsign to extra text area of beacon
# v2.0 12JUN05  ZL1AMW  major re-write to change to TCP connections to 
#                       APRSSD server, plus allow user config of more values
#		        TNC and TTY support has been removed
# v2.1 14JUN05  ZL1AMW  update from sugestions received D7 mode support,
#                       improve README
# v2.2 25JUN05  ZL1AMW  further update of README and notes in .conf file
#                       bugfix for simplex frequencies
# v2.3 26JUN05  ZL1AMW  improved enviro variable loading
# v2.4 01JUL05  ZL1AMW  fix bug with 1 digit day of month
# v2.5 05JUL05  ZL1AMW  allow 3 digit node numbers
# v2.6 11SEP05  KC6HUR  Added EchoLink compatability
#                            - Added Node BUSY status
#                            - Cleaned up code
# v3.0 09APR06  KC6HUR  irlp_aprs_status_tx.pl completely rewritten to
#               KF7FLY  rewritten to prevent nodes command processor
#                       from hanging due to a stuck APRS-IS server.
#                       Also, now uses all available APRS2 servers to
#                       pass traffic automatically not just one.
# v4.0 10APR07  KC6HUR  Did away with the irlp_aprs_status_tx.pl program
#               KF7FLY  and modified irlp_aprs_status to use netcat (nc)
#                       to transfer the IRLP status information to
#                       the APRS-IS network.
#

QUICK SETUP (KL3NO)
===================

Cron:

I have this in my /home/irlp/custom/custom.crons

36 * * * * (/home/irlp/custom/irlp_aprs_status >/dev/null 2>&1)

Keeps the APRS object “fresh” once per hour on the 36th minute.

And in /home/irlp/custom/custom_on and /home/irlp/custom/custom_off, I have

${CUSTOM}/irlp_aprs_status &

This updates the status upon connect and disconnect.


OVERVIEW
========
This script intends to combine IRLP and APRS together, in the IPRS or 
AVRS concept of APRS Author Bob Bruninga WB4APR. 

See also http://web.usna.navy.mil/~bruninga/avrs.html

This script will transmit the current status of the node to the worldwide
APRS-IS network.

This version 4.0 set of scripts was developed by KC6HUR and VE7LTD, from
3.0 set of scripts developed by KC6HUR and KF7FLY, from 2.x scripts 
developed by ZL1AMW, which was based on version 1.x script by VK2XJG.

Note there is a significant change from ver 1 of this script.  The 
previous version sent station beacons with the callsign STNxxxx, 
sunsequent versions send the status as an APRS object, with the node call
as the originator's callsign.  The change means the data sent is from a 
valid amateur callsign, so will pass through IGATES. Version 3 of this 
script enhances the Internet operability by using timeouts on all
transactions, and will try connecting to all APRS-IS servers until one
that works is found. The entire irlp_aprs_status_tx.pl script was rewritten 
to be more robust in it's handling of input parameters as well. Ver 4.0
completely does away with the irlp_aprs_status_tx.pl script which is replaced
with the netcat (nc) program, thus doing away with the need to have PERL
loaded on the node making use of irlp_aprs_status usable on the new embedded
IRLP nodes.

Version greater than 1 no longer support a local TNC or radio. All 
communication is done via the Internet.

NOTES ON IRLP-APRS INTERFACE
============================

APRS is an excellent medium for local operators to be made aware of 
your node name, frequency and current status.

The IRLP node operator does not have to have any APRS equipment, or 
any knowledge of the APRS network, the script just sends data to the 
APRS-IS system in the same manner that all other APRS stations do.

For the object to appear on APRS RF, it then needs to transit through 
an IGATE somewhere, any IGATE set up to gateway APRS traffic from the
area and/or callsign district of the IRLP node will send the object to
RF, unless they have specifically decided to filter individual callsigns
(which is unusual). Actually, in most places it is necessary for you to
arrange with a local IGATE operator to have your packets forwarded to
RF in your local area.

The 3.x version of the irlp_aprs_status program no longer requires that you
enter any information regarding which APRS server or connecting port
before it can be used. These are already defaulted to use the rotating
DNS lookup (which provides different address each time a request is
made, spreading the load across servers). You may enter an APRS server 
name, and a valid connecting port for that server; HOWEVER, it is
recommended that you run with the defaults. It is unimportant which 
APRS server the data is sent too, they are all inter-connected through 
the APRS-IS network. You can view a list of servers and their available 
ports at serverlist.aprswest.com

For a quick map view of all the nodes running this or similar APRS 
scripts, have a look at:

http://www.findu.com/cgi-bin/find.cgi?irlp*

On an APRS program running at home, the IRLP nodes show up as an icon 
amongst other stations, with the frequency and current state (connected, 
idle, etc) displayed in the station status display.


OPERATION
=========
The irlp_aprs_status script is called periodically (60 minutes) from 
custom.crons, and sends an APRS format beacon to the APRS-IS network.
To make this script effective in real time mode, it is also called from 
both custom_on and custom_off, so that it captures change of status of 
the node in real time.

Whenever the node is idle (IDLE), the APRS beacon indicates this.

If the node is being used for local activity, such as playing 
Newsline or some other purpose (and the $LOCAL/active file is set but
it's contents are empty) the beacon will show (BUSY).

If the node is connected to another IRLP node or reflector, this is 
indicated in the beacon, as well as the ID of the connected station 
(C STNxxxx) or (C REFxxxx). If the node is connected
to an EchoLink node, the beacon will show: (C ELxxxxxx) or 
(C callsign) depending on your configuration.

If the node is disabled, the APRS beacon will show (OFFLINE).

Each status is represented by a different overlay 
letter on the APRS symbol, and text in the beacon comment.


INSTALLATION
============
1. Login is as root.

2. Get the tar file:

   wget http://irlp.kc6hur.net/downloads/irlp_aprs_status-4.0.tgz

3. Install the files found in the tar file:

   cd /
   tar -xzvf /root/irlp_aprs_status-4.0.tgz

   This will un-zip the files and place them in the appropriate 
   directories.

4. Edit both custom_on and custom_off files to include the 
   the following line:

   ${CUSTOM}/irlp_aprs_status &

   You also need to ensure that CUSTOM_ON=YES and CUSTOM_OFF=YES 
   in your $CUSTOM/environment file. Without these, there will be 
   no beacon as your node changes status!

5. Next configure the irlp_aprs_status.conf file as described below.


SETTING UP YOUR APRS BEACON
===========================
You must edit the contents of the file irlp_aprs_status.conf

Each entry has comments within the irlp_aprs_status.conf file describing 
what is required.

Take special note of:

- your longitude must be three digits of degrees, followed by 2 digits 
  of minutes, then two digits of decimal minutes then E or W (DDDMM.mm), 
  eg: for 88 degrees, 8.56 minutes, enter 08808.56W.

- your latitude must be two digits of degrees, 2 digits of minutes then 
  two digits of decimal minutes then N or S (DDMM.mm), e.g. 34 degrees,
  19.32 minutes North, enter: 3419.32N.


APRS VALIDATION NUMBER
======================

You must have an APRS validation number in order to connect to the APRS
Internet servers. The aprspass program has been included in this distro
so that you can generate your own APRS validation number.

To generate your validation number, do the following:

1. login as repeater

2. generate the validation code with the following command:

   ${CUSTOM}/aprspass <your callsign>

   Example usage:

   [repeater@node4494 ~]$ ${CUSTOM}/aprspass kc6hur
   APRS passcode for kc6hur = 23483

   Do not include your SSID, it is not needed.

3. When editing the irlp_aprs_status.conf, the 5-digit code obtained in the
   step above is added to the "export APRS_PASS=" line:

   e.g. export APRS_PASS=23483

   replacing the 23483 in the example above with your 5-digit code.


D7 MODE
=======
PLEASE NOTE:
   The argument for VERBOSE (true or false) MUST BE IN LOWER CASE!!!

export VERBOSE=false

   The default format of the beacon is terse (D7 mode), describing Node 
   access parameters:

   146950-103 IDLE

   The frequency is in KHZ, the offset is +/-/s and only the integer value
   of the PL frequency is used. This format displays quite well on radios
   like the Kenwood D7 and D700, the HamHUD and other systems.

export VERBOSE=true

   An alternative verbose format, that is more suitable for display 
   programs like UI-view, and other PC based programs:

   146.950MHz, - offset PL tone 103.5: IDLE

   This format is virtually unsable by most mobile user because it is too
   long and the information cannot be seen. So why use it?

The "VERBOSE=false" mode is the default mode because it is most usable
by mobile users, the intended user of this beacon service. I'm sorry, I 
don't see APRS as system designed for home use; hence, I decided to make
the status report useful to the mobile user, not the armchair user.


SETTING UP THE CUSTOM CRON
==========================
To update your custom cron to schedule running irlp_aprs_status script 
regularly, run the update in the /tmp file with the command:

sh /tmp/post_install_aprs.sh 

This will write the new entries in your custom_crons you then must 
enter:

update files 

to read the custom crons into the system.

