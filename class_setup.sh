#!/bin/bash
# Here we are going to download the class script and template config files
git clone https://github.com/aksoutherland/az_config
# now we create the folder that us used by the class script
mkdir ~/lab_setup
# now we cd into the folder
cd cd ~/lab_setup
# now we clone the repo's that contain the scripts that are used by the class script
git clone https://github.com/roncterry/configure-as-labmachine
git clone https://github.com/roncterry/create-azure-vm
git clone https://github.com/roncterry/azure-course-tools
git clone https://github.com/roncterry/install_lab_env
# now we place the class script in your path and make it executable
sudo cp az_config/class /usr/local/bin
sudo chmod +x /usr/local/bin/class
echo Setup Complete
