#!/bin/bash
# this script will add the azure lab vm's to your local /etc/hosts file
#
# we use the command "az vm list-ip-addresses --output table | awk '{print $2,$1}' | egrep -v 'Public|----'#" to get a list of stations and add the station names to our local /etc/hosts file
#

if [ -z "$1" ]
then
	usage
fi

usage () {
        echo
        echo "USAGE: $0 <MODE>"
        echo
        echo "When running this script, you need to supply 1 argument"
        echo
        echo "<MODE> will be either "add" to append the station names to your local /etc/hosts file"
	echo 
	echo "or "remove" to delete the station names for your local /etc/hosts file"
	echo
        echo "Please re-run the command with the proper argument"
        echo
        echo "EXAMPLE COMMAND: $0 add / $0 remove"
        echo
}

case $1 in
add) 
# the first step is to back up your /etc/hosts file
sudo cp /etc/hosts /etc/hosts-pre_class
# now we need to get a list of stations from azure
az vm list-ip-addresses --output table | awk '{print $2,$1}' | egrep -v 'Public|----' | sudo tee -a /etc/hosts
	;;
remove)
# now we restore /etc/hosts back to its original state
sudo cp /etc/hosts-pre_class /etc/hosts
	;;
*)
	echo 
	usage
	exit
	;;
esac
