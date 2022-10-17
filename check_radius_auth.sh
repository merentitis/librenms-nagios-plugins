#!/bin/bash
#Radius Authentication check tool for nagios - LibreNMS
#2022 - Konstantinos Merentitis
#Version 1.2
#freeradius-radclient package required

usage() { echo "Usage: 
        $0 [-H hostname] [-u username ] [-p pass ] [-P port] [-s secret] "
echo "Options:
        -h  show this page;
        -H  Radius server hostname;
        -u  username;
        -p  password;
        -P  port (Optional) - default 1812;
        -s  radius secret;"
exit 2;
}

while getopts hH:u:p:P:s: option
do 
    case "${option}"
        in
        h)usage;;
        H)host=${OPTARG} || usage;;
        u)username=${OPTARG} || usage;;
        p)pass=${OPTARG} || usage;;
        P)port=${OPTARG} || usage;;
        s)secret=${OPTARG} || usage;;
        \?) echo "Invalid option \"$OPTARG\" Please check help page"; exit 2;;
        :) echo "Option \"$OPTARG\" requires an argument."; exit 2;;
        *)  usage;;
    esac
done

if [ "${port}" = "" ]; then
    port="1812"
fi

if [ -z "$host" ] || [ -z "$username" ] || [ -z "$pass" ] || [ -z "$port" ] || [ -z "$secret" ]; then usage; fi

if  $(echo "User-Name="${username}",User-Password="${pass}"" | radclient -c 1 -r 2 -t 3 "${host}":"${port}" auth "${secret}" | grep -q 'Received Access-Accept') 
then echo "Radius Auth is OK" && exit 0
else echo "Radius Auth is Critical" ; exit 2;
fi