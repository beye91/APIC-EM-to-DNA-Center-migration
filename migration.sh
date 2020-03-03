#!/bin/bash

# Setting variables
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;36m"
NORM="\033[0m"

timestamp=`date +%Y%m%d-%H-%M-%S`
mkdir -p /tmp/apic-em_migration_logs/${timestamp}
tmp_dir="/tmp/apic-em_migration_logs/${timestamp}"

function help
{
  echo "Usage: migration.sh [-a] [-d] [-h]"
  echo ""
  echo "   -a  APIC-EM IP address"
  echo "   -d  DNA-Center IP address"
  echo "   -h  Help menue"
  echo "   -m  Start migration"  
  echo ""
  echo ""
}

function header
{
  printf "\n"
  printf "\n"
  printf "${BLUE}                                                                                                      ${NORM}\n"
  printf "${BLUE}                         000                                             000                          ${NORM}\n"
  printf "${BLUE}                        00000                                           00000                         ${NORM}\n"
  printf "${BLUE}                        00000                                           00000                         ${NORM}\n"
  printf "${BLUE}                        00000                                           00000                         ${NORM}\n"
  printf "${BLUE}              77        00000        777                     777        00000         77              ${NORM}\n"
  printf "${BLUE}             0000       00000       70004                   80007       00000        0000             ${NORM}\n"
  printf "${BLUE}             0000       00008       70009                   00007       00000        0000             ${NORM}\n"
  printf "${BLUE}             0000       00000       70004         0         80007       00000        0000         00  ${NORM}\n"
  printf "${BLUE} 7002        0000       00000       70002        000        90007       00000        0000        6007 ${NORM}\n"
  printf "${BLUE} 0000        0000       00000       70004       80005       80007       00000        0000        0008 ${NORM}\n"
  printf "${BLUE} 0000        0000       00000       70004       50007       90007       00000        0000        0005 ${NORM}\n"
  printf "${BLUE} 0000        0000       00000       10000       80002       00007       00000        0000        0008 ${NORM}\n"
  printf "${BLUE} 7005        0007       00000        000         000         000        00000         00          00  ${NORM}\n"
  printf "${BLUE}                        00000                                           00000                         ${NORM}\n"
  printf "${BLUE}                        00000                                           00000                         ${NORM}\n"
  printf "${BLUE}                         717                                             717                          ${NORM}\n"
  printf "\n"
  printf "\n"
  printf "${RED}               700000000      0000        700000009         720000000         7600000087               ${NORM}\n"
  printf "${RED}             90000000000      0000       0000000000       700000000007      70000000000002             ${NORM}\n"
  printf "${RED}            0000097  719      0000      00002            10000077 7707     00000077 7900000            ${NORM}\n"
  printf "${RED}           00000              0000      00009           700001            100007       00008           ${NORM}\n"
  printf "${RED}           00007              0000       000000007      80000             00007        70000           ${NORM}\n"
  printf "${RED}           00007              0000        740000000     80000             00007        70000           ${NORM}\n"
  printf "${RED}           00000              0000             40000    700007            60000        00000           ${NORM}\n"
  printf "${RED}            000001     1      0000             10000     0000007    1      0000057   100000            ${NORM}\n"
  printf "${RED}             00000000000      0000      00000000000       100000000007      60000000000008             ${NORM}\n"
  printf "${RED}               775266691      8250      108080457            71249490          714692577               ${NORM}\n"
  printf "\n"
  printf "${YELLOW}                       Author: cbeye Last update:03/03/20                                           ${NORM}\n"
  printf "\n"
  printf "${YELLOW}         Your TMP dir is: ${tmp_dir}                                                                ${NORM}\n"
}

