#!/bin/bash
#first we need to mount the remote filesystem
echo "Mounting remote filesystem"
echo ""
echo ""
echo ""
sudo mount 192.168.81.230:/volume1/nfs1 /mnt/nfs
#now we backup your files
echo "backing up your files"
echo ""
echo ""
echo ""
sudo rsync -rav --progress /mnt/4T_USB/Packaged/ /mnt/nfs/packaged/ 2>/dev/null
cd /home/$USER/
sudo rsync -rav --progress Documents bin workbench Downloads ISO lab_setup SUSE Videos /mnt/nfs/backup 2>/dev/null
#now we unmount the remote  filesystem
echo "unMounting remote filesystem"
echo ""
echo ""
echo ""
sudo umount /mnt/nfs
#your backup has completed
echo "Your backup has completed"
echo ""
echo ""
echo ""
