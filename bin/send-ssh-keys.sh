#!/bin/bash
#
# !!!for this script to work you will need to install the sshpass package using the command "sudo zypper in sshpass"!!!
#
# this script will send your ssh-keys to the lab stations
# here we will grab the class name so that we know what password to use to connect to the vm
#
# $CLASS is the course - we use this to grab the passwd from the class script
# $1 will be used to define the class
#
# this is the command we use to get the password from the class script - you may have to change the path to the class script
# grep VM_PASSWD_${CLASS} /home/$USER/bin/class | cut -d "=" -f 2 | tr -d \'\"
#
CLASS=$1
# here we define the usage
usage () {
        echo
        echo "USAGE: $0 <class>"
        echo
        echo "When running this script, we specify 1 argument to declare the class"
        echo
        echo "Please re-run the command using the proper argument"
        echo
        echo "EXAMPLE COMMAND: send-ssh-keys.sh sle201"
        echo
	exit
}

if [ -z "$1" ]
then 
	usage

fi
case $1 in
$CLASS)
# here we gather the lab vm IP's and then push our local keyeach of the lab stations
	for server in $(az vm list-ip-addresses --output table | awk '{print $2}' | egrep -v 'Public|----');
	do 
	sshpass -p $(grep VM_PASSWD_${CLASS} /home/$USER/bin/class | cut -d "=" -f 2 | tr -d \'\") ssh-copy-id -o StrictHostKeyChecking=accept-new -f tux@${server};
	done
	;;
*) 
	echo 
	usage
	exit
	;;
esac
