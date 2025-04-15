#!/bin/bash
#
# this script will send the snapshot script to the lab vm host so that we can take snapshots of the vms
# $CLASS is the course - we use this to grab the passwd from the class script and should be the first argument
# $1 will be used to define the class
# $ACTION is used to define the action will be performing with the snapshots, IE. create, list, delete, revert
#

CLASS="$1"
ACTION="$2"
PASSWD=$(grep VM_PASSWD_${CLASS} /home/$USER/bin/class | cut -d "=" -f 2 | tr -d \'\")

# then use scp with the password and the ip to send the snapshot script to the azure vm host :/home/tux/
# !!!for this script to work you will need to install the sshpass package using the command "sudo zypper in sshpass"!!!
#
CLASS="$1"
PASSWD=$(grep VM_PASSWD_${CLASS} /home/$USER/bin/class | cut -d "=" -f 2 | tr -d \'\")

usage () {
        echo
        echo "USAGE: $0 <class> <filename>"
        echo
        echo "When running this script, we specify 1 argument to declare the lab environment"
        echo
        echo "Please re-run the command using the proper argument"
        echo
        echo "EXAMPLE COMMAND: $0 sle201 create/list/delete/revert"
        echo
	exit
}

if [ -z "$1" ]
then
	usage

fi

if [ -z "$2" ]
then
	usage

fi
# 
# here we are going to send the snapshot script to each of the lab stations
#
for server in $(az vm list-ip-addresses --output table | awk '{print $2}' | egrep -v 'Public|----');
	do echo $server && sshpass -p ${PASSWD} scp /home/$USER/bin/snapshot tux@${server}:/home/tux/; done
#
# this sections defines what actions we will complete based on the value of $2
#
case $2 in
list)
# this is where we list the snapshots
	for server in $(az vm list-ip-addresses --output table | awk '{print $2}' | egrep -v 'Public|----');
	do echo $server && sshpass -p ${PASSWD} ssh tux@${server} snapshot list; done
	;;
create)
# this is where we create the snapshots
        for server in $(az vm list-ip-addresses --output table | awk '{print $2}' | egrep -v 'Public|----');
	do echo $server && sshpass -p ${PASSWD} ssh tux@${server} snapshot create; done
        ;;
delete)
# this is where we delete the snapshots
	for server in $(az vm list-ip-addresses --output table | awk '{print $2}' | egrep -v 'Public|----');
	do echo $server && sshpass -p ${PASSWD} ssh tux@${server} snapshot revert; done
        ;;
revert)
# this is where we revert the snapshots
	for server in $(az vm list-ip-addresses --output table | awk '{print $2}' | egrep -v 'Public|----');
	do echo $server && sshpass -p ${PASSWD} ssh tux@${server} snapshot delete; done
        ;;
*) 
	echo 
	usage
	exit
	;;
esac
