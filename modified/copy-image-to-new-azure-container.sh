#!/bin/bash
#
# Version: 1.1.0
# Date: 2024-11-14

usage() {
  echo
  echo "USAGE: ${0} <source_storage_account>:<container>:<file> <destination_storage_account>:<container>[:<file>] [watch]"
  echo
}

display_help() {
  echo
  echo "This command enables you to easily copy an file (blob) from one Azure Storage Container to another using the 'az storage' command."
  echo
  echo "You must provide the source file as the first argument in the format."
  echo " <source_storage_account>:<container>:<file>"
  echo
  echo "You must provide the destination as the second argument in the format:"
  echo " <destination_storage_account>:<file_share>"
  echo "Or "
  echo " <destination_storage_account>:<file_share>:<new_file_name>"
  echo "(If the destination file name is not provided it will be named the same as the source file.)"
  echo
  echo "Where the storage account name, the container name the file share name are separated by a colon (:)."
  echo
  echo "The Storage Account Access Key must either be stored in "
  echo "the environment variable: AZURE_STORAGE_KEY"
  echo " Or "
  echo "In a file in your current working directory named: azure_storage_key.txt"
  echo
  echo "To watch the progress until completion supply as the third argument to the command: watch"
  echo

}

check_cli_args() {
  if [ -z ${1} ]
  then
    echo
    echo "ERROR: No Storage Account, Countainer or File Share. Exiting."
    #echo "ERROR: No source files directory provided. Exiting."
    echo
    usage
    echo
    exit
  else
    case ${1} in
      -h|-H|--help)
        display_help
        usage
        echo
        exit
      ;;
      *)
        if echo ${1} | grep -q ":"
        then
          export SOURCE_STORAGE_ACCOUNT="$(echo ${1} | cut -d : -f 1)"
          export SOURCE_STORAGE_CONTAINER="$(echo ${1} | cut -d : -f 2)"
          export SOURCE_FILE="$(echo ${1} | cut -d : -f 3)"
        else
          echo 
          echo "ERROR: Source Storage Account, Container and File Share not provided in the correct format. Exiting."
          echo
          usage
          exit
        fi
      ;;
    esac
  fi

  if [ -z ${2} ]
  then
    echo
    echo "ERROR: No Destination Storage Account, Course and File Share provided. Exiting."
    echo
    usage
    echo
    exit
  else
    if echo ${2} | grep -q ":"
    then
      export DESTINATION_STORAGE_ACCOUNT="$(echo ${2} | cut -d : -f 1)"
      export DESTINATION_STORAGE_CONTAINER="$(echo ${2} | cut -d : -f 2)"
      export DESTINATION_FILE="$(echo ${2} | cut -d : -f 3)"
    else
      echo 
      echo "ERROR: Storage Account, Container and File Share not provided in the correct format. Exiting."
      echo
      usage
      exit
    fi
  fi

  if [ -z ${SOURCE_STORAGE_ACCOUNT} ]
  then
    echo
    echo "ERROR: No Source Storage Account provided. Exiting."
    echo
    usage
    exit
  fi

  if [ -z ${SOURCE_STORAGE_CONTAINER} ]
  then
    echo
    echo "ERROR: No Source Storage Container provided. Exiting."
    echo
    usage
    exit
  fi

  if [ -z ${SOURCE_FILE} ]
  then
    echo
    echo "ERROR: No Source File provided. Exiting."
    echo
    usage
    exit
  fi

  if [ -z ${DESTINATION_STORAGE_ACCOUNT} ]
  then
    echo
    echo "ERROR: No Destination Storage Account provided. Exiting."
    echo
    usage
    exit
  fi

  if [ -z ${DESTINATION_STORAGE_CONTAINER} ]
  then
    echo
    echo "ERROR: No Destination Storage Container provided. Exiting."
    echo
    usage
    exit
  fi

  if [ -z ${DESTINATION_FILE} ]
  then
    DESTINATION_FILE=${SOURCE_FILE}
  fi

  SOURCE_URI="https://${SOURCE_STORAGE_ACCOUNT}.blob.core.windows.net/${SOURCE_STORAGE_CONTAINER}/${SOURCE_FILE}"
}

