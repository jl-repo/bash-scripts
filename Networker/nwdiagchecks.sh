#!/bin/bash
# Script to check Networker client status and connectivity to Networker and Data Domain from a Linux Client.
# By Jared Leslie
# Colour  Variables
RED='\e[0;91m'
BLUE='\e[0;94m'
GREEN='\e[0;92m'
CLEAR='\e[0m'
# List all Networker servers to be tested in the array between quotes "server.example.com". This can include Networker Storage Nodes if required.
declare -a NetworkerServers=(
    "burvrhel038.backup.cba"
    "norvrhel038.backup.cba"
	"burvrhel040.backup.cba"
    "norvrhel040.backup.cba"
	"burvrhel041.backup.cba"
    "norvrhel041.backup.cba"
	"burvrhel042.backup.cba"
    "norvrhel042.backup.cba"
	"burvrhel043.backup.cba"
    "norvrhel043.backup.cba"
    )
# List all Data Domain appliances to be tested in the array between quotes "datadomain.example.com".
declare -a DataDomain=(
    "emcndd10.backup.cba"
    "emcbdd10.backup.cba"
    "emcndd11.backup.cba"
    "emcbdd11.backup.cba"
    "emcndd13.backup.cba"
    "emcbdd13.backup.cba"
)
echo -e "$BLUE""Networker Client Diagnostic Tests""$CLEAR"
echo ""
# If Distribution is not Linux halt script.
DISTRO=$(uname -s | grep Linux)
if [ -z "$DISTRO" ]; then
    echo -e "$RED""This script needs to run on Linux to continue.""$CLEAR"
    exit 1
fi
# Sudo check on current user.
if sudo -l | grep "nsr\|networker\|ALL" > /dev/null; then
    echo -e "$GREEN""Found Sudo rules for Networker.""$CLEAR"
    echo ""
    sudo -l
    echo ""
    else
    echo -e "$RED""Sudo rules for Networker might be missing.""$CLEAR"
    echo ""
    sudo -l
    echo ""
fi
# Networker Service Checks.
echo -e "$BLUE""Checking Networker Client Status""$CLEAR"
echo ""
if [ ! -x /usr/sbin/nsrexecd ]; then
    echo -e "$RED""Networker Client is not installed.""$CLEAR" 
    echo ""
else
    STATUS="$(ps -eaf | grep -i /usr/sbin/nsrexecd | sed '/^$/d' | wc -l)"
    case $STATUS in
        # Case if the Networker service is not running.
        0) 
			echo -e "$RED""The Networker Service is 'not running'. Starting the service.""$CLEAR"
			sudo /usr/bin/systemctl start networker
			echo ""
			sudo /usr/bin/systemctl status networker
			echo ""
        ;;
        # Case if the Networker service has failed.
        1) 
			echo -e "$RED""The Networker Service has 'failed'. Restarting the Service.""$CLEAR"
			sudo /usr/bin/systemctl restart networker
			echo ""
			sudo /usr/bin/systemctl status networker
			echo ""
			;;
        # Case if Networker service is running normally.
        2) 
			echo -e "$GREEN""The Networker Service is 'running'.""$CLEAR"
			sudo /usr/bin/systemctl status networker
			echo ""
			;;
    esac
    # Print version of agent via rpm.
    echo -e "$GREEN""Networker Client Version""$CLEAR"
    echo ""
    /usr/bin/rpm -qa | grep 'lgtoclnt\|lgtoxtdclnt'
	echo ""
    # Print the servers file.

    # Print the ports used.
    echo -e "$GREEN""Networker Client Ports.""$CLEAR"
    echo ""
    /usr/bin/nsrports
    echo ""
    # Render the daemon log and show the last 20 lines.
    echo -e "$GREEN""Daemon Log Render (20 Lines).""$CLEAR"
    echo ""
    /usr/sbin/nsr_render_log /nsr/logs/daemon.raw | tail -20
    echo ""
fi
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
    /usr/bin/ping -c 3 "$server" &> /dev/null && echo -e "$GREEN""Ping Success.""$CLEAR" || echo -e "$RED""Ping Fail.""$CLEAR"
    echo ""
    #Telnet Test.
    TELNET="$(echo "quit" | /usr/bin/curl -v --connect-timeout 15 telnet://"$server":7937 &> /dev/null && echo yes)"
    if [ -z "$TELNET" ]; then
        echo -e "$RED""Telnet Fail on port 7937.""$CLEAR"
        echo ""
        else
        echo -e "$GREEN""Telnet Success on port 7937.""$CLEAR"
        echo ""
        if [ ! -x /usr/sbin/nsrrpcinfo ]; then
            echo -e "$RED""Networker Extended Client is not installed.""$CLEAR" 
            echo ""
            else
            echo -e "$GREEN""/usr/sbin/nsrrpcinfo -p $server""$CLEAR"
            /usr/sbin/nsrrpcinfo -p "$server"
            echo ""
        fi
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
    /usr/bin/ping -c 3 "$dd" &> /dev/null && echo -e "$GREEN""Ping Success.""$CLEAR" || echo -e "$RED""Ping Fail.""$CLEAR"
    echo ""
    # Telnet Test via curl.
    echo "quit" | /usr/bin/curl -v --connect-timeout 15 telnet://"$dd":2049 &> /dev/null && echo -e "$GREEN""Telnet Success on port 2049.""$CLEAR" || echo -e "$RED""Telnet Fail on port 2049.""$CLEAR"
    echo ""
    echo "quit" | /usr/bin/curl -v --connect-timeout 15 telnet://"$dd":2052 &> /dev/null && echo -e "$GREEN""Telnet Success on port 2052.""$CLEAR" || echo -e "$RED""Telnet Fail on port 2052.""$CLEAR"
    echo ""
    echo "quit" | /usr/bin/curl -v --connect-timeout 15 telnet://"$dd":111 &> /dev/null && echo -e "$GREEN""Telnet Success on port 111.""$CLEAR" || echo -e "$RED""Telnet Fail on port 111.""$CLEAR"
    echo ""
done
# Press any keep to exit the script.
echo "Press any key to exit."
while true ; do
    if read -rn 1; then exit; else :; fi
done