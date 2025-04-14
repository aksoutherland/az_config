#!/bin/bash
#
# version: 1.1.2
# date: 2022-05-02

######### Default Values #################
DEF_REGION_LIST="centralus"
DEF_IMAGE_SOURCE_RESOURCE_GROUP="trainingimages"
DEF_IMAGE_SOURCE_STORAGE_ACCOUNT="labmachineimagetraining"
DEF_IMAGE_SOURCE_CONTAINER_NAME="vhds"
DEF_COURSE_STORAGE_CONTAINER_NAME="vhds"
#DEF_COURSE_STORAGE_CONTAINER_NAME="course-disks"
##########################################

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

usage() {
  echo
  echo "USAGE: ${0} <course_config_file> [copy-template-vhd]"
  echo
  echo "       If you would like to also copy the temaple vhd file into the new"
  echo "       storage account container, enter as the second option to the command:"
  echo
  echo "        copy-template-vhd"
  echo
}

if [ -z "${1}" ]
then
  echo -e "${RED}ERROR. You must supply a course config file. Exiting.${NC}"
  echo
  usage
  exit
else
  COURSE_CONFIG_FILE=${1}
  if ! [ -e ${COURSE_CONFIG_FILE} ]
  then
    echo -e "${RED}ERROR: The supplied course config file does not seem to exist. Exiting.${NC}"
    echo
    exit
  else
    source ${COURSE_CONFIG_FILE}
  fi
fi

if echo ${*} | grep -q copy-template-vhd
then
  COPY_TEMPLATE_VHD=Y
fi

#############################################################################

set_default_values() {
  if [ -z "${REGION_LIST}" ]
  then
    REGION_LIST="${DEF_REGION_LIST}"
  fi

  if [ -z "${IMAGE_SOURCE_RESOURCE_GROUP}" ]
  then
    IMAGE_SOURCE_RESOURCE_GROUP="${DEF_IMAGE_SOURCE_RESOURCE_GROUP}"
  fi

  if [ -z "${IMAGE_SOURCE_STORAGE_ACCOUNT}" ]
  then
    IMAGE_SOURCE_STORAGE_ACCOUNT="${DEF_IMAGE_SOURCE_STORAGE_ACCOUNT}"
  fi

  if [ -z "${IMAGE_SOURCE_CONTAINER_NAME}" ]
  then
    IMAGE_SOURCE_CONTAINER_NAME="${DEF_IMAGE_SOURCE_CONTAINER_NAME}"
  fi

  if [ -z "${COURSE_STORAGE_CONTAINER_NAME}" ]
  then
    COURSE_STORAGE_CONTAINER_NAME="${DEF_COURSE_STORAGE_CONTAINER_NAME}"
  fi
}

create_new_resource_group() {
  echo -e "${LTBLUE}Creating new resource group named: ${GRAY}${COURSE_RESOURCE_GROUP_BASE_NAME}-${REGION}${NC}"
  az group create \
    -l ${REGION} \
    -n ${COURSE_RESOURCE_GROUP_BASE_NAME}-${REGION}
  echo
}

create_new_storage_account() {
  echo -e "${LTBLUE}Creating new storage account named: ${GRAY}${COURSE_STORAGE_ACCOUNT_BASE_NAME}${REGION}${NC}"
  az storage account create \
    -n ${COURSE_STORAGE_ACCOUNT_BASE_NAME}${REGION} \
    -g ${COURSE_RESOURCE_GROUP_BASE_NAME}-${REGION} \
    -l ${REGION} \
    --kind Storagev2 \
    --sku Premium_LRS
  echo
}

create_new_storage_container() {
  echo -e "${LTBLUE}Creating new container for course disks named: ${GRAY}${COURSE_STORAGE_CONTAINER_NAME}${NC}"
  az storage container create \
    --account-name ${COURSE_STORAGE_ACCOUNT_BASE_NAME}${REGION} \
    --name ${COURSE_STORAGE_CONTAINER_NAME} 
  
  az storage container create \
    --account-name ${COURSE_STORAGE_ACCOUNT_BASE_NAME}${REGION} \
    --name vhds
  echo
}


