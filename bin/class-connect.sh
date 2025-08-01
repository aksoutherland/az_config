#!/bin/bash
# this script will connect you to the  lab vm's
# this is the course that we are working with
COURSE=$1

### Colors ###
RED='\e[0;31m'
LTRED='\e[1;31m'
BLUE='\e[0;34m'
LTBLUE='\e[1;34m'
GREEN='\e[0;32m'
LTGREEN='\e[1;32m'
ORANGE='\e[0;33m'
YELLOW='\e[1;33m'
CYAN='\e[0;36m'
LTCYAN='\e[1;36m'
PURPLE='\e[0;35m'
LTPURPLE='\e[1;35m'
GRAY='\e[1;30m'
LTGRAY='\e[0;37m'
WHITE='\e[1;37m'
NC='\e[0m'
##############

# we need to make sure that we have the newest version of class.cfg so that we have the proper password
FILE1=/home/$USER/az_config/class.cfg
if [ -f ${FILE1} ];
then
        echo -e "${GREEN}class.cfg exists${NC}"
else
        wget https://github.com/aksoutherland/az_config/raw/master/class.cfg -O /home/$USER/az_config/class.cfg
fi

usage () {
	echo
	echo "USAGE: $0 <course>"
	echo
	echo "When running this script, you need to supply 1 arguments,"
	echo
	echo "The only argument you need will specify the "Course" you wish to connect to"
	echo
	echo "Please re-run the command with the proper arguments"
	echo
	echo "EXAMPLE COMMANDS: $0 sle301"
	echo
	echo
}

if [ -z "${COURSE}" ] 
then
	echo
	echo "You are missing the Course ID"
	echo "Please specify either appropriate course"
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

# here we get the lab station password
PASSWD=$(grep VM_PASSWD_${COURSE} /home/$USER/az_config/class.cfg | cut -d "=" -f 2 | tr -d \'\")

# here we show you the password and the stations you will connect to
echo "Your lab password is:"
echo -e "${GREEN}${PASSWD}${NC}"
echo "Your server IP's are:"
echo -e "${GREEN}${NAME}${NC}"

