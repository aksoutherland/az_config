#!/bin/bash
#
# Version: 1.3.1
# Date: 2022-05-25

######### Default Values #################
DEFAULT_CLI_ARGS="--use-unmanaged-disk --public-ip-sku Standard"
DEFAULT_OS_TYPE="linux"
DEFAULT_NAME="MyVM"
DEFAULT_SIZE="Standard_D4s_v3"
DEFAULT_VM_DISK_SIZE="256"
DEFAULT_REGION="westus"
DEFAULT_AUTH_TYPE="password"
DEFAULT_ADMIN_USERNAME="tux"
DEFAULT_ADMIN_PASSWORD="d3faul7P@s5w0rd"
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
  echo "Usage: ${0} <vm_config_file>"
  echo
}

if [ -z ${1} ]
then
  usage
  exit 0
fi

if [ -e ${1} ]
then
  CONFIG_FILE=${1}
  EXE_PATH=$(dirname ${0})

  source ${CONFIG_FILE}

else
  echo -e "${RED}ERROR: The VM config file specified does not exist. Exiting.${NC}"
  exit 1
fi

#############################################################################

get_cli_args() {
  CLI_ARGS=${DEFAULT_CLI_ARGS}

  if ! [ -z ${REGION} ]
  then
    CLI_ARGS="${CLI_ARGS} --location ${REGION}"
  else
    REGION=${DEFAULT_REGION}
    CLI_ARGS="${CLI_ARGS} --location ${DEFAULT_REGION}"
  fi

  if ! [ -z ${RESOURCE_GROUP} ]
  then
    CLI_ARGS="${CLI_ARGS} --resource-group ${RESOURCE_GROUP}"
  else
    echo -e "${RED}ERROR: You must provide a resource group for the new VM. Exiting.${NC}"
    echo
    exit 1
  fi

  if ! [ -z ${OS_TYPE} ]
  then
    CLI_ARGS="${CLI_ARGS} --os-type ${OS_TYPE}"
  else
    OS_TYPE=${DEFAULT_OS_TYPE}
    CLI_ARGS="${CLI_ARGS} --os-type ${DEFAULT_OS_TYPE}"
  fi

  if ! [ -z ${VM_NAME} ]
  then
    CLI_ARGS="${CLI_ARGS} --name ${VM_NAME}"
  else
    VM_NAME=${DEFAULT_VM_NAME}
    CLI_ARGS="${CLI_ARGS} --name ${DEFAULT_VM_NAME}"
  fi

  if ! [ -z ${VM_SIZE} ]
  then
    CLI_ARGS="${CLI_ARGS} --size ${VM_SIZE}"
  else
    SIZE=${DEFAULT_SIZE}
    CLI_ARGS="${CLI_ARGS} --size ${DEFAULT_SIZE}"
  fi

  if ! [ -z ${SOURCE_IMAGE_URI} ]
  then
    CLI_ARGS="${CLI_ARGS} --image ${SOURCE_IMAGE_URI}"
  else
    echo -e " ${RED}ERROR: You must provide a source image. Exiting${NC}"
    echo
    exit 1
  fi

  CLI_ARGS="${CLI_ARGS} --os-disk-name ${VM_NAME}-disk"

  if ! [ -z ${VM_DISK_SIZE} ]
  then
    CLI_ARGS="${CLI_ARGS} --os-disk-size ${VM_DISK_SIZE}"
  fi

  case ${EPHEMERAL_OS_DISK} in
    true|TRUE|yes|Yes|YES)
      CLI_ARGS="${CLI_ARGS} --ephemeral-os-disk true --os-disk-caching ReadOnly"
    ;;
    *)
      if ! [ -z ${STORAGE_ACCOUNT} ]
      then
        CLI_ARGS="${CLI_ARGS} --storage-account ${STORAGE_ACCOUNT}"
      else
        echo -e "${RED}ERROR: You must provide a storage account for the new disk image. Exiting.${NC}"
        echo
        exit 1
      fi
  
      if ! [ -z ${STORAGE_CONTAINER_NAME} ]
      then
        CLI_ARGS="${CLI_ARGS} --storage-container-name ${STORAGE_CONTAINER_NAME}"
      else
        STORAGE_CONTAINER_NAME=${DEFAULT_STORAGE_CONTAINER_NAME}
        CLI_ARGS="${CLI_ARGS} --storage-container-name course-disks"
      fi
    ;;
  esac

  if ! [ -z ${AUTH_TYPE} ]
  then
    CLI_ARGS="${CLI_ARGS} --authentication-type ${AUTH_TYPE}"
  else
    AUTH_TYPE=${DEFAULT_AUTH_TYPE}
    CLI_ARGS="${CLI_ARGS} --authentication-type ${DEFAULT_AUTH_TYPE}"
  fi

  if ! [ -z ${ADMIN_USERNAME} ]
  then
    CLI_ARGS="${CLI_ARGS} --admin-username ${ADMIN_USERNAME}"
  else
    ADMIN_USERNAME=${DEFAULT_ADMIN_USERNAME}
    CLI_ARGS="${CLI_ARGS} --admin-username ${DEFAULT_ADMIN_USERNAME}"
  fi

  case ${AUTH_TYPE} in
    password)
      if ! [ -z ${ADMIN_PASSWORD} ]
      then
        CLI_ARGS="${CLI_ARGS} --admin-password ${ADMIN_PASSWORD}"
      else
	ADMIN_PASSWORD=${DEFAULT_ADMIN_PASSWORD}
        CLI_ARGS="${CLI_ARGS} --admin-password ${DEFAULT_ADMIN_PASSWORD}"
      fi
    ;;
    ssh)
      if ! [ -z ${SSH_KEY_LIST} ]
      then
        CLI_ARGS="${CLI_ARGS} --ssh-key-values \"${SSH_KEY_LIST}\""
      else
        echo -e "${RED}ERROR: The authentication type is set to ssh. You must supply at least one public ssh key. Exiting${NC}"
        echo
        exit 1
      fi
    ;;
    all)
      if ! [ -z ${ADMIN_PASSWORD} ]
      then
        CLI_ARGS="${CLI_ARGS} --admin-password ${ADMIN_PASSWORD}"
      else
	ADMIN_PASSWORD=${DEFAULT_ADMIN_PASSWORD}
        CLI_ARGS="${CLI_ARGS} --admin-password ${DEFAULT_ADMIN_PASSWORD}"
      fi

      if ! [ -z ${SSH_KEY_LIST} ]
      then
        CLI_ARGS="${CLI_ARGS} --ssh-key-values \"${SSH_KEY_LIST}\""
      else
        echo -e "${RED}ERROR: The authentication type is set to all. You must supply at least one public ssh key. Exiting${NC}"
        echo
        exit 1
      fi
    ;;
  esac

  CLI_ARGS="${CLI_ARGS} ${ADDITIIONAL_CLI_ARGS}"
}

