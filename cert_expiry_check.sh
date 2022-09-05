#!/bin/bash 
# Script to check and report on certificate expiry and email results.
# By Jared Leslie

# Colour variables.
RED='\e[0;91m'
GREEN='\e[0;92m'
YELLOW='\e[43m'
CLEAR='\e[0m'
#Grace days before expiry.
gracedays=30
#Email address to send report
email=example@example.com
#URL lists with port to check.
declare -a servers=(
    "google.com:443"
    "shellcheck.net:443"
    "expired.badssl.com:443"
)
#Certificate expiry.
echo -e "Checking Certicates..."
echo -e "Grace days is set to $gracedays days."
echo -e ""
for server in "${servers[@]}"; do
        #Capture expiry date using openssl using port defined in the servers array.
        data="$(date --date="$(echo | openssl s_client -connect "${server}" -servername "${server}" 2>/dev/null | openssl x509 -noout -enddate | awk -F '=' '{print $NF}' )" --iso-8601)"
        #Math to compare and generate date difference.
        ssldate="$(date -d "${data}" '+%s')"
        nowdate="$(date '+%s')"
        diff="$(("$ssldate"-"$nowdate"))"
        #If statement tests to determine if a cert is expired or expring based on the gracedays.
        if test "${diff}" -lt "$(("${gracedays}"*24*3600))"; then
            if test "${diff}" -lt "0"; then
                echo -e "$RED""The certificate for ${server} has already expired.""$CLEAR"
            else
                echo -e "$YELLOW""The certificate for ${server} will expire in $(("$diff"/3600/24)) days.""$CLEAR"
            fi
        else
            echo -e "$GREEN""The certifcate for ${server} will expire in $(("$diff"/3600/24)) days.""$CLEAR"
        fi
done > /tmp/certifcate_output.txt
#Read output from for loop.
cat /tmp/certifcate_output.txt
#Send email
#echo /tmp/certifcate_output.txt | mailx -s "Certificate Expiry Report - $(date "+%D")" -a /tmp/certifcate_output.txt "$email"
