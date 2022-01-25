#!/bin/bash

##
# Colour  Variables
##
RED='\e[0;91m'
BLUE='\e[0;94m'
GREEN='\e[0;92m'
CLEAR='\e[0m'

##
# Colour Functions
##

ColourGreen(){
	echo -ne $GREEN$1$CLEAR
}

ColourRed(){
	echo -ne $RED$1$CLEAR
}

ColourBlue(){
	echo -ne $BLUE$1$CLEAR
}


# Redirect all stdout and stderr to syscheck.log
#exec > syscheck.log 2>&1

##
# Script Functions
##

#Check System Information
function system_information(){
	echo -e $(ColourRed 'System Information:')
	echo ""
	/usr/bin/uname -a
	echo "" 
}

#Display Uptime
function system_uptime(){
	echo -e $(ColourRed 'System Uptime:')
	echo ""
	/usr/bin/uptime
	echo ""
}

#CPU Check using top
function cpu_check(){
	echo -e $(ColourRed 'CPU Usage:')
	echo ""
	/usr/bin/top - i -b -n 1
	echo ""
}

#Check Memory
function memory_check(){
	echo -e $(ColourRed 'Memory Usage:')
	echo ""
	/usr/bin/free -h
	echo ""
}

#Check Disk Space
function disk_space(){
	echo -e $(ColourRed 'Disk Space:')
	echo ""
	/usr/bin/df -h
	echo ""
}

#Display Network Information
function network_information(){
	echo -e $(ColourRed 'Network Information:')
	echo ""
	/usr/sbin/ifconfig -a
	echo ""
}

#Display Journal Logs with Error (3) or higher since last boot
function journal_errors(){
	echo -e $(ColourRed 'Journal Errors since last boot:')
	echo ""
	/usr/bin/journalctl -p 3 -b --no-pager
	echo ""
}

function all_checks(){
	system_information
	system_uptime
	cpu_check
	memory_check
	disk_space
	network_information
	journal_errors
}


##
# Menu
##

menu(){
echo -ne "
$(ColourRed 'SysCheck Menu')
$(ColourGreen '1)') System Information
$(ColourGreen '2)') System Uptime
$(ColourGreen '3)') CPU Check
$(ColourGreen '4)') Memory Check
$(ColourGreen '5)') Disk Check
$(ColourGreen '6)') Network Information
$(ColourGreen '7)') Journal Log Errors
$(ColourGreen '8)') Run All Checks
$(ColourGreen '0)') Exit
$(ColourBlue 'Choose an option:') "
	read a
	case $a in
		1) system_information ; menu ;;
		2) system_uptime ; menu ;;
		3) cpu_check ; menu ;;
		4) memory_check ; menu ;;
		5) disk_space ; menu ;;
		6) network_information ; menu ;;
		7) journal_errors ; menu ;;
		8) all_checks ; menu ;;
		0) exit 0 ;;
		*) echo -e $RED"Wrong Option Selected."$CLEAR; WrongCommand;;
	esac
}

# Call the menu function
menu 




			