function get_auth_token
{
printf "\n"
printf "\n"
printf "${YELLOW}Welcome to the APIC-EM to DNA Center migration tool${NORM}\n"
printf "\n"
printf "${YELLOW}Lets gather all needed authentication data!${NORM}\n"
printf "\n"
printf "${YELLOW}+++++++++++++++++++++++++++++++++++++++++++++++++++${NORM}\n"
printf "${BLUE}                       APIC-EM                       ${NORM}\n"
printf "${YELLOW}+++++++++++++++++++++++++++++++++++++++++++++++++++${NORM}\n"
read -p "Enter Username: " apicem_username
read -s -p "Enter Password: " apicem_password
printf "\n"
printf "\n"
APIC_EM_TOKEN=`curl --header "Content-Type:application/json" --header "Accept:application/json" -X POST --data '{"username":"'${apicem_username}'","password":"'${apicem_password}'"}' --insecure -s https://${APICIP}/api/v1/ticket 2>&1 | awk -F '"' '{print $6}'`
printf "${YELLOW}Your APIC-EM token is: ${GREEN}${APIC_EM_TOKEN}${NORM}\n"
printf "\n"
printf "\n"
printf "${YELLOW}+++++++++++++++++++++++++++++++++++++++++++++++++++${NORM}\n"
printf "${BLUE}                        DNA-C                        ${NORM}\n"
printf "${YELLOW}+++++++++++++++++++++++++++++++++++++++++++++++++++${NORM}\n"
read -p "Enter Username: " dnac_username
read -s -p "Enter Password: " dnac_password
printf "\n"
printf "\n"
DNAC_TOKEN=`curl -k -u ${dnac_username}:${dnac_password} -X POST --insecure -s https://${DNAIP}/api/system/v1/auth/token 2>&1 | awk -F '"' '{print $4}'`
printf "${YELLOW}Your DNA-C token is: ${GREEN}${DNAC_TOKEN}${NORM}\n"
printf "\n"
printf "\n"
printf "${BLUE}Press ENTER to continue!${NORM}\n"
read

get_apic-em_projects
}

function get_apic-em_projects
{
# Get projects with serial numbers and write in File 
printf "${YELLOW}- Get sites from APIC-EM: ${NORM}\n"
curl --header "Content-Type:application/json" --header "Accept:application/json" --header "x-auth-token:${APIC_EM_TOKEN}" -X GET --insecure -s https://${APICIP}/api/v1/pnp-project 2>&1 | jq '.' | grep "siteName\|id" | sed 's/,$//' | awk -F '"' '{print $4}' | awk '{printf "%s%s",$0,(NR%2?" ":"\n")}' > ${tmp_dir}/temp_apicem_sites
cat ${tmp_dir}/temp_apicem_sites
printf "\n"
printf "${BLUE}Press ENTER to continue!${NORM}\n"
read

create_dna-c_sites
}

function create_dna-c_sites
{
printf "${YELLOW}- Create sites on DNA-Center ${NORM}\n"
printf "\n"
while read line; 
do 
area=`echo $line | awk '{print $1}'`
printf "  ${YELLOW}Site $area will be created \n"
curl --header "Content-Type:application/json" --header "Accept:application/json" --header "x-auth-token:${DNAC_TOKEN}" -X POST --data '{"type":"area","site":{"area":{"name":"'${area}'","parentName":"Global"}}}' --insecure -s https://${DNAIP}/dna/intent/api/v1/site 2>&1 | jq '.' 
printf "  ${YELLOW}Bulding in $area will be created \n"
curl --header "Content-Type:application/json" --header "Accept:application/json" --header "x-auth-token:${DNAC_TOKEN}" -X POST --data '{"type":"building","site":{"building":{"name":"Building 1","parentName":"Global/'${area}'","latitude":"51.40019226074219","longitude":"7.128604412078857"}}}' --insecure -s https://${DNAIP}/dna/intent/api/v1/site 2>&1 | jq '.' 
sleep 1
done < ${tmp_dir}/temp_apicem_sites
printf "\n"
printf "${BLUE}Press ENTER to continue!${NORM}\n"
read

define_create_credentials
}

function define_create_credentials
{
      printf "${RED}#############################################################################\n"
      printf "#  Please define all required information to add the device to DNA Center:  #\n"
      printf "#############################################################################${NORM}\n"
      printf "\n"
      read -p "Enter SSH Username: " ssh_username
      read -s -p "Enter SSH Password: " ssh_password
      printf "\n"
      read -s -p "Enter enable Password: " enable_password
      printf "\n"
      read -p "Enter snmpROCommunity : " snmp_ro_community    
      read -s -p "Enter snmpRWCommunity : " snmp_rw_community 
      printf "\n"
      printf "\n"
      printf "${BLUE}Press ENTER to continue!${NORM}\n"
      read

      get_and_create_devices   
}

