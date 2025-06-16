#!/bin/bash
#
# this script will allow you to send files to azure lab machines
# $2 will be used to specify the filename to send to the lab env
# $1 will be used to define the class that we will be sending files to
# then use scp with the password and the ip to send the files to the azure vm host :/home/tux/
# !!!for this script to work you will need to install the sshpass package using the command "sudo zypper in sshpass"!!!
#
COURSE="$1"
FILE="$2"

# now we need to make sure we have the latest version of the class.cfg file
FILE1=/home/$USER/az_config/class.cfg
if [ -f ${FILE1} ];
then
        echo "class.cfg exists"
else
        wget https://github.com/aksoutherland/az_config/raw/master/class.cfg -O /home/$USER/az_config/class.cfg
fi

# now we need to source the file so that contains the variables needed for the commands below
source ${FILE1}

usage () {
        echo
        echo "USAGE: $0 <course> <filename>"
        echo
        echo "When running this script, we specify 2 arguments to declare the lab environment and the filename to send"
        echo
        echo "Please re-run the command using the proper argument"
        echo
        echo "EXAMPLE COMMAND: $0 sle201 test.txt"
        echo
	exit
}

if [ -z "$1" ]
then
	echo "You forgot to specify the course ID"
	usage
	exit
fi

if [ -z "$2" ]
then
	echo "You forgot to specify the file you want to transfer"
	usage
	exit
fi

case $2 in
${FILE})
	for FILE in "${@:2}"
	do echo ${FILE}
	for server in ${IP};
	do
	${SCP} ${FILE} tux@${server}:/home/tux/
	done
	done
	echo 
	echo "Your file/s have been copied"
	echo
	;;

*) 
	echo
	usage
	exit
	;;
esac
