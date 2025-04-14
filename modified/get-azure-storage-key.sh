#!/bin/bash
#
# Version: 1.0.3
# Date: 2022-11-03

usage() {
  echo
  echo "USAGE: ${0} <storage_account>"
}

get_storage_account() {
  if [ -z ${1} ]
  then
    echo
    echo "ERROR: You must provide a Storage Account name. Exiting."
    echo
    usage
    exit
  else
    export AZURE_STORAGE_ACCOUNT=${1}
  fi
}

get_storage_account_key() {
  local AZURE_STORAGE_ACCOUNT_KEY=$(az storage account keys list --account-name ${AZURE_STORAGE_ACCOUNT} --output table 2> /dev/null | grep "key1" | awk '{ print $4 }')

  if [ -z ${AZURE_STORAGE_ACCOUNT_KEY} ]
  then
    AZURE_STORAGE_ACCOUNT_KEY=$(az storage account keys list --account-name ${AZURE_STORAGE_ACCOUNT} --output table 2> /dev/null | grep "key1" | awk '{ print $3 }')
  fi

  echo ${AZURE_STORAGE_ACCOUNT_KEY} | tee ~/azure_${AZURE_STORAGE_ACCOUNT}_account_key.txt
}

main() {
  get_storage_account $*

  get_storage_account_key
}

main $*