copy_source_disk_image() {
  echo -e "${LTBLUE}Copying the source course disk into the new course container ...${NC}"
  echo -e "${LTBLUE}(This will take a while, please be patient)${NC}"
  echo

  local IMAGE_SOURCE_STORAGE_KEY=$(az storage account keys list --resource-group ${IMAGE_SOURCE_RESOURCE_GROUP} --account-name ${IMAGE_SOURCE_STORAGE_ACCOUNT} --output table 2> /dev/null | grep key1 | awk '{ print $4 }')
  if [ -z ${IMAGE_SOURCE_STORAGE_KEY} ]
  then
    local IMAGE_SOURCE_STORAGE_KEY=$(az storage account keys list --resource-group ${IMAGE_SOURCE_RESOURCE_GROUP} --account-name ${IMAGE_SOURCE_STORAGE_ACCOUNT} --output table 2> /dev/null | grep key1 | awk '{ print $3 }')
  fi

  local REGION_COURSE_STORAGE_KEY=$(az storage account keys list --resource-group ${COURSE_RESOURCE_GROUP_BASE_NAME}-${REGION} --account-name ${COURSE_STORAGE_ACCOUNT_BASE_NAME}${REGION} --output table 2> /dev/null | grep key1 | awk '{ print $4 }')
  if [ -z ${REGION_COURSE_STORAGE_KEY} ]
  then
    local REGION_COURSE_STORAGE_KEY=$(az storage account keys list --resource-group ${COURSE_RESOURCE_GROUP_BASE_NAME}-${REGION} --account-name ${COURSE_STORAGE_ACCOUNT_BASE_NAME}${REGION} --output table 2> /dev/null | grep key1 | awk '{ print $3 }')
  fi

  
  az storage blob copy start \
    --source-account-name ${IMAGE_SOURCE_STORAGE_ACCOUNT} \
    --source-account-key ${IMAGE_SOURCE_STORAGE_KEY} \
    --source-container ${IMAGE_SOURCE_CONTAINER_NAME} \
    --source-blob ${IMAGE_SOURCE_IMAGE_FILE} \
    --account-name ${COURSE_STORAGE_ACCOUNT_BASE_NAME}${REGION} \
    --account-key ${REGION_COURSE_STORAGE_KEY} \
    --destination-container ${COURSE_STORAGE_CONTAINER_NAME} \
    --destination-blob ${IMAGE_SOURCE_IMAGE_FILE} \
    --query '{jobID:id}' --output table
    
  #echo
  #echo -e "${ORANGE}TIP: The image file copy is happening in the background.${NC}"
  #echo
  #echo -e "${ORANGE}     You can watch the progress of the image file copy job by${NC}"
  #echo -e "${ORANGE}     running the following command:${NC}"
  #echo
  #echo -e "${NC}    watch az storage blob show \ ${NC}"
  #echo -e "${NC}      --account-name ${COURSE_STORAGE_ACCOUNT_BASE_NAME}${REGION} \ ${NC}"
  #echo -e "${NC}      --account-key ${REGION_COURSE_STORAGE_KEY} \ ${NC}"
  #echo -e "${NC}      -c ${COURSE_STORAGE_CONTAINER_NAME} \ ${NC}"
  #echo -e "${NC}      -n ${IMAGE_SOURCE_IMAGE_FILE} \ ${NC}"
  #echo -e "${NC}      --query \'progress:properties.copy.progress}\' \ ${NC}"
  #echo -e "${NC}      --output table${NC}"
  #echo 
  #echo -e "${LTPURPLE}     (Ctrl+c quits the command)${NC}"
  #echo
  #echo -e "${ORANGE}     Or you can use the command:${NC}"
  #echo
  #echo -e "${NC}     ./show-image-copy-status.sh ${COURSE_STORAGE_ACCOUNT_BASE_NAME}${REGION}:${COURSE_STORAGE_CONTAINER_NAME}:${IMAGE_SOURCE_IMAGE_FILE}${NC}"
  #echo 

  # commenting out this command so that we can use the section below instead
  #  watch az storage blob show \
  #          --account-name ${COURSE_STORAGE_ACCOUNT_BASE_NAME}${REGION} \
  #          --account-key ${REGION_COURSE_STORAGE_KEY} \
  #          -c ${COURSE_STORAGE_CONTAINER_NAME} \
  #          -n ${IMAGE_SOURCE_IMAGE_FILE} \
  #          --query \'{progress:properties.copy.progress}\' \
  #          --output table

  #
  # here we are going to create 2 variables
  #
  # this variable is the total size of the source disk image to copy to the new storage container
  TOTAL_BLOB_SIZE=$(az storage blob show --account-name ${COURSE_STORAGE_ACCOUNT_BASE_NAME}${REGION} --account-key ${REGION_COURSE_STORAGE_KEY} --container-name ${COURSE_STORAGE_CONTAINER_NAME} --name ${IMAGE_SOURCE_IMAGE_FILE} --query '{progress:properties.copy.progress}' --output table | grep '/' | cut -d '/' -f2)
  #
  # this variable is the amount that has been copied to the new storage container
  TRANSFERRED_BLOB_SIZE=$(az storage blob show --account-name ${COURSE_STORAGE_ACCOUNT_BASE_NAME}${REGION} --account-key ${REGION_COURSE_STORAGE_KEY} --container-name ${COURSE_STORAGE_CONTAINER_NAME} --name ${IMAGE_SOURCE_IMAGE_FILE} --query '{progress:properties.copy.progress}' --output table | grep '/' | cut -d '/' -f1)
  #
  # now we are going to compare the amount copied with the total amount and wait for the copy to complete
  echo -e "${LTBLUE}Waiting for the template disk to copy to the new storage container${NC}"
  until [ "${TRANSFERRED_BLOB_SIZE}" = "${TOTAL_BLOB_SIZE}" ];
  do 
    TRANSFERRED_BLOB_SIZE=$(az storage blob show --account-name ${COURSE_STORAGE_ACCOUNT_BASE_NAME}${REGION} --account-key ${REGION_COURSE_STORAGE_KEY} --container-name ${COURSE_STORAGE_CONTAINER_NAME} --name ${IMAGE_SOURCE_IMAGE_FILE} --query '{progress:properties.copy.progress}' --output table | grep '/' | cut -d '/' -f1)
    printf "\r Copied %2d of ${TOTAL_BLOB_SIZE}" ${TRANSFERRED_BLOB_SIZE}
    sleep 5
  done
  echo
  echo -e "${LTBLUE}Copy Complete${NC}"
  echo

}


############################################################################

main() {
  echo -e "${LTBLUE}===========================================================================${NC}"
  echo -e "${LTBLUE}               Creating new course environment in Azure${NC}"
  echo -e "${LTBLUE}===========================================================================${NC}"
  echo

  set_default_values

  for REGION in ${REGION_LIST}
  do
    echo -e "${LTBLUE}---------------------${NC}"
    echo -e "${LTBLUE}Region: ${GRAY}${REGION}${NC}"
    echo -e "${LTBLUE}---------------------${NC}"
    echo

    create_new_resource_group
    create_new_storage_account
    create_new_storage_container
    copy_source_disk_image

    case ${COPY_TEMPLATE_VHD} in
      Y)
        copy_source_disk_image
      ;;
    esac

    echo
    echo -e "${LTBLUE}---------------------------------------------------------------------------${NC}"
    echo
  done
}

############################################################################

time main ${*}

