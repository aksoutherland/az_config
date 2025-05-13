#!/bin/bash
# this script will remove podman for testing purposes
echo "Removing Guacamole"
# first we stop all containers
podman stop -a
# then we remove all of the containers
podman rm -a
# now we remove all of the artifacts
podman system prune -af
# here we clean up the folder that contains the service files for the containers
systemctl --user disable container-postgresql.service > /dev/null 2>&1
systemctl --user disable container-guacd.service > /dev/null 2>&1
systemctl --user disable container-guacamole.service > /dev/null 2>&1
sudo rm -rf ~/.config/systemd/user
systemctl --user daemon-reload > /dev/null 2>&1
# finally we remove the folders that podman was using
sudo rm -rf /podman
echo "Guacamole has been removed"