enable_ssh() {
  case ${ENABLE_SSH} in
    true|TRUE|yes|YES)
      echo -e "${LTBLUE}Enabling SSH:${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY}az vm open-port --resource-group ${RESOURCE_GROUP} --name ${VM_NAME} --port 22${NC}"
      az vm open-port --resource-group ${RESOURCE_GROUP} --name ${VM_NAME} --port 22 > /dev/null
      echo
      REMOTE_ACCESS="${REMOTE_ACCESS},SSH"
      REMOTE_ACCESS_PORTS="${REMOTE_ACCESS_PORTS} 22"
    ;;
  esac
}

enable_rdp() {
  case ${ENABLE_RDP} in
    true|TRUE|yes|YES)
      echo -e "${LTBLUE}Enabling RDP:${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY}az vm open-port --resource-group ${RESOURCE_GROUP} --name ${VM_NAME} --port 3389${NC}"
      az vm open-port --resource-group ${RESOURCE_GROUP} --name ${VM_NAME} --port 3389 > /dev/null
      echo
      REMOTE_ACCESS="${REMOTE_ACCESS},RDP"
      REMOTE_ACCESS_PORTS="${REMOTE_ACCESS_PORTS} 3389"
    ;;
  esac
}

open_additional_ports() {
  if ! [ -z ${ADDITIONAL_OPEN_PORTS} ]
  then
    echo -e "${LTBLUE}Opening Additional Ports:${NC}"
    for PORT in ${ADDITIONAL_OPEN_PORTS}
    do
      echo -e "${LTGREEN}COMMAND: ${GRAY}az vm open-port --resource-group ${RESOURCE_GROUP} --name ${VM_NAME} --port ${PORT}${NC}"
      az vm open-port --resource-group ${RESOURCE_GROUP} --name ${VM_NAME} --port ${PORT} --priority 1010 > /dev/null 2>&1
    done
    echo
  fi
}

############################################################################

