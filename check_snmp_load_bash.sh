#!/bin/bash
#SNMP Load checker tool for nagios - LibreNMS
#2022 - Konstantinos Merentitis
#Version 1.1
#This monitoring plugin will alert you according to the Warning/Critical thresholds that you pass as arguments:

#Usage: ./check_snmp_load_bash.sh [-H hostname] [-c SNMP community] (optional) [-I 1m Warning] [-O 5m Warning] [-P 15m Warning] [-J 1m Critical] [-K 5m Critical] [-L 15m Critical] 
#example: ./check_snmp_load_bash.sh -H 10.10.1.20 -c public -I 2 -O 2 -P 2 -J 2 -K 3 -L 3

while getopts H:c:I:O:P:J:K:L: option
do 
    case "${option}"
        in
        H)host=${OPTARG};;
        c)community=${OPTARG};;
        I)w1m=${OPTARG};;
        O)w5m=${OPTARG};;
        P)w15m=${OPTARG};;
        J)c1m=${OPTARG};;
        K)c5m=${OPTARG};;
        L)c15m=${OPTARG};;        

    esac
done

if [ "${community}" = "" ]; then
    community="public"
fi

l1m=$(snmpget -Oqv -v2c -c "${community}" "${host}" 1.3.6.1.4.1.2021.10.1.3.1)
l5m=$(snmpget -Oqv -v2c -c "${community}" "${host}" 1.3.6.1.4.1.2021.10.1.3.2)
l15m=$(snmpget -Oqv -v2c -c "${community}" "${host}" 1.3.6.1.4.1.2021.10.1.3.3)

if [[ -z $w1m || -z $w5m || -z $w15m || -z $c1m || -z $c5m || -z $c15m ]]; then
  echo 'one or more variables are undefined'
  exit -1
fi

echo "1m:$l1m 5m:$l5m 15m:$l15m"

#Criticals

if (( $(echo "$l1m > $c1m" |bc -l) )); then 
        echo "Load 1m is Critical"; exit 2;
        
fi

if (( $(echo "$l5m > $c5m" |bc -l) )); then 
        echo "Load 5m is Critical"; exit 2;
        
fi

if (( $(echo "$l15m > $c15m" |bc -l) )); then 
        echo "Load 15m is Critical"; exit 2;
        
fi

#Warnings
if (( $(echo "$l1m > $w1m" |bc -l) )); then 
        echo "Load 1m is Warning"; exit 1;
        
fi

if (( $(echo "$l5m > $w5m" |bc -l) )); then 
        echo "Load 5m is Warning"; exit 1;
        
fi

if (( $(echo "$l15m > $w15m" |bc -l) )); then 
      echo "Load 15m is Warning"; exit 1;
        
fi

if [[ -z $l1m || -z $l5m || -z $l15m ]]; then
  echo 'Cannot get Load output'; exit 2;
fi

echo "Loads are OK" && exit 0
