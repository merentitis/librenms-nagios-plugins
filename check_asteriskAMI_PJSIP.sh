#!/bin/bash
#asterisk SIP trunk and peer checker tool for nagios - LibreNMS
#2022 - Konstantinos Merentitis
#v1.2
#added a retry in case of 1st failure

#echo "usage: check_asterisk peers [-H hostname] [-P port] (optional) [-u Asterisk AMI username] [-p password] [-T trunk] (optional) [-E peer] (optional)"
 
while getopts H:P:u:p:T:E: option
do 
    case "${option}"
        in
        H)host=${OPTARG};;
        P)port=${OPTARG};;
        u)user=${OPTARG};;
        p)pass=${OPTARG};;
        T)TRUNKS=${OPTARG};;
        E)PEERS=${OPTARG};;

    esac
done

#In case you want to batch monitor, and did not specify peer or trunk to monitor, setup a list with the trunks and peers you wish to monitor
if [ "${TRUNKS}" = "" ] && [ "${PEERS}" = "" ]; then
        if [ "${TRUNKS}" == "" ]; then
                TRUNKS="
trunk1
trunk2
trunk3
"
        fi
        if [ "${PEERS}" == "" ]; then
                PEERS="
peer1
peer2
peer3
"
        fi
fi
if [ "${port}" = "" ]; then
        port="5038"
fi

trunkdown=0
for TRUNK in ${TRUNKS} ; do
FAILS=0
#Using sort because I have 2 trunks with the same name
check_trunk () {
        echo -e "Action: login\r\nUsername: ${user}\r\nSecret: ${pass}\r\nEvents: off\r\n\r\nAction: Command\r\ncommand: pjsip show endpoints\r\n\r\nAction: Logoff\r\n\r\n" | nc ${host} ${port}  |grep "$TRUNK"/sip | awk '{print $5}' | tr -d "\r"
}
result=$(check_trunk)
echo "$TRUNK : $result"

if [[ $result != "Avail" ]]; then
        #retry once
        for i in {1..2}; do
                FAILS=$[FAILS + 1]
                if [ $FAILS -le 1 ]; then
                        sleep 1
                        check_trunk
                        result=$(check_trunk)
                        #echo retrying: $FAILS
                        echo "$TRUNK : $result"
                        logger "trunkmon $TRUNK : $result"
                else
                        trunkdown=$((trunkdown+1))
                        #echo  trunk down
                fi
        done
fi
done

peerdown=0
for PEER in ${PEERS} ; do
check_peer () {
        echo -e "Action: login\r\nUsername: ${user}\r\nSecret: ${pass}\r\nEvents: off\r\n\r\nAction: Command\r\ncommand: pjsip show aors\r\n\r\nAction: Logoff\r\n\r\n" | nc  ${host} ${port}   |grep "$PEER"/sip| awk '{print $5}' | tr -d "\r"
}
result=$(check_peer)
echo "$PEER : $result"

if  [[ $result != "Avail" ]]; then
        peerdown=$((peerdown+1))
fi
done

#results for nagios
if [[ $trunkdown -ge "1" ]] || [[ $peerdown -ge "1" ]] ; then
        if [[ $trunkdown -ge "3" ]] ; then
                echo "Critical - $trunkdown trunks down, $peerdown peers down"
                exit 2
        else
                echo "Warning - $trunkdown trunks down, $peerdown peers down"
                exit 1

        fi
else
        echo "Everything OK"
        exit 0
fi
