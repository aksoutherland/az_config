#!/bin/bash
# this script will remove podman for testing purposes
echo "Removing Guacamole"
# first we stop all containers
podman stop -a
# then we remove all of the containers
podman rm -a
# now we remove all of the artifacts
podman system prune -af
# here we remove the folder that contains the service files for the containers
sudo rm -rf ~/.config/systemd/user
# finally we remove the folders that podman was using
sudo rm -rf /podman
echo "Guacamole has been removed"
