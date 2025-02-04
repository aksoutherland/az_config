#!/bin/bash
#
# this script will allow you to send files to azure lab machines
# $2 will be used to grab the filename to send to the lab env
# $1 will be used to define the class that we will be sending files to
# then use scp with the password and the ip to send the files to the azure vm host :/home/tux/
# !!!for this script to work you will need to install the sshpass package using the command "sudo zypper in sshpass"!!!
#
CLASS="$1"
FILE="$2"
PASSWD=$(grep VM_PASSWD_${CLASS} /home/$USER/bin/class | cut -d "=" -f 2 | tr -d \'\")
usage () {
        echo
        echo "USAGE: $0 <class> <filename>"
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
	usage

fi

if [ -z "$2" ]
then
	usage

fi

case $2 in
${FILE})
	for FILE in "${@:2}"
	do echo $FILE
	for server in $(az vm list-ip-addresses --output table | awk '{print $2}' | egrep -v 'Public|----');
	do
	sshpass -p $PASSWD scp -o StrictHostKeyChecking=accept-new $FILE tux@${server}:/home/tux/
done
done
	;;
*) 
	echo
	usage
	exit
	;;
esac
