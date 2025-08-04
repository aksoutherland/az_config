#!/bin/bash
# this script will start the Management vm for the deployed lab environment
# the first thing we need to do is grab the course ID
COURSE=$1

usage () {
        echo
        echo "USAGE: $0 <COURSE>"
        echo
        echo "When running this script, you need to supply 1 arguments"
        echo
        echo "This argument should be course_id"
        echo
        echo "EXAMPLE COMMAND: $0 sle201"
        echo
}

if [ -z "$1" ]
then
        echo "You are missing the Course ID"
        usage
        exit
fi

# here we set the region
REGION="centralus"

# here we get the resource group name
export RG=$(az group list -o table | grep ${COURSE}-${REGION} | cut -d " " -f1)

# now we set the ssh passwd
export SSHPASS=$(grep VM_PASSWD_${COURSE} /home/$USER/az_config/class.cfg | cut -d "=" -f 2 | tr -d \'\")

# here we make the course ID uppercase
export NEWCOURSE=$(echo ${COURSE} | sed 's[a-z]/\U&/g')

# and finally this section will connect to the lab environment and start the mgmt vm
for i in $(az vm list-ip-addresses -g ${RG} --output table | egrep -v 'Public|----' | awk -F '-' '{print $2,$1}' | awk '{print $1}'); 
do sshpass -e ssh -o StrictHostKeyChecking=no tux@$i virsh start ${NEWCOURSE}-management; 
done
