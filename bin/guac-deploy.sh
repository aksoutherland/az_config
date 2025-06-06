#!/bin/bash
# this script will deploy guacamole on the lab vm's
ACTION=$1
# this is the course that we are working with
COURSE=$2

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

# we are going to set some variables to be used in the for loops below
# here we get the resource group name
export RG="$(az group list -o table | grep ${COURSE} | cut -d " " -f1)"

# here we get the lab station password
export PASSWD=$(grep VM_PASSWD_${COURSE} /home/$USER/az_config/class.cfg | cut -d "=" -f 2 | tr -d \'\")

# now we set the password
export SSHPASS=${PASSWD}

# here we are going to get a list of the IP's of the remote machines
export IP=$(az vm list-ip-addresses -g ${RG} --output table | awk '{print $2}' | egrep -v 'Public|----')

# now we need to do is make sure we have latest version of the guac script to send to the remote machine
FILE=/home/$USER/bin/guac
if [ -f ${FILE} ];
then
        echo "guac script exists"
else
	wget https://github.com/aksoutherland/az_config/raw/master/guac/guac -O /home/$USER/bin/guac
fi

# here we will either setup or remove guacamole
case $1 in
setup)
# this is where we deploy guacamole
	for server in $(az vm list-ip-addresses -g ${RG} --output table | awk '{print $2}' | egrep -v 'Public|----');
	do echo $server &&
		sshpass -e scp -o StrictHostKeyChecking=no /home/$USER/bin/guac tux@${server}:/home/tux/bin/ && 
		sshpass -e ssh -o StrictHostKeyChecking=no tux@${server} bash /home/tux/bin/guac setup
        done
	echo "Your lab password is:"
        echo "${PASSWD}"
	echo "Your server IP's are:"
        echo "${IP}"
        ;;

remove)
# this is where we remove guacamole
	for server in $(az vm list-ip-addresses -g ${RG} --output table | awk '{print $2}' | egrep -v 'Public|----');
	do echo $server && 
		sshpass -e ssh -o StrictHostKeyChecking=no tux@${server} bash /home/tux/bin/guac remove
        done
        ;;

*) 
	echo 
	usage
	exit
	;;

esac
