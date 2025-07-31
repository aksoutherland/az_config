#!/bin/bash
#
# !!! the sshpass package is required for this to work, you can install sshpass with this command !!!
# sudo zypper in sshpass
#
# this script will connect to your lab vm and create vm snapshots
# here we will grab the class name so that we know what password to use to connect to the vm
#
# $CLASS is the course - we use this to grab the passwd from the class script and should be the first argument
# $1 will be used to define the class
# $ACTION is used to define the action will be performing with the snapshots, IE. create, list, delete, revert
# $2 will be used to define the action
# $SNAPNAME will be used to define the name of the snapshot
# the next 2 variables are not currently being passed to the ssh command to the remote machine - will figure this out later
# $3 will be used to define the snapshot name
# $DESCRIPTION will be used to define the description of the snapshot if needed
# $4 will be used to define the snapshot description
#
COURSE="$1"
ACTION="$2"
SNAPNAME="$3"
DESCRIPTION="$4"

# now we need to make sure we have latest version of the snapshot script to send to the remote machine
FILE=/home/$USER/bin/snapshot
if [ -f ${FILE} ];
then
        echo "snapshot script exists"
else
        wget https://github.com/aksoutherland/az_config/raw/master/bin/snapshot -O /home/$USER/bin/snapshot
fi

# here we define the usage
usage () {
        echo
        echo "USAGE: $0 <course> <action>"
        echo
        echo "When running this script, we specify 2 arguments to declare the class and the snapshot action"
	echo 
	echo "The first argument will specify the lab environment and the second argument will specify the snapshot action"
	echo
	echo "The third option if used will allow you to specify the name of the snapshot you are creating/deleting/reverting"
	echo
	echo "The fourth option if used will allow you to set a description for the snapshot"
        echo
        echo "Please re-run the command using the proper arguments"
        echo
        echo "EXAMPLE COMMAND: "
	echo "			$0 sle201 create mysnapshotname mydescription"
	echo "			$0 sle201 delete mysnapsnothname"
	echo "			$0 sle201 list"
	echo "			$0 sle201 revert mysnapshotname"
	echo 
	echo "The snapshot name and description are not required"
        echo
	exit
}

# We set the variables if they are not specified when the command is run
	
if [ -z "$1" ]
then
	usage
fi

if [ -z "$2" ]
then 
	usage
fi

if [ -z "$3" ]
then
	export SNAPNAME=snap01
fi

if [ -z "$4" ]
then
        export DESCRIPTION=pre-class
fi

# here we set the region for the course
REGION="centralus"

# here we get the resource group name
export RG=$(az group list -o table | grep ${COURSE}-${REGION} | cut -d " " -f1)

# here we are going to get a list of the IP's of the remote machines
export IP=$(az vm list-ip-addresses -g ${RG} --output table | awk '{print $2}' | egrep -v 'Public|----')

# here we get the lab station password
export PASSWD=$(grep VM_PASSWD_${COURSE} /home/$USER/az_config/class.cfg | cut -d "=" -f 2 | tr -d \'\")

# now we set the password
export SSHPASS=${PASSWD}

# here we are setting the options for ssh and scp commands used in various scripts
export SCP="sshpass -e scp -o StrictHostKeyChecking=no"
export SSH="sshpass -e ssh -o StrictHostKeyChecking=no"

case $2 in
list)
# this is where we list the snapshots
	for server in ${IP};
	do echo $server && 
		${SCP} ${FILE} tux@${server}:/home/tux/bin/ && 
		${SSH} tux@${server} bash /home/tux/bin/snapshot list
	done
	;;

create)
# this is where we create the snapshots
        for server in ${IP};
	do echo $server && 
		${SCP} ${FILE} tux@${server}:/home/tux/bin/ && 
		${SSH} tux@${server} bash /home/tux/bin/snapshot create ${SNAPNAME} ${DESCRIPTION}
        done
        ;;

delete)
# this is where we delete the snapshots
	for server in ${IP};
	do echo $server && 
		${SCP} ${FILE} tux@${server}:/home/tux/bin/ && 
		${SSH} tux@${server} bash /home/tux/bin/snapshot delete ${SNAPNAME}
        done
        ;;

revert)
# this is where we revert the snapshots
	for server in ${IP};
	do echo $server && 
		${SCP} ${FILE} tux@${server}:/home/tux/bin/ && 
		${SSH} tux@${server} bash /home/tux/bin/snapshot revert ${SNAPNAME} ${DESCRIPTION}
        done
        ;;

*) 
	echo 
	usage
	exit
	;;

esac
