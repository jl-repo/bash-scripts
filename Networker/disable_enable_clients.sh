#!/bin/bash
# Script to enable or disable Networker clients via nsradmin via.
# By Jared Leslie

# Colour variables.
RED='\e[0;91m'
BLUE='\e[0;94m'
GREEN='\e[0;92m'
CLEAR='\e[0m'
# Date variable for files.
date=$(/usr/bin/date +"%m_%d_%Y")
# Check and remove any leftover files from cancelled runs. Silent.
/usr/bin/rm nsradmin_input_"$date".txt nsradmin_output_"$date".txt client_clean_"$date".txt client_input_"$date".txt 2> /dev/null
# Get client information from standard input.
echo -e "$BLUE""Enter the list of clients you would like to modify. <CTRL> <D> to finalize the list.""$CLEAR"
input_data=$(</dev/stdin)
/usr/bin/printf "%s\n" "${input_data[@]}" &> client_input_"$date".txt
echo ""
# Check if the client file exists.
input_file=client_input_"$date".txt
if test -f "$input_file"; then
    /usr/bin/echo ""
    /usr/bin/echo -e "$GREEN""$input_file exits.""$CLEAR"
    /usr/bin/echo ""
else
    /usr/bin/echo -e "$RED""File doesnt exist. Please make sure that $input_file is generated in the same directory as this script.""$CLEAR"
    exit 1
fi
# Edit initial input file to remove any blank lines. This is to prevent a sitiation where clients are mass edited that are not listed in the file.
/usr/bin/sed '/^$/d' client_input_"$date".txt > client_clean_"$date".txt
# Generate arry from client_clean file.
mapfile -t servers < client_clean_"$date".txt
# Print the array of clients.
/usr/bin/echo -e "$BLUE""List of clients:""$CLEAR"
/usr/bin/echo ""
/usr/bin/printf "%s\n" "${servers[@]}"
/usr/bin/echo ""
# Enabled or disabled if statement. Convert to case statement later?
/usr/bin/echo -e "$BLUE""Type the action to perform: 'enabled' or 'disabled':""$CLEAR"
/usr/bin/echo ""
read -r choice
status="$(echo "$choice" | awk '{print tolower($0)}')"
if [ "${status,,}" = "enabled" ] || [ "${status,,}" = "disabled" ]; then
	/usr/bin/echo -e "$BLUE""You have chosen to set the client status as ""$status"".""$CLEAR"
    /usr/bin/echo ""
else
	/usr/bin/echo -e "Invalid status. Please try again."
	exit 1
fi
# Count to make sure the clists is greater than zero.
count="$(echo "${#servers[@]}")"
if [ "$count" -lt 1 ]; then
	/usr/bin/echo -e "$RED""No clients input to disable/enable. Check $input_file. Exiting script.""$CLEAR"
	exit 1
fi
/usr/bin/echo ""
/usr/bin/echo -e "Number of clients is: $count clients."
/usr/bin/echo ""
# Create the input file for nsradmin.
for server in "${servers[@]}"; do
	/usr/bin/echo -e ". type: nsr client; name: $server \nupdate scheduled backup: $status" |tee -a nsradmin_input_"$date".txt > /dev/null
done
/usr/bin/echo -e "quit" |tee -a nsradmin_input_"$date".txt > /dev/null
# Echo out nsradmin input file.
/usr/bin/echo -e "$BLUE""nsradmin input:""$CLEAR"
echo ""
cat nsradmin_input_"$date".txt
/usr/bin/echo ""
# Confirmation case for the user to continue or exit out.
while true
do
    read -r -p 'Do you want to continue? Yes/No ' continue
    case "$continue" in
      n|N|no|No) exit 1 && /usr/bin/rm nsradmin_input_"$date".txt nsradmin_output_"$date".txt client_clean_"$date".txt client_input_"$date".txt 2> /dev/null;;
      y|Y|yes|Yes) break;;
      *) /usr/bin/echo -e "$RED""Response not valid""$CLEAR";;
    esac
done
/usr/bin/echo ""
# nsradmin with input from nsradmin_input file.
/usr/sbin/nsradmin -i nsradmin_input_"$date".txt > nsradmin_output_"$date".txt
# Output from nsradmin.
/usr/bin/echo -e "nsradmin output:"
cat nsradmin_output_"$date".txt
/usr/bin/echo ""
# Cleanup files and the end.
echo -e "$BLUE""Cleaning up temporary files""$CLEAR"
/usr/bin/rm nsradmin_input_"$date".txt nsradmin_output_"$date".txt client_clean_"$date".txt client_input_"$date".txt
echo ""
# Press any keep to exit the script.
echo "Press any key to exit."
while true ; do
    if read -rn 1; then exit; else :; fi
done