check_storage_key() {
  if [ -z ${AZURE_STORAGE_KEY} ]
  then
    if [ -e ./azure_storage_key.txt ]
    then
      echo "Retrieving destination storage key from file: ./azure_storage_key.txt"
      echo
      export AZURE_STORAGE_KEY="$(cat ./azure_storage_key.txt)"
      if [ -z ${AZURE_STORAGE_KEY} ]
      then
        echo "Retrieval from file faild.  Trying a different way ..."
        echo
      else
        echo "Destination storage key retrieved ( ${AZURE_STORAGE_KEY} )"
        echo
      fi
    fi
  fi

  if [ -z ${AZURE_STORAGE_KEY} ]
  then
    echo "Retrieving destination storage key from API"
    echo
    export AZURE_STORAGE_KEY="$(az storage account keys list --account-name ${DESTINATION_STORAGE_ACCOUNT} --output table 2> /dev/null | grep "key1" | awk '{ print $4 }')"
    if [ -z ${AZURE_STORAGE_KEY} ]
    then
      export AZURE_STORAGE_KEY="$(az storage account keys list --account-name ${DESTINATION_STORAGE_ACCOUNT} --output table 2> /dev/null | grep "key1" | awk '{ print $3 }')"
    fi
    echo
    if ! [ -z ${AZURE_STORAGE_KEY} ]
    then
    echo "Destination storage key retrieved ( ${AZURE_STORAGE_KEY} )"
    else
      echo "ERROR: Failed to retrieve destination storage key. Exiting."
      echo
      exit 1
    fi
    echo
  fi

  if [ -z ${SOURCE_AZURE_STORAGE_KEY} ]
  then
    if [ -e ./source_azure_storage_key.txt ]
    then
      echo "Retrieving source storage key from file: ./source_azure_storage_key.txt"
      echo
      export SOURCE_AZURE_STORAGE_KEY="$(cat ./source_azure_storage_key.txt)"
      if [ -z ${SOURCE_AZURE_STORAGE_KEY} ]
      then
        echo "Retrieval from file faild.  Trying a different way ..."
        echo
      else
        echo "Source storage key retrieved ( ${SOURCE_AZURE_STORAGE_KEY} )"
        echo
      fi
    fi
  fi

  if [ -z ${SOURCE_AZURE_STORAGE_KEY} ]
  then
    echo "Retrieving source storage key from API"
    echo
    export SOURCE_AZURE_STORAGE_KEY="$(az storage account keys list --account-name ${SOURCE_STORAGE_ACCOUNT} --output table 2> /dev/null | grep "key1" | awk '{ print $4 }')"
    if [ -z ${SOURCE_AZURE_STORAGE_KEY} ]
    then
      export SOURCE_AZURE_STORAGE_KEY="$(az storage account keys list --account-name ${SOURCE_STORAGE_ACCOUNT} --output table 2> /dev/null | grep "key1" | awk '{ print $3 }')"
    fi
    if ! [ -z ${SOURCE_AZURE_STORAGE_KEY} ]
    then
    echo "Source storage key retrieved ( ${SOURCE_AZURE_STORAGE_KEY} )"
    else
      echo "ERROR: Failed to retrieve source storage key. Exiting."
      echo
      exit 1
    fi
    echo
  fi
}

copy_blob_to_new_container() {
  echo "COMMAND: az storage blob copy start --account-name ${DESTINATION_STORAGE_ACCOUNT} --account-key ${AZURE_STORAGE_KEY} --destination-container ${DESTINATION_STORAGE_CONTAINER} --destination-blob ${DESTINATION_FILE} --source-account-name ${SOURCE_STORAGE_ACCOUNT} --source-account-key ${SOURCE_STORAGE_ACCOUNT_KEY} --source-container ${SOURCE_STORAGE_CONTAINER} --source-blob ${SOURCE_FILE}"
echo
az storage blob copy start \
  --account-name ${DESTINATION_STORAGE_ACCOUNT} \
  --account-key ${AZURE_STORAGE_KEY} \
  --destination-container ${DESTINATION_STORAGE_CONTAINER} \
  --destination-blob ${DESTINATION_FILE} \
  --source-account-name ${SOURCE_STORAGE_ACCOUNT} \
  --source-account-key ${SOURCE_AZURE_STORAGE_KEY} \
  --source-container ${SOURCE_STORAGE_CONTAINER} \
  --source-blob ${SOURCE_FILE}
echo
}

display_blob_copy_status_watch() {
    TOTAL_BLOB_SIZE=$(az storage blob show --account-name ${DESTINATION_STORAGE_ACCOUNT} --account-key ${AZURE_STORAGE_KEY} --container-name ${DESTINATION_STORAGE_CONTAINER} --name ${DESTINATION_FILE} --query '{progress:properties.copy.progress}' --output table | grep '/' | cut -d '/' -f2)
  #
  # this variable is the amount that has been copied to the new storage container
  TRANSFERRED_BLOB_SIZE=$(az storage blob show --account-name ${DESTINATION_STORAGE_ACCOUNT} --account-key ${AZURE_STORAGE_KEY} --container-name ${DESTINATION_STORAGE_CONTAINER} --name ${DESTINATION_FILE} --query '{progress:properties.copy.progress}' --output table | grep '/' | cut -d '/' -f1)
  #
  # now we are going to compare the amount copied with the total amount and wait for the copy to complete
  until [ "${TRANSFERRED_BLOB_SIZE}" = "${TOTAL_BLOB_SIZE}" ];
  do
    TRANSFERRED_BLOB_SIZE=$(az storage blob show --account-name ${DESTINATION_STORAGE_ACCOUNT} --account-key ${AZURE_STORAGE_KEY} --container-name ${DESTINATION_STORAGE_CONTAINER} --name ${DESTINATION_FILE} --query '{progress:properties.copy.progress}' --output table | grep '/' | cut -d '/' -f1)
    printf "\r Copied %2d of ${TOTAL_BLOB_SIZE}" ${TRANSFERRED_BLOB_SIZE}
    sleep 5
  done
  echo
  echo -e "${LTBLUE}Copy Complete${NC}"
  echo
}

##############################################################################

main() {
  check_cli_args ${1} ${2}
  check_storage_key ${1} ${2}

  #az login
  
  copy_blob_to_new_container
  
# echo "To see the status of the copy, run the following command:"
# echo
# echo "./show-image-copy-status.sh ${DESTINATION_STORAGE_ACCOUNT}:${DESTINATION_STORAGE_CONTAINER}:${DESTINATION_FILE}"
# echo
  case ${3} in
    watch)
      display_blob_copy_status_watch
    ;;
  esac

}

##############################################################################

main $*