function get_and_create_devices
{
printf "${YELLOW}- Collect devices from APIC-EM: ${NORM}\n"
curl --header "Content-Type:application/json" --header "Accept:application/json" --header "x-auth-token:${DNAC_TOKEN}" -X GET https://${DNAIP}/dna/intent/api/v1/topology/site-topology --insecure -s | jq '.' > ${tmp_dir}/temp_dna_sites
printf "\n"
while read line; 
do 
site=`echo $line | awk '{print $1}'`
siteid=`echo $line | awk '{print $2}'`
printf "  ${YELLOW}Get devices from ${site}: \n"
curl --header "Content-Type:application/json" --header "Accept:application/json" --header "x-auth-token:${APIC_EM_TOKEN}" -X GET --insecure -s https://${APICIP}/api/v1/pnp-project/${siteid}/device 2>&1 | jq '.' > ${tmp_dir}/temp_${site}_raw_devices
device_serials=`cat ${tmp_dir}/temp_${site}_raw_devices | grep serialNumber | awk -F '"' '{print $4}' | tee ${tmp_dir}/temp_${site}_devices`
if [ -z "$device_serials" ]
then
      printf "${RED}No devices found ${NORM}\n"
else
      while read serialNumber; 
      do    
            curl --header "Content-Type:application/json" --header "Accept:application/json" --header "x-auth-token:${APIC_EM_TOKEN}" -X GET --insecure -s https://${APICIP}/api/v1/network-device/serial-number/${serialNumber} 2>&1 | jq '.'  > ${tmp_dir}/temp_${site}_${serialNumber}_device
            managementIpAddress=`cat ${tmp_dir}/temp_${site}_${serialNumber}_device | grep managementIpAddress | awk -F '"' '{print $4}'`    
            printf "${YELLOW}Create devices with serialnumber ${serialNumber} and MGMT IP ${managementIpAddress} on DNAC ${NORM}\n"
            curl --header "Content-Type:application/json" --header "Accept:application/json" --header "x-auth-token:${DNAC_TOKEN}" -X POST --data '{"cliTransport":"ssh","enablePassword":"'${enable_password}'","userName":"'${ssh_username}'","password":"'${ssh_password}'","snmpROCommunity":"'${snmp_ro_community}'","snmpRWCommunity":"'${snmp_rw_community}'","snmpRetry":"2","snmpTimeout":"3","snmpVersion":"v2","type":"NETWORK_DEVICE","serialNumber":"'${serialNumber}'","ipAddress":["'${managementIpAddress}'"]}' --insecure -s https://${DNAIP}/dna/intent/api/v1/network-device 2>&1 | jq '.' 
            printf "${YELLOW}Assign device ${serialNumber} to site ${site} ${NORM}\n"
            dna_siteid=`cat ${tmp_dir}/temp_dna_sites | grep "Global/${site}/Building 1" -B 9 | grep "id" | awk -F '"' '{print $4}'`
            echo ${dna_siteid}
            curl --header "Content-Type:application/json" --header "Accept:application/json" --header "x-auth-token:${DNAC_TOKEN}" -X POST --data '{"device":[{"ip":"'${managementIpAddress}'"}]}' --insecure -s https://${DNAIP}/dna/system/api/v1/site/${dna_siteid}/device 2>&1 | jq '.' 
            sleep 1
      done < ${tmp_dir}/temp_${site}_devices
fi
done < ${tmp_dir}/temp_apicem_sites
}

function exit_abnormal
{          
  printf "${RED}!!!!! OH nooooo ... something went wrong! Try again! !!!!!${NORM}\n"
  help
  exit 1
}

header

if [ "$#" == "0" ]
  then
    help
	else
    while getopts ":a:d:hm" opt
    do
      case $opt in
        a) APICIP="${OPTARG}"
           echo "APIC-EM IP is: ${APICIP}" 
            ;;
        d) DNAIP="${OPTARG}"
           echo "DNA-Center IP is: ${DNAIP}" 
            ;;
        h) help
            ;;
        m) get_auth_token
            ;;
        *) exit_abnormal
            ;;
      esac
    done
    shift $(($OPTIND -1))
fi