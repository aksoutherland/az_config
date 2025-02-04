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
# $3 will be used to define the snapshot name
# $DESCRIPTION will be used to define the description of the snapshot if needed
# $4 will be used to define the snapshot description
#
CLASS="$1"
ACTION="$2"
SNAPNAME="$3"
DESCRIPTION="$4"
PASSWD=$(grep VM_PASSWD_${CLASS} /home/$USER/bin/class | cut -d "=" -f 2 | tr -d \'\")
# here we define the usage
usage () {
        echo
        echo "USAGE: $0 <class> <action>"
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
        echo "EXAMPLE COMMAND: $0 sle201 create/delete/list/revert mysnapshotname mydescription"
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
	SNAPNAME=snap01
fi

if [ -z "$4" ]
then
        DESCRIPTION=pre-class
fi

# this is the command we use to get the password from the class script - you may have to change the path to the class script
# grep VM_PASSWD_${CLASS} /home/$USER/bin/class | cut -d "=" -f 2 | tr -d \'\"
#
case $2 in
list)
# this is where we list the snapshots
	for server in $(az vm list-ip-addresses --output table | awk '{print $2}' | egrep -v 'Public|----');
	do sshpass -p ${PASSWD} ssh tux@${server} "bash -s" << \EOF
 	for NAME in $(virsh list --all | awk '{print $2}'| grep -v Name);
 	do virsh snapshot-list $NAME; done
EOF
	done
	;;
create)
# this is where we create the snapshots
        for server in $(az vm list-ip-addresses --output table | awk '{print $2}' | egrep -v 'Public|----');
	do sshpass -p ${PASSWD} ssh tux@${server} "bash -s" << \EOF
        for NAME in $(virsh list --all | awk '{print $2}'| grep -v Name);
        do virsh snapshot-create-as --domain $NAME --name "$SNAPNAME" --description "$DESCRIPTION"; done
EOF
        done
        ;;
delete)
# this is where we delete the snapshots
	for server in $(az vm list-ip-addresses --output table | awk '{print $2}' | egrep -v 'Public|----');
	do sshpass -p ${PASSWD} ssh tux@${server} "bash -s" << \EOF
        for NAME in $(virsh list --all | awk '{print $2}'| grep -v Name);
        do virsh snapshot-delete --domain $NAME "$SNAPNAME" ; done
EOF
        done
        ;;
revert)
# this is where we revert the snapshots
	for server in $(az vm list-ip-addresses --output table | awk '{print $2}' | egrep -v 'Public|----');
	do sshpass -p ${PASSWD} ssh tux@${server} "bash -s" << \EOF
        for NAME in $(virsh list --all | awk '{print $2}'| grep -v Name);
        do virsh snapshot-revert --domain $NAME "$SNAPNAME" ; done
EOF
        done
        ;;
*) 
	echo 
	usage
	exit
	;;
esac
