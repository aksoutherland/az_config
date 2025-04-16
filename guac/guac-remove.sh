#!/bin/bash
# this script will remove podman for testing purposes
podman stop -a
podman rm -a
podman system prune -af
sudo rm -rf ~/.config/systemd/user
sudo rm -rf /podman
