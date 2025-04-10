#!/bin/bash
# This script will setup Guacamole on the host
# Here we make sure that podman is installed
# the folders being created for caddy are for future use
# here we are adding the ip/hostname to /etc/hosts
# first we gather the details
IP=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
NAME=$(hostname)
# now we put those details into /etc/hosts
echo $IP  $NAME | sudo tee -a /etc/hosts
# now we install podman and xrdp if not installed
sudo zypper in -y podman xrdp freerdp-server
sudo systemctl enable --now xrdp
# Now we create the required folders
sudo mkdir -m 775 -p /podman/guac/home/.guacamole
sudo mkdir -m 775 -p /podman/postgresql/{data,init}
sudo mkdir -m 775 -p /podman/guacd/{drive,records}
sudo mkdir -m 775 -p /podman/caddy/{config,data}
# Set the ownership on the folders
sudo chown tux:users -R /podman
# now we open the correct ports in the firewall
sudo systemctl enable --now firewalld.service
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --add-service=rdp --permanent
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --reload
# # Create the Guacamole Network
podman network create guacamole
# Initialize the database for Guacamole
# podman run --rm docker.io/guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > /podman/postgresql/init/initdb.sql
# this command can be used to grab a custom initdb.sql that can be used to initialze the DB for first time use
wget https://github.com/aksoutherland/az_config/raw/master/initdb.sql -O /podman/postgresql/init/initdb.sql
wget https://github.com/aksoutherland/az_config/raw/master/guac-passwords.txt -O /podman/postgresql/guac-passwords.txt
sed -i "s/_HOSTNAME_/${NAME}/g" /podman/postgresql/init/initdb.sql
HASH=$(grep ${NAME} /podman/postgresql/guac-passwords.txt | cut -d "|" -f2)
SALT=$(grep ${NAME} /podman/postgresql/guac-passwords.txt | cut -d "|" -f3)
CONP=$(grep ${NAME} /podman/postgresql/guac-passwords.txt | cut -d "|" -f4)
sed -i "s/_PASS_HASH_/${HASH}/g" /podman/postgresql/init/initdb.sql
sed -i "s/_PASS_SALT_/${SALT}/g" /podman/postgresql/init/initdb.sql
sed -i "s/_CON_PASS_/${CONP}/g" /podman/postgresql/init/initdb.sql
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
-e POSTGRESQL_HOSTNAME=postgresql \
-e POSTGRESQL_DATABASE=guacamole_db \
-e POSTGRESQL_USER=guacamole_user \
-e POSTGRESQL_PASSWORD=some_password \
-e GUACD_PORT_4822_TCP_ADDR=guacd \
-e GUACD_PORT_4822_TCP_PORT=4822 \
-e GUACD_HOSTNAME=guacd \
-v /podman/guac/home:/etc/guacamole \
--requires=guacd,postgresql \
-p 8080:8080 \
--network=guacamole \
docker.io/guacamole/guacamole
# lets make sure linger is enabled for the user tux
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
