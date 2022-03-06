#!/usr/bin/env bash

# Time function for unquie output files.
timeNowSecondsEpoch=$(date +%s)
echo "${timeNowSecondsEpoch}"


echo "$(tput setaf 3)"Input Client Name"$(tput sgr0)"
# Get Client Name.
read -r clientName

