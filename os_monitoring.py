#!/usr/bin/env python3

# import modules
import os
import subprocess
import time
from datetime import datetime

# file and directory variables
file_name = f"osinfo-{datetime.now():%Y-%m-%d-%H-%M}.txt"
file_path = r'/opt/DBRaaS/logs/'

# check if directory exists. if not create.
check_folder = os.path.isdir(file_path)
if not check_folder:
    os.makedirs(file_path)

with open(file_path + file_name, 'w') as file:
    # memory check
    memory = subprocess.run(["free", "-m"],capture_output=True, encoding='UTF-8')
    file.write("memory:\n")
    file.write(memory.stdout)
    file.write("\n")

    # free space check
    file.write("disk space:\n")
    disk = subprocess.run(["df", "-h"],capture_output=True, encoding='UTF-8')
    file.write(disk.stdout)
    file.write("\n")

    # arp check
    file.write("arp:\n")
    arp = subprocess.run(["arp", "-a"],capture_output=True, encoding='UTF-8')
    file.write(arp.stdout)
    file.write("\n")

    # ifconfig check
    file.write("ifconfig:\n")
    ifconfig = subprocess.run(["ifconfig", "-a"],capture_output=True, encoding='UTF-8')
    file.write(ifconfig.stdout)
    file.write("\n")

    # ifconfig check
    file.write("netstat:\n")
    netstat = subprocess.run(["netstat", "-n", "-r"],capture_output=True, encoding='UTF-8')
    file.write(netstat.stdout)
    file.write("\n")

    # dmesg check
    file.write("dmesg:\n")
    dmesg = subprocess.run(["dmesg"],capture_output=True, encoding='UTF-8')
    file.write(dmesg.stdout)
    file.write("\n")

    # uptime check
    file.write("uptime:\n")
    uptime = subprocess.run(["uptime"],capture_output=True, encoding='UTF-8')
    file.write(uptime.stdout)
    file.write("\n")

    # who check
    file.write("who:\n")
    who = subprocess.run(["who"],capture_output=True, encoding='UTF-8')
    file.write(who.stdout)
    file.write("\n")

    # mount check
    file.write("mount:\n")
    mount = subprocess.run(["mount"],capture_output=True, encoding='UTF-8')
    file.write(mount.stdout)
    file.write("\n")

    #  iostat check
    file.write("iostat:\n")
    iostat = subprocess.run(["iostat"],capture_output=True, encoding='UTF-8')
    file.write(iostat.stdout)
    file.write("\n")

    #  mpstat check
    file.write("mpstat:\n")
    mpstat = subprocess.run(["mpstat"],capture_output=True, encoding='UTF-8')
    file.write(mpstat.stdout)
    file.write("\n")

    #  mpstat check
    file.write("vmstat:\n")
    vmstat = subprocess.run(["vmstat", "-w"],capture_output=True, encoding='UTF-8')
    file.write(vmstat.stdout)
    file.write("\n")

    #  sar check
    file.write("sar:\n")
    sar = subprocess.run(["sar"],capture_output=True, encoding='UTF-8')
    file.write(sar.stdout)
    file.write("\n")

    #  proc cmdline check
    file.write("proc cmdline:\n")
    cmdline = subprocess.run(["cat", "/proc/cmdline"],capture_output=True, encoding='UTF-8')
    file.write(cmdline.stdout)
    file.write("\n")

    #  proc cpuinfo check
    file.write("proc cpuinfo:\n")
    cpuinfo = subprocess.run(["cat", "/proc/cpuinfo"],capture_output=True, encoding='UTF-8')
    file.write(cpuinfo.stdout)
    file.write("\n")

    #  proc devices check
    file.write("proc cpuinfo:\n")
    devices = subprocess.run(["cat", "/proc/devices"],capture_output=True, encoding='UTF-8')
    file.write(devices.stdout)
    file.write("\n")

    #  proc meminfo check
    file.write("proc meminfo:\n")
    meminfo = subprocess.run(["cat", "/proc/meminfo"],capture_output=True, encoding='UTF-8')
    file.write(meminfo.stdout)
    file.write("\n")

    #  proc partitions check
    file.write("proc partitions:\n")
    partitions = subprocess.run(["cat", "/proc/partitions"],capture_output=True, encoding='UTF-8')
    file.write(partitions.stdout)
    file.write("\n")

    #  proc version check
    file.write("proc version:\n")
    version = subprocess.run(["cat", "/proc/version"],capture_output=True, encoding='UTF-8')
    file.write(version.stdout)
    file.write("\n")

# Delete files program
def delete_old_files(root_dir_path, days):
    files_list = os.listdir(root_dir_path)
    current_time = time.time()
    for file in files_list:
        filepath = os.path.join(root_dir_path, file)
        if os.path.isfile(filepath) and (current_time - os.stat(filepath).st_mtime) > days * 86400:
            os.remove(filepath)

# Path and days variable to cleanup directory
if __name__ == '__main__':
    delete_old_files(file_path, 31)

#os.exit(0)