main() {
  get_cli_args $*
  echo 
  echo -e "${LTBLUE}=======================================================================${NC}"
  echo -e "${LTBLUE}                Creating Azure VM ${GRAY}${VM_NAME}${NC}"
  echo -e "${LTBLUE}=======================================================================${NC}"
  echo
  echo -e "${LTBLUE}Creating VM:${NC}"

  TMP_OUTPUT_FILE="/tmp/create-azure-vm.output.$$"
  TMP_ERROR_FILE="/tmp/create-azure-vm.error.$$"
  echo -e "${LTGREEN}COMMAND: ${GRAY}az vm create ${CLI_ARGS}${NC}"
  az vm create ${CLI_ARGS} > ${TMP_OUTPUT_FILE} 2> ${TMP_ERROR_FILE}

  case ${?} in
    0)
      if [ -e ${TMP_OUTPUT_FILE} ]
      then
        FQDNS=$(grep "fqdns" ${TMP_OUTPUT_FILE} | cut -d \" -f 4)
        ID=$(grep id ${TMP_OUTPUT_FILE} | cut -d \" -f 4)
        POWER_STATE=$(grep powerState ${TMP_OUTPUT_FILE} | cut -d \" -f 4)
        MAC_ADDR=$(grep macAddress ${TMP_OUTPUT_FILE} | cut -d \" -f 4)
        PRIVATE_IP_ADDR=$(grep privateIpAddress ${TMP_OUTPUT_FILE} | cut -d \" -f 4)
        PUBLIC_IP_ADDR=$(grep publicIpAddress ${TMP_OUTPUT_FILE} | cut -d \" -f 4)
        ZONES=$(grep zones ${TMP_OUTPUT_FILE} | cut -d \" -f 4)
    
        rm ${TMP_OUTPUT_FILE}
        rm ${TMP_ERROR_FILE}
        echo
   
        case ${OS_TYPE} in
          linux)
            REMOTE_ACCESS="SSH"
            REMOTE_ACCESS_PORTS="22"
            enable_rdp
          ;;
          windows)
            REMOTE_ACCESS="RDP"
            REMOTE_ACCESS_PORTS="3389"
            enable_ssh
          ;;
        esac
   
        open_additional_ports

        echo -e "${LTBLUE}=======================================================================${NC}"
        echo
        echo -e "${LTBLUE}+----------------------------------------------------------------------${NC}"
        echo -e "${LTBLUE}|                             VM Info:${NC}"
        echo -e "${LTBLUE}+----------------------------------------------------------------------${NC}"
        echo -e "${LTBLUE}| ${LTPURPLE}VM Name:            ${GRAY}${VM_NAME}${NC}"
        echo -e "${LTBLUE}| ${LTPURPLE}OS Type:            ${GRAY}${OS_TYPE}${NC}"
        echo -e "${LTBLUE}| ${LTPURPLE}Ephemeral OS Disk:  ${GRAY}${EPHEMERAL_OS_DISK}${NC}"
        echo -e "${LTBLUE}| ${LTPURPLE}MAC Address:        ${GRAY}${MAC_ADDR}${NC}"
        echo -e "${LTBLUE}| ${LTPURPLE}Private IP Address: ${GRAY}${PRIVATE_IP_ADDR}${NC}"
        echo -e "${LTBLUE}| ${LTPURPLE}Open Ports:         ${GRAY}${REMOTE_ACCESS_PORTS} ${ADDITIONAL_OPEN_PORTS}${NC}"
        echo -e "${LTBLUE}| ${LTPURPLE}Region:             ${GRAY}${REGION}${NC}"
        echo -e "${LTBLUE}| ${LTPURPLE}Zones:              ${GRAY}${ZONES}${NC}"
        echo -e "${LTBLUE}| ${LTPURPLE}Resource Group:     ${GRAY}${RESOURCE_GROUP}${NC}"
        echo -e "${LTBLUE}| "
        echo -e "${LTBLUE}| ${ORANGE}You can access the VM using the following:${NC}"
        echo -e "${LTBLUE}| ${LTPURPLE}Protocols:          ${GRAY}${REMOTE_ACCESS}${NC}"
        echo -e "${LTBLUE}| ${LTPURPLE}Public IP Address:  ${GRAY}${PUBLIC_IP_ADDR}${NC}"
        echo -e "${LTBLUE}| ${LTPURPLE}Username:           ${GRAY}${ADMIN_USERNAME}${NC}"
        echo -e "${LTBLUE}| ${LTPURPLE}Password:           ${GRAY}${ADMIN_PASSWORD}${NC}"
        echo -e "${LTBLUE}+----------------------------------------------------------------------${NC}"
        echo
        echo "VM Name:            ${VM_NAME}" > $(dirname ${CONFIG_FILE})/${VM_NAME}-connection_info.txt
        echo "Protocols:          ${REMOTE_ACCESS}" >> $(dirname ${CONFIG_FILE})/${VM_NAME}-connection_info.txt
        echo "Public IP Address:  ${PUBLIC_IP_ADDR}" >> $(dirname ${CONFIG_FILE})/${VM_NAME}-connection_info.txt
        echo "Username:           ${ADMIN_USERNAME}" >> $(dirname ${CONFIG_FILE})/${VM_NAME}-connection_info.txt
        echo "Password:           ${ADMIN_PASSWORD}" >> $(dirname ${CONFIG_FILE})/${VM_NAME}-connection_info.txt
        echo "" >> $(dirname ${CONFIG_FILE})/${VM_NAME}-connection_info.txt
      fi
    ;;
    *)
      if [ -e ${TMP_ERROR_FILE} ]
      then
        ERROR_MSG=$(grep "message" ${TMP_ERROR_FILE} | cut -d \" -f 4)
    
        rm ${TMP_OUTPUT_FILE}
        rm ${TMP_ERROR_FILE}

        echo
        echo -e "${RED}=======================================================================${NC}"
        echo
        echo -e "${RED}ERROR: ${ERROR_MSG}${NC}"
        echo
        echo -e "${RED}=======================================================================${NC}"
        echo

        sleep 2
        echo -e "${LTBLUE}Cleaning up the failed VM's environment ...${NC}"
        sleep 5
        echo

        bash ${EXE_PATH}/delete-azure-vm.sh ${1}
      fi
    ;;
  esac
}

############################################################################

main ${*}

