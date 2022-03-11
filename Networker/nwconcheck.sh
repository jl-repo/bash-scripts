#!/bin/bash
# Script to check connectivity to Networker and Data Domain from a Linux Client.
# By Jared Leslie
# Colour  Variables
RED='\e[0;91m'
BLUE='\e[0;94m'
GREEN='\e[0;92m'
CLEAR='\e[0m'
# List all Networker servers to be tested in the array between quotes "server.example.com". This can include Networker Storage Nodes if required.
declare -a NetworkerServers=(
    "networker1.example.com"
    "networker2.example.com"
)
# List all Data Domain appliances to be tested in the array between quotes "datadomain.example.com".
declare -a DataDomain=(
    "datadomain1.example.com"
    "datadomain2.example.com"
    "datadomain3.example.com"
)
# Tests to run from the client to the Networker servers.
for server in "${NetworkerServers[@]}"; do
    echo -e "$BLUE""Testing connectivity to $server""$CLEAR"
    echo ""
    # DNS Name Resoultion Test.
    NWIP=$(/usr/bin/dig +short "$server" | head -1)
    if [ -z "$NWIP" ]; then
        echo -e "$RED""DNS Lookup has failed.""$CLEAR"
    else
        echo -e "$GREEN""DNS Lookup was successful for $server with $NWIP.""$CLEAR"
    fi
    echo ""
    # Ping Test.
    /usr/bin/ping -c 3 "$server" &>/dev/null && echo -e "$GREEN""Ping Success.""$CLEAR" || echo -e "$RED""Ping Fail.""$CLEAR"
    echo ""
    # Telnet Test.
    echo "quit" | /usr/bin/curl -v telnet://"$server":7937 &>/dev/null && echo -e "$GREEN""Telnet Success on port 7937.""$CLEAR" || echo -e "$RED""Telnet Fail on port 7937.""$CLEAR"
    echo ""
    # Networker inbuilt nsrrpcinfo cmdlet test if extended client is installed.
    if [ ! -x /usr/sbin/nsrrpcinfo ]; then
        echo -e "$RED""Networker Extended Client is not installed.""$CLEAR"
        echo ""
    else
        echo -e "$GREEN""sudo /usr/sbin/nsrrpcinfo -p $server""$CLEAR"
        /usr/sbin/nsrrpcinfo -p "$server"
        echo ""
    fi
done
# Tests to run from the client to the Data Domain appliances.
for dd in "${DataDomain[@]}"; do
    echo -e "$BLUE""Testing connectivity to $dd""$CLEAR"
    echo ""
    # DNS Name Resoultion Test.
    DDIP=$(/usr/bin/dig +short "$dd" | head -1)
    if [ -z "$DDIP" ]; then
        echo -e "$RED""DNS Lookup has failed.""$CLEAR"
    else
        echo -e "$GREEN""DNS Lookup was successful for $dd with $DDIP.""$CLEAR"
    fi
    echo ""
    # Ping Test
    /usr/bin/ping -c 3 "$dd" &>/dev/null && echo -e "$GREEN""Ping Success.""$CLEAR" || echo -e "$RED""Ping Fail.""$CLEAR"
    echo ""
    # Telnet Test via curl.
    # DD often connects via CURL but exits with error code 56. Added 56 as a successful exit.
    echo "quit" | /usr/bin/curl -v --connect-timeout 15 telnet://"$dd":2049 &>/dev/null
    CODE=$?
    if [ $CODE != "0" ] && [ $CODE != "56" ]; then 
        echo -e "$RED""Telnet Fail on port 2049.""$CLEAR"
        echo ""
    else
        echo -e "$GREEN""Telnet Success on port 2049.""$CLEAR"
        echo ""
    fi
    # DD often connects via CURL but exits with error code 56. Added 56 as a successful exit.
	echo "quit" | /usr/bin/curl -v --connect-timeout 15 telnet://"$dd":2052 &>/dev/null
    CODE=$?
    if [ $CODE != "0" ] && [ $CODE != "56" ]; then
        echo -e "$RED""Telnet Fail on port 2052.""$CLEAR"
        echo ""
    else
        echo -e "$GREEN""Telnet Success on port 2052.""$CLEAR"
        echo ""
    fi
    # DD often connects via CURL but exits with error code 56. Added 56 as a successful exit.
    echo "quit" | /usr/bin/curl -v --connect-timeout 15 telnet://"$dd":111 &>/dev/null
    CODE=$?
    if [ $CODE != "0" ] && [ $CODE != "56" ]; then
        echo -e "$RED""Telnet Fail on port 111.""$CLEAR"
        echo ""
    else
        echo -e "$GREEN""Telnet Success on port 111.""$CLEAR"
        echo ""
    fi
done
# Press any keep to exit the script.
echo "Press any key to exit."
while true; do
    if read -rn 1; then exit; else :; fi
done
