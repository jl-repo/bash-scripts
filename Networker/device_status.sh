#!/bin/bash
# By Jared Leslie

# Colour variables.
RED='\e[0;91m'
BLUE='\e[0;94m'
GREEN='\e[0;92m'
CLEAR='\e[0m'
# Date variable for files.
date=$(/usr/bin/date +"%m_%d_%Y")

declare -a NetworkerServers=(
    "networker1.example.com"
    "networker2.example.com"
)

# Input data domain shortname
/usr/bin/echo -e "$BLUE""Type the Data Domain short name (Example: emcndd11):""$CLEAR"
/usr/bin/echo ""
read -r choice
DD="$(echo "$choice" | awk '{print tolower($0)}')"
if [[ "${DD,,}" = emcbdd[0-9][0-9] ]] || [[ "${DD,,}" = emcndd[0-9][0-9] ]]; then
    /usr/bin/echo ""
    /usr/bin/echo -e "$BLUE""You have chosen ""$DD"".""$CLEAR"
    /usr/bin/echo ""
else
    /usr/bin/echo -e "Invalid status. Please try again."
    exit 1
fi

# Enabled or disabled if statement. Convert to case statement later?
/usr/bin/echo -e "$BLUE""Type the action to perform: 'enabled', 'service' or 'disabled':""$CLEAR"
/usr/bin/echo ""
read -r choice
status="$(echo "$choice" | awk '{print tolower($0)}')"
if [ "${status,,}" = "enabled" ] || [ "${status,,}" = "disabled" ] || [ "${status,,}" = "service" ]; then
    /usr/bin/echo ""
    /usr/bin/echo -e "$BLUE""You have chosen to set the device status as ""$status"".""$CLEAR"
    /usr/bin/echo ""
else
    /usr/bin/echo -e "Invalid status. Please try again."
    exit 1
fi
# SSH to each Networker server and create the NSR file << broken
for server in "${NetworkerServers[@]}"; do
    ssh -q -f "$server" 'echo -e option regexp\n. type: NSR device;device access information: ^.*$DD.*$ \nupdate enabled: $status\nexit > /tmp/device_modify_tmp | cat /tmp/device_modify_tmp'
done