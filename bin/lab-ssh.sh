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

COURSE=$1

usage () {
        echo
        echo "USAGE: $0 <COURSE> <MODE>"
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

# now we need to make sure we have the latest version of the class.cfg file
FILE=/home/$USER/az_config/class.cfg
if [ -f ${FILE} ];
then
        echo "class.cfg exists"
else
        wget https://github.com/aksoutherland/az_config/raw/master/class.cfg -O /home/$USER/az_config/class.cfg
fi

# now we need to source the file so that contains the variables needed for the commands below
source ${FILE}

case $2 in
add)
	# the first step is to back up your /etc/hosts and ~/.ssh/known_hosts file
	sudo cp /etc/hosts /etc/hosts-pre_class
	cp /home/$USER/.ssh/known_hosts /home/$USER/.ssh/known_hosts-pre_class
	# now we need to send your ssh keys to the lab vm's
	az vm list-ip-addresses -g ${RG} --output table | egrep -v 'Public|----' | awk -F '-' '{print $2,$1}' | awk '{print $2,$1}' | sudo tee -a /etc/hosts
	for server in ${IP};
	do sshpass -e ssh-copy-id -o StrictHostKeyChecking=accept-new -f tux@$server &&
		ssh-keyscan -H $server >> /home/$USER/.ssh/known_hosts;
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
