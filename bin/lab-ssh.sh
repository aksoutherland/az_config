#!/bin/bash
#
# !!!for this script to work you will need to install the sshpass package using the command "sudo zypper in sshpass"!!!
#
# this script will send your ssh-keys to the lab stations
# this script will also add the azure lab vm's names and ip's to your local /etc/hosts file
#
# $CLASS is the course - we use this to grab the passwd from the class script
# $1 will be used to define the class
# $2 will be the action - add or remove

CLASS=$1

usage () {
        echo
        echo "USAGE: $0 <CLASS> <MODE>"
        echo
        echo "When running this script, you need to supply 2 arguments"
	echo
	echo "The first argument should be course_id"
	echo 
	echo "The second argument should be the action"
        echo
        echo "<ACTION> will be either <add> to append the station names to your local /etc/hosts file"
	echo 
	echo "And add the ssh-keys to your local known_hosts file"
	echo
	echo "or <remove> to delete the station names for your local /etc/hosts file"
	echo 
	echo "and remove the ssh-fingerprints from your local known_hosts file"
	echo
        echo "Please re-run the command with the proper argument"
        echo
        echo "EXAMPLE COMMAND: $0 sle201 add"
        echo "                 $0 sle201 remove"
        echo
}

if [ -z "$1" ]
then
	echo "You are missing the Course ID"
	usage
	exit
fi

if [ -z "$2" ]
then
	echo "You are missing the action"
        usage
	exit
fi

# we are going to set some variables to be used in the for loops below
# here we get the resource group name
export RG="$(az group list -o table | grep ${CLASS} | cut -d " " -f1)"

# here we get the lab station password
export PASSWD=$(grep VM_PASSWD_${CLASS} /home/$USER/az_config/class.cfg | cut -d "=" -f 2 | tr -d \'\")

# now we set the password
export SSHPASS=${PASSWD}

# here we are going to get a list of the IP's of the remote machines
export IP=$(az vm list-ip-addresses -g ${RG} --output table | awk '{print $2}' | egrep -v 'Public|----')


case $2 in
add)
	# the first step is to back up your /etc/hosts and ~/.ssh/known_hosts file
	sudo cp /etc/hosts /etc/hosts-pre_class
	cp /home/$USER/.ssh/known_hosts /home/$USER/.ssh/known_hosts-pre_class
	# now we need to get a list of stations from azure and append them to your existing /etc/hosts file
	az vm list-ip-addresses -g ${RG} --output table | awk '{print $2,$1}' | egrep -v 'Public|----' | sudo tee -a /etc/hosts
	# now we need to send your ssh keys to the lab vm's
	for server in $(az vm list-ip-addresses -g ${RG} --output table | awk '{print $2}' | egrep -v 'Public|----');
	do
	sshpass -p ${PASSWD} ssh-copy-id -o StrictHostKeyChecking=accept-new -f tux@${server};
	ssh-keyscan -H $server >> /home/$USER/.ssh/known_hosts
	done
	# this next loop allows you to connect to the hostname without having to accept the fingerprint
	for hostname in $(az vm list-ip-addresses -g ${RG} --output table | awk '{print $1}' | egrep -v 'Public|----');
	do
	ssh-keyscan -H $hostname >> /home/$USER/.ssh/known_hosts
	done
	echo
	echo "Your hosts and known_hosts files have been updated"
	echo
	;;

remove)
	# here we restore /etc/hosts and .ssh/known_hosts back to their original state
	sudo cp /etc/hosts-pre_class /etc/hosts
	cp /home/$USER/.ssh/known_hosts-pre_class /home/$USER/.ssh/known_hosts
	echo
	echo "Your hosts and known_hosts files have been restored"
	echo
	;;

*)
	echo
	usage
	exit
	;;
esac
