#!/bin/bash
# this script will deploy guacamole on the lab vm's
ACTION=$1

# this is the course that we are working with
COURSE=$2

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

# here we set the region
REGION="centralus"

# here we get the resource group name
RG=$(az group list -o table | grep ${COURSE}-${REGION} | cut -d " " -f1)

# here we are going to get a list of the IP's of the remote machines
IP=$(az vm list-ip-addresses -g ${RG} --output table | awk '{print $2}' | egrep -v 'Public|----')

# here we are going to get a list of HOSTNAME's and IP's of the remote machines
export NAME=$(az vm list-ip-addresses -g ${RG} --output table | awk '{print $1,$2}' | egrep -v 'Public|----')

# here we get the lab station password
PASSWD=$(grep VM_PASSWD_${COURSE} /home/$USER/az_config/class.cfg | cut -d "=" -f 2 | tr -d \'\")

# now we set the password
export SSHPASS=${PASSWD}

# here we are setting the options for ssh and scp commands used in various scripts
export SCP="sshpass -e scp -o StrictHostKeyChecking=no"
export SSH="sshpass -e ssh -o StrictHostKeyChecking=no"

# here we will either setup or remove guacamole
case $1 in
setup)
# this is where we deploy guacamole
	for server in ${IP};
	do echo $server &&
		$SCP /home/$USER/bin/guac tux@${server}:/home/tux/bin/ && 
		$SSH tux@${server} bash /home/tux/bin/guac setup
        done
	echo "Your lab password is:"
        echo "${PASSWD}"
	echo "Your server IP's are:"
        echo "${NAME}"
	echo
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
