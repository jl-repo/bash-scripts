#!/bin/bash

# Script to install and configure Cockpit on RHEL 7.9. Created by Jared Leslie.

# Variables

FIREWALL="$(systemctl is-active firewalld.service)"
SELINUX="$(getenforce)"
IPADDRESS="$(hostname --ip-address)"
HOSTNAME="$(hostname)"

# Check if the script is run as root or sudo.

if [ "$(whoami &2> /dev/null)" != "root" ] && [ "$(id -un &2> /dev/null)" != "root" ]; then
      echo "You must be root to run this script! Switch to root or use sudo."
      exit 1
fi

# User defines the port for Cockpit to use.

echo "Please provide a port number for Cockpit to use (default is 9090)."

read -rp 'Port: ' PORT

# Validate if the PORT Value is a number.

if [ -z "${PORT##*[!0-9]*}" ]; then   
    echo "Sorry integers only. Please run the script again and provide a valid port number."
    exit 1
fi

# Validate if the PORT value is not empty and display PORT value.

if [ -z "$PORT" ]; then
	echo "The port value is empty. Please run the script again and provide a valid port number."
	exit 1
else 
	echo "You have selected $PORT for Cockpit to use."
fi

# User confirms the PORT value.

echo "Is the port correct?"
read -rp 'Yes/No: ' ANSWER
if [ "${ANSWER,,}" = "yes" ]; then
    echo "Thanks for confirming. Continuing Setup....."
else 
    echo "Terminating setup"
	exit 1
fi

# Install Cockpit with Storage Add-on.

echo " Installing Cockpit... "
yum -y install cockpit cockpit-dashboard cockpit-storaged

# Configure Port in Cockpit.Socket.

echo "Changing Cockpit port to $PORT..."
cp /usr/lib/systemd/system/cockpit.socket /usr/lib/systemd/system/cockpit.backup
sed -i "s/ListenStream=9090/ListenStream=$PORT/" /usr/lib/systemd/system/cockpit.socket

# Start and enable Cockpit Service.

echo "Starting Cockpit... "
systemctl start cockpit && systemctl enable --now cockpit.socket

# Check for Firewall.d and add rule if Firewall.d is running.

if [ "${FIREWALL}" = "active" ]; then
    echo "Adding firewall rule to FirewallD for port $PORT and reloading....."
	firewall-cmd --permanent --add-port="$PORT"/tcp && firewall-cmd --reload
else 
    echo "Firewall.d is not running... continuing..."  
fi

# Check SELinux is enforced and add rule.

if [ "${SELINUX}" = "Enforced" ]; then
    echo "Adding SELinux rule for Cockpit ..."
	semanage port -a -t websm_port_t -p tcp "$PORT"
else 
    echo "SELinux is not running... continuing..."  
fi

# Echo out completion and how to access.

echo "Cockpit is now installed and configured... You can now access via https://$IPADDRESS:$PORT or https://$HOSTNAME:$PORT."

# Press any keep to exit the script.
echo "Press any key to exit."
while true ; do
    if read -rn 1; then exit; else :; fi
done