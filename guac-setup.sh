#!/bin/bash
# This script will setup Guacamole on the host
# Here we make sure that podman is installed
# the folders being created for caddy are for future use
sudo zypper in -y podman
# Now we create the required folders
sudo mkdir -m 775 -p /podman/guac/home
sudo mkdir -m 775 -p /podman/postgresql/{data,init}
sudo mkdir -m 775 -p /podman/guacd/{drive,records}
sudo mkdir -m 775 -p /podman/caddy/{config,data}
# Set the ownership on the folders
sudo chown tux:users -R /podman
# Create the Guacamole Network
podman network create guacamole
# Initialize the database for Guacamole
podman run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > /podman/postgresql/init/initdb.sql
# Start the required containers starting with postgresql
podman run -d --name postgresql \
-v /podman/postgresql/init:/docker-entrypoint-initdb.d \
-v /podman/postgresql/data:/var/lib/postgresql/data \
-v /etc/localtime:/etc/localtime:ro \
-e POSTGRES_USER=guacamole_user \
-e POSTGRES_PASSWORD=some_password \
-e POSTGRES_DB=guacamole_db \
--network=guacamole \
docker.io/library/postgres:16-alpine
# followed by the Guacamole listener daemon
podman run -d --name guacd \
-v /etc/localtime:/etc/localtime:ro \
-v /podman/guacd/records:/record \
-v /podman/guacd/drive:/drive \
--network=guacamole \
docker.io/guacamole/guacd
# now for the Guacamole container
podman run -d --name guacamole \
-e POSTGRES_HOSTNAME=postgresql \
-e POSTGRES_DATABASE=guacamole_db \
-e POSTGRES_USER=guacamole_user \
-e POSTGRES_PASSWORD=some_password \
-e GUACD_PORT_4822_TCP_ADDR=guacd \
-e GUACD_PORT_4822_TCP_PORT=4822 \
-e GUACD_HOSTNAME=guacd \
--requires=guacd \
--requires=postgresql \
-p 8080:8080 \
--network=guacamole \
docker.io/guacamole/guacamole
# lets make sure linger is enabled for the user tux
loginctl show-user tux
loginctl enable-linger tux
loginctl show-user tux
# create the folder for the container service files
mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
# now we create the container service files
podman generate systemd --files --name postgresql
podman generate systemd --files --name guacd
podman generate systemd --files --name guacamole
# reload systemctl user daemon
systemctl --user daemon-reload
# finally, enable the container service files so that containers will start at boot
systemctl --user enable container-postgresql.service 
systemctl --user enable container-guacd.service 
systemctl --user enable container-guacamole.service 
# need to add a section for the config for guac for user mappings and such
