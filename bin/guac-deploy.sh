#!/bin/bash
# this script will deploy guacamole on the lab vm's
ACTION=$1
# this is the course that we are working with
COURSE=$2

# we need to make sure that we have the newest version of class.cfg so that we have the proper password
FILE1=/home/$USER/az_config/class.cfg
if [ -f ${FILE1} ];
then
        echo "class.cfg exists"
else
        wget https://github.com/aksoutherland/az_config/raw/master/class.cfg -O /home/$USER/az_config/class.cfg
fi

# now we need to do is make sure we have latest version of the guac script to send to the remote machine
FILE2=/home/$USER/bin/guac
if [ -f ${FILE2} ];
then
        echo "guac script exists"
else
        wget https://github.com/aksoutherland/az_config/raw/master/guac/guac -O /home/$USER/bin/guac
fi

usage () {
	echo
	echo "USAGE: $0 <action> <course>"
	echo
	echo "When running this script, you need to supply 2 arguments,"
	echo
	echo "The first argument will specify the "Action" you wish to perform"
	echo "     A. Use "setup" to deploy Guacamole to the lab environment"
	echo "     B. Use "remove" to remove Guacamaole from the lab environment"
	echo
	echo "The second argument will be the name of the course you are working with"
	echo
	echo "Please re-run the command with the proper arguments"
	echo
	echo "EXAMPLE COMMANDS: guac-deploy.sh setup sle301"
	echo "                  guac-deploy.sh remove sle201"
	echo
	echo
}

if [ -z "${ACTION}" ] 
then
	echo
	echo "You are missing the action command"
	echo "Please specify either appropriate action"
	echo 
	usage
	exit

elif [ -z "${COURSE}" ]
then
	echo
	echo "You are missing the course"
	echo "Please specify the course code for the course you want to work with"
	echo 
	usage
	exit
fi

source ${FILE1}

# here we will either setup or remove guacamole
case $1 in
setup)
# this is where we deploy guacamole
	for server in ${IP};
	do echo $server &&
		${SSH} /home/$USER/bin/guac tux@${server}:/home/tux/bin/ && 
		${SCP} tux@${server} bash /home/tux/bin/guac setup
        done
	echo "Your lab password is:"
        echo "${PASSWD}"
	echo "Your server IP's are:"
        echo "${NAME}"
	echo
	echo "You can connect to the lab environment VM's"
	echo "using this command"
	echo "for line in ${IP}; do firefox --new-tab --url "$line:8080" & sleep 1 ; done"
        ;;

remove)
# this is where we remove guacamole
	for server in ${IP};
	do echo $server && 
		${SSH} tux@${server} bash /home/tux/bin/guac remove
        done
        ;;

*) 
	echo 
	usage
	exit
	;;

esac
