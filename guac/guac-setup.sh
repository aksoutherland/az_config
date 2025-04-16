#!/bin/bash
# This script will setup Guacamole on the host
# first we gather some details to be used later
IP=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
NAME=$(hostname)
# now we put those details into /etc/hosts
echo $IP  $NAME | sudo tee -a /etc/hosts
# Now we create the required folders
sudo mkdir -m 775 -p /podman/guac/home/.guacamole
sudo mkdir -m 775 -p /podman/postgresql/{data,init}
sudo mkdir -m 775 -p /podman/guacd/{drive,records}
# now we make sure that podman is installed
sudo zypper in -y podman
# now we make make sure subuids and subgids are setup
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 tux
# now we activate the changes
podman system migrate
# Set the ownership on the folders
sudo chown $UID:users -R /podman
# now we  make sure the firewall is enabled and started, then we open the correct ports in the firewall for guac
sudo systemctl enable --now firewalld.service
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
# Create the Guacamole Network
podman network create guacamole
# here we grab the file used to initialize the database for Guacamole and put it in the correct location
wget https://github.com/aksoutherland/az_config/raw/master/guac/initdb.sql -O /podman/postgresql/init/initdb.sql
# now we need to grab the file that contains the passwords used by guacamole for the different classes
wget https://github.com/aksoutherland/az_config/raw/master/guac/vars -O /podman/postgresql/vars
# here we insert the guacamole server's hostname in the the SQL init script
sed -i "s/_HOSTNAME_/${NAME}/g" /podman/postgresql/init/initdb.sql
# now we set some variables for the passwords
HASH=$(grep ${NAME} /podman/postgresql/vars | cut -d "|" -f2)
SALT=$(grep ${NAME} /podman/postgresql/vars | cut -d "|" -f3)
CONP=$(grep ${NAME} /podman/postgresql/vars | cut -d "|" -f4)
export GUACDB=$(grep guacdb /podman/postgresql/vars | cut -d "|" -f2)
# here we insert those passwords into the SQL init script
sed -i "s/_PASS_HASH_/${HASH}/g" /podman/postgresql/init/initdb.sql
sed -i "s/_PASS_SALT_/${SALT}/g" /podman/postgresql/init/initdb.sql
sed -i "s/_CON_PASS_/${CONP}/g" /podman/postgresql/init/initdb.sql
# Start the required containers starting with postgresql
podman run -d --name postgresql \
-v /podman/postgresql/init:/docker-entrypoint-initdb.d \
-v /podman/postgresql/data:/var/lib/postgresql/data \
-v /etc/localtime:/etc/localtime:ro \
-e POSTGRES_USER=guacamole \
-e POSTGRES_PASSWORD=${GUACDB} \
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
-e POSTGRESQL_USER=guacamole \
-e POSTGRESQL_PASSWORD=${GUACDB} \
-e GUACD_PORT_4822_TCP_ADDR=guacd \
-e GUACD_PORT_4822_TCP_PORT=4822 \
-e GUACD_HOSTNAME=guacd \
-v /podman/guac/home:/etc/guacamole \
--requires=guacd,postgresql \
-p 8080:8080 \
--network=guacamole \
docker.io/guacamole/guacamole
# lets make sure linger is enabled for the user tux so that we can have the containers start at bootup
loginctl enable-linger $USER
loginctl show-user $USER
# create the folder for the container service files
mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
# now we create the container service files
podman generate systemd --files --name postgresql > /dev/null 2>&1
podman generate systemd --files --name guacd > /dev/null 2>&1
podman generate systemd --files --name guacamole > /dev/null 2>&1
cd ~
# reload systemctl user daemon so that the newly created service files are seen by systemd
systemctl --user daemon-reload > /dev/null 2>&1
# finally, enable the container service files so that containers will start at boot
systemctl --user enable container-postgresql.service > /dev/null 2>&1
systemctl --user enable container-guacd.service > /dev/null 2>&1
systemctl --user enable container-guacamole.service > /dev/null 2>&1
rm /podman/postgresql/.vars > /dev/null 2>&1
echo
echo
echo "Guacamole has been successfully configured"
echo
