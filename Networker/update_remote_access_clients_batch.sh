#!/bin/bash
# Script to update remote access for Cluster Object clients via nsradmin.
# By Jared Leslie

# Colour variables.
RED='\e[0;91m'
BLUE='\e[0;94m'
GREEN='\e[0;92m'
CLEAR='\e[0m'
# Date and Time variable for files.
date=$(/usr/bin/date +"%m_%d_%Y_%H_%M_%S")
# Get client information from standard input and output to a temp file to clean.
echo -e "$BLUE""Enter the list of cluster objects you would like to update remote access entries. <CTRL> <D> to finalize the list.""$CLEAR"
echo -e "$BLUE""Example: server1.example.com    cluster_test1.example.com""$CLEAR"
input_data=$(</dev/stdin)
/usr/bin/printf "%s\n" "${input_data[@]}" &>client_input_"$date".txt
echo ""
# Check if the client file exists. << Debug Step
input_file=client_input_"$date".txt
if test -f "$input_file"; then
    /usr/bin/echo ""
    /usr/bin/echo -e "$GREEN""$input_file exists.""$CLEAR"
    /usr/bin/echo ""
else
    /usr/bin/echo -e "$RED""File doesnt exist. Please make sure that $input_file is generated in the same directory as this script.""$CLEAR"
    exit 1
fi
# Input Correction: Edit initial input file to remove any blank lines. This is to prevent a sitiation where clients are mass edited that are not listed in the file.
/usr/bin/sed '/^[[:space;]]*$/d;/^$/d' client_input_"$date".txt > client_clean_"$date".txt
# Generate arry from client_clean file.
mapfile -t servers < <(awk '{print $1}' client_clean_"$date".txt)
mapfile -t clusters < <(awk '{print $2}' client_clean_"$date".txt)
# Print the array of clients.
/usr/bin/echo -e "$BLUE""List of clients and clusters:""$CLEAR"
/usr/bin/echo ""
paste <(/usr/bin/printf "%s\n" "${servers[@]}") <(/usr/bin/printf "%s\n" "${clusters[@]}")
/usr/bin/echo ""
# Error Catch: Count to make sure the clists is greater than zero. 
count="$(echo "${#servers[@]}")"
if [ "$count" -lt 1 ]; then
    /usr/bin/echo -e "$RED""No clients input into script. Check $input_file. Exiting script.""$CLEAR"
    exit 1
fi
/usr/bin/echo ""
/usr/bin/echo -e "Number of clients is: $count clients."
/usr/bin/echo ""
# Create the input file for nsradmin.
while read -r LINE; do
    cluster=$(/usr/bin/echo "$LINE" | awk '{print $2}')
    client=$(/usr/bin/echo "$LINE" | awk '{print $1}')
    /usr/bin/echo -e ". type: nsr client; name: $cluster \nappend remote access: $client" | tee -a nsradmin_input_"$date".txt >/dev/null
done < client_clean_"$date".txt
/usr/bin/echo -e "quit" | tee -a nsradmin_input_"$date".txt >/dev/null
# Cat out nsradmin input file.
/usr/bin/echo -e "$BLUE""nsradmin input:""$CLEAR"
echo ""
cat nsradmin_input_"$date".txt
/usr/bin/echo ""
# User confirmation case for the user to continue or exit out.
while true; do
    read -r -p 'Do you want to continue? Yes/No ' continue
    case "$continue" in
    n | N | no | No) /usr/bin/rm nsradmin_input_"$date".txt nsradmin_output_"$date".txt client_clean_"$date".txt client_input_"$date".txt 2>/dev/null & exit 1 ;;
    y | Y | yes | Yes) break ;;
    *) /usr/bin/echo -e "$RED""Response not valid""$CLEAR" ;;
    esac
done
/usr/bin/echo ""
# nsradmin with input from nsradmin_input file.
/usr/sbin/nsradmin -i nsradmin_input_"$date".txt >nsradmin_output_"$date".txt
# Output from nsradmin.
/usr/bin/echo -e "nsradmin output:"
cat nsradmin_output_"$date".txt
/usr/bin/echo ""
# Cleanup files and the end.
echo -e "$BLUE""Cleaning up temporary files""$CLEAR"
rm nsradmin_input_"$date".txt nsradmin_output_"$date".txt client_clean_"$date".txt client_input_"$date".txt
echo ""
# Press any keep to exit the script.
echo "Press any key to exit."
while true; do
    if read -rn 1; then exit; else :; fi
done
