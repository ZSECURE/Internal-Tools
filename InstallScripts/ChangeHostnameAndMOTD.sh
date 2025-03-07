#!/bin/bash

if [ ! -n "$1" ] ; then
	echo 'Missing argument: new_hostname'
	exit 1
fi

if [ "$(id -u)" != "0" ] ; then
	echo "Script needs to be run as root."
	exit 2
fi

CUR_HOSTNAME=$(cat /etc/hostname)
NEW_HOSTNAME=$1

# Display the current hostname
echo "The current hostname is $CUR_HOSTNAME"

# Change the hostname
sudo hostnamectl set-hostname $NEW_HOSTNAME
hostname $NEW_HOSTNAME

# Change hostname in /etc/hosts & /etc/hostname
sudo sed -i "s/$CUR_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts
sudo sed -i "s/$CUR_HOSTNAME/$NEW_HOSTNAME/g" /etc/hostname

# Display new hostname
echo "The new hostname is $NEW_HOSTNAME"


# Update the message of the day (MOTD)
MOTD_MESSAGE="Welcome to your server. Hostname: $NEW_HOSTNAME"
echo "$MOTD_MESSAGE" | sudo tee /etc/motd
