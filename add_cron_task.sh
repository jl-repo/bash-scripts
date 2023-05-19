#!/bin/bash

# Prompt for username and password
read -rp "Enter your username: " username
read -rsp "Enter your password: " password
echo

# Read server list from file into an array
mapfile -t servers <serverlist.txt

# Define variables
cron_task="0 * * * * /path/to/command"
line_to_add="cat /etc/sudoers > /tmp/sudoers"
file_directory="/tmp"
file_name="file.sh"
path_to_file="${file_directory}/${file_name}"
backup_filename="${path_to_file}_$(date +%Y%m%d%H%M%S).backup"
backup_crontab="crontab_$(date +%Y%m%d%H%M%S).backup"

# Track servers with issues
servers_with_issues=()

# Loop through servers
for server in "${servers[@]}"; do
    echo
    # Check if the user has sudo access
    echo "Checking sudo access on ${server}..."
    sudo_access=$(sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${username}@${server}" "sudo -n true && echo 'true' || echo 'false'")
    if [[ "${sudo_access}" == "true" ]]; then
        # Crontab checks
        echo "Checking for existing cron task on ${server}..."
        existing_cron=$(sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${username}@${server}" "sudo crontab -l 2>/dev/null")
        if [[ "${existing_cron}" == *"${cron_task}"* ]]; then
            echo "Cron task already exists on ${server}. Skipping..."
        else
            if [[ -z "${existing_cron}" ]]; then
                echo "${cron_task}" | sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${username}@${server}" "sudo crontab -"
            else
                echo "Creating backup of crontab on ${server}..."
                sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${username}@${server}" "sudo crontab -l > ${backup_crontab}"
                (
                    echo "${existing_cron}"
                    echo "${cron_task}"
                ) | sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${username}@${server}" "sudo crontab -"
            fi
        fi

        # File Content Checks
        echo "Checking if file exists on ${server}..."
        file_exists=$(sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${username}@${server}" "[ -f ${path_to_file} ] && echo 'true' || echo 'false'")
        if [[ "${file_exists}" == "true" ]]; then
            echo "Checking for existing line in the file on ${server}..."
            existing_lines=$(sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${username}@${server}" "sudo cat ${path_to_file}")
            if [[ "${existing_lines}" == *"${line_to_add}"* ]]; then
                echo "Line already exists on ${server}. Skipping..."
            else
                echo "Creating backup of the file on ${server}..."
                # Backup File
                sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${username}@${server}" "sudo cp ${path_to_file} ${backup_filename}"
                echo "Adding line to ${server}..."
                echo "${line_to_add}" | sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${username}@${server}" "sudo tee -a ${path_to_file} > /dev/null"
            fi
            # Check if the existing file is executable and make it executable if it is not
            executable=$(sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${username}@${server}" "sudo stat -c %A ${path_to_file} | grep -o 'x' || echo 'false'")
            if [[ "${executable}" == "false" ]]; then
                echo "Making ${path_to_file} executable on ${server}..."
                sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${username}@${server}" "sudo chmod +x ${path_to_file}"
            fi
        else
            echo "File does not exist on ${server}. Creating file and making it executable..."
            # Create Directory
            sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${username}@${server}" "sudo [ -d ${file_directory} ] || sudo mkdir -p ${file_directory}"
            # Create File
            sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${username}@${server}" "sudo touch ${path_to_file} && sudo chmod +x ${path_to_file}"
            echo "Adding line to ${server}..."
            # Add Line
            echo "${line_to_add}" | sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${username}@${server}" "sudo tee -a ${path_to_file} > /dev/null"
        fi
    else
        echo "User does not have sudo access on ${server}. Skipping..."
        servers_with_issues+=("${server}")
    fi
done

# Print servers with issues
if [[ ${#servers_with_issues[@]} -gt 0 ]]; then
    echo "Servers with issues:"
    printf '%s\n' "${servers_with_issues[@]}"
fi

echo "Done."
