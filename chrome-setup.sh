#!/bin/bash
# this command will add the repo for chrome
sudo zypper ar http://dl.google.com/linux/chrome/rpm/stable/x86_64 Google-Chrome
# this commands grabs the key for the above repo
wget https://dl.google.com/linux/linux_signing_key.pub
# this command imports the key for the repo
sudo rpm --import linux_signing_key.pub
# this command will install google chrome
sudo zypper in -y google-chrome-stable

