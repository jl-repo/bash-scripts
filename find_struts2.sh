#!/bin/bash
# --------------------------------------------------------------
# Remote Struts Search Script
# --------------------------------------------------------------
# This Bash script facilitates a remote search for files matching
# a specified pattern (struts2-core-*.jar) on a list of remote
# servers. The search results are collected and saved in a CSV
# file (struts_search_results.csv), indicating the server where
# each match was found.
#
# Usage:
#   - Output CSV File: struts_search_results.csv
#   - Server List File: server_list.txt
#   - Search Pattern: struts2-core-*.jar
#   - User Authentication: Username and password prompted
#
# Execution:
#   1. Initializes the CSV file with headers (Server,Results).
#   2. Checks for the existence of the server list file.
#   3. Reads the server list into an array.
#   4. Iterates over servers, conducting a remote search.
#   5. Appends results to the CSV file (Server,FilePath).
#   6. Displays progress and separators for each server.
#   7. Prints a message upon completion.
#
# Prerequisites:
#   - Dependencies: sshpass, awk
#   - SSH Configuration: Passwordless authentication recommended.
#
# Security Considerations:
#   - Secure Password Entry: Password input hidden (-s flag).
#   - Strict Host Key Checking: Disabled for non-interactive SSH.
#
# Notes:
#   - Assumes user has sudo privileges remotely.
#   - Review and adapt based on security and environment considerations.
#
# Example Usage:
#   ./find_struts2.sh
#
# Author:
#   Jared Leslie
#   jaredaleslie@gmail.com
#
# Version: 1.0
# Date: 11/12/2023

# Output CSV file
output_file="struts_search_results.csv"

# File containing a list of remote servers, one per line
servers_file="server_list.txt"

# Pattern to search for
file_pattern="struts2-core-*.jar"

# Prompt for username
read -r -p "Enter your username: " username

# Prompt for password (use -s flag to hide input)
read -r -s -p "Enter your password: " password
echo

# Create or overwrite the CSV file with headers
echo "Server,Results" > "$output_file"

# Check if the servers file exists
if [ ! -f "$servers_file" ]; then
    echo "Error: Server list file '$servers_file' not found."
    exit 1
fi

# Read the server list file into an array
mapfile -t servers < "$servers_file"

# Iterate over the array of servers
for server in "${servers[@]}"; do
    echo "Searching on $server..."
    
    # Run find command remotely from root with sudo and append to CSV file
    sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username@$server" "sudo find / -type f -name '$file_pattern' 2>/dev/null" | \
    awk -v s="$server" '{print s "," $0}' >> "$output_file"
    
    echo -e "\n-------------------------------------\n"
done

echo "Search results have been saved to $output_file."
