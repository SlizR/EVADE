#!/bin/sh
# EVADE Security Autosave script ('Saving any edits to a flash drive with the OS without saving data on the PC only uses RAM, the processor, and if for 3D graphics, the video card')

ROOT_DEV=$(mount | grep 'on / ' | awk '{print $1}')

PERSISTENT=$(lsblk -no MOUNTPOINT $ROOT_DEV)/tce

mkdir -p "$PERSISTENT"

export TCE_DIR="$PERSISTENT"


echo "Starting data restore from $PERSISTENT..."
filetool.sh -r


echo "Initializing .filetool.lst with common user directories..."
cat << EOF > /opt/.filetool.lst
home
opt/
etc/hosts
etc/shadow
etc/passwd
etc/group
etc/fstab
# Add directories of your Unix-like OS to backup
EOF

while true; do

    filetool.sh -b

    echo "$(date +'%Y-%m-%d %H:%M:%S') - Backup complete s."

    sleep 30
done &
