#!/bin/bash
# Transmission Bittorrent Client road warrior installer for Debian and Ubuntu 

# This script will work on Debian, Ubuntu and probably other distros
# of the same families, although no support is offered for them. It isn't
# bulletproof but it will probably work if you simply want to setup tranmission on
# your Debian/Ubuntu box. It has been designed to be as unobtrusive and
# universal as possible.


if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit 1
fi

if [[ ! -e /etc/debian_version ]]; then
	echo "Sorry, you need to run this in Debian/Ubuntu"
	exit 1
fi

if [[ -e /etc/transmission-daemon/settings.json ]]; then
	echo "Looks like Transmission is already installed"
	exit 1
fi

IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
if [[ "$IP" = "" ]]; then
		IP=$(wget -qO- ipv4.icanhazip.com)
fi

clear
echo 'Welcome to this quick Transmission Bittorent Client installer'
echo ""

echo "I need to ask you a few questions before starting the setup"
echo "You can leave the default options and just press enter if you are ok with them"
echo ""

DOWNLOAD_COMPLETED="/var/downloads/completed"
DOWNLOAD_INCOMPLETE="/var/downloads/incomplete"

echo "First I need to know the completed download location of Transmission"
read -p "Completed Download Location: " -e -r -i $DOWNLOAD_COMPLETED DOWNLOAD_COMPLETED
echo ""
echo "What is the incomplete download location of Transmission"
read -p "Incomplete Download Location: " -e -r -i $DOWNLOAD_INCOMPLETE DOWNLOAD_INCOMPLETE
echo ""

echo "What port do you want for Transmission Web Interface?"
read -p "Port: " -e -r -i 9091 PORT
echo ""

echo "Transmission Web Interface Username"
read -p "Username: " -r USERNAME

echo "Transmission Web Interface Password"
while true
do
    read -s -p "Password: " password
    echo
    read -s -p "Password (again): " password2
    echo
    [ "$password" = "$password2" ] && break
    echo "Password mismatch! Please try again"
done
PASSWORD=$password2

echo ""
echo "Okay, that was all I needed. We are ready to setup your Transmission Bittorent Client now"
read -n1 -r -p "Press any key to continue..."

apt-get update
apt-get install transmission-daemon transmission-cli -y
service transmission-daemon stop

sleep 3
mkdir -p "$DOWNLOAD_COMPLETED"
mkdir -p "$DOWNLOAD_INCOMPLETE"
sleep 3
chown -R debian-transmission:debian-transmission "$DOWNLOAD_INCOMPLETE"
chown -R debian-transmission:debian-transmission "$DOWNLOAD_COMPLETED"

sleep 3

sed -i 's/^.*incomplete-dir-enabled.*/"incomplete-dir-enabled": true,/' /etc/transmission-daemon/settings.json
sed -i 's@^.*incomplete-dir\".*@"incomplete-dir": "'"$DOWNLOAD_INCOMPLETE"'",@' /etc/transmission-daemon/settings.json
sed -i 's@^.*download-dir.*@"download-dir": "'"$DOWNLOAD_COMPLETED"'",@' /etc/transmission-daemon/settings.json
sed -i 's@^.*rpc-port.*@"rpc-port": '"$PORT"',@' /etc/transmission-daemon/settings.json
sed -i 's/^.*rpc-whitelist-enabled.*/"rpc-whitelist-enabled": false,/' /etc/transmission-daemon/settings.json
sed -i 's/^.*rpc-authentication-required.*/"rpc-authentication-required": true,/' /etc/transmission-daemon/settings.json
sed -i 's@^.*rpc-username.*@"rpc-username": "'"$USERNAME"'",@' /etc/transmission-daemon/settings.json
sed -i 's@^.*rpc-password.*@"rpc-password": "'"$PASSWORD"'",@' /etc/transmission-daemon/settings.json

service transmission-daemon start
sleep 3

echo ""
echo "Finished!"
echo ""
echo "Go to: http://$IP:$PORT"