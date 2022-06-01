#!/bin/bash
#Carel pcoweb checker tool for nagios - LibreNMS
#2021 - Konstantinos Merentitis
#Version 1.0

#Usage: ./check_carel_pcoweb [-H hostname] [-c SNMP community] (optional) [-N sensor number]
#some alarms list, for more, see CAREL-ug40cdz.MIB

#s1="SystemFanon"
#s2="Compressor1"
#s10="Dehumidification"
#s11="Humidification"
#s20="TamperingAlarm"
#s21="Alarm:RoomHighTemperature"
#s22="Alarm:RoomLowTemperature"
#s23="Alarm:RoomHighHumidity"
#s24="Alarm:RoomLowHumidity"
#s27="Alarm:WaterLeakageDetected"
#s30="Circuit1HighPressure"
#s32="Circuit1LowPressure"
#s41="Alarm:HumidifierWaterLoss"
#s65="HumidifierGeneralAlarm"
#s75="SystemOn-Off"
#s66="GeneralAlarm"
#s118="Alarm:Humidifier:BottleFullOfWater(lock)"

while getopts H:c:N: option
do 
    case "${option}"
        in
        H)host=${OPTARG};;
        c)community=${OPTARG};;
        N)number=${OPTARG};;

    esac
done

if [ "${community}" = "" ]; then
    community="public"
fi

s1="System Fan on"
s27="Alarm: Water Leakage Detected"
s41="Alarm: Humidifier Water Loss"
s65="Humidifier General Alarm"
s66="General Alarm"
s75="System On-Off"
s118="Alarm: Humidifier: Bottle Full Of Water(lock)"

result=$(snmpget -Oqv -v2c -c "${community}" "${host}" 1.3.6.1.4.1.9839.2.1.1."${number}".0)


if [ "$result" == "1" ]; then 
        case "${number}" in 
        1) echo $s1 is OK; exit 0;; 
        75) echo $s75 is OK; exit 0;; 
        27) echo $s27 is Critical; exit 2;;
        41) echo $s41 is Critical; exit 2;;
        65) echo $s65 is Critical; exit 2;;
        66) echo $s66 is Critical; exit 2;;
        118) echo $s118 is Critical; exit 2;;
        esac
        #if number not in list:
        echo Digital Variable "${number}" is Critical && exit 2
fi

if [ "$result" == "0" ]; then 
        case "${number}" in 
        1) echo $s1 is Off; exit 2;;
        75) echo $s75 is Off; exit 2;;
        27) echo $s27 is OK; exit 0;; 
        41) echo $s41 is OK; exit 0;; 
        65) echo $s65 is OK; exit 0;; 
        66) echo $s66 is OK; exit 0;; 
        118) echo $s118 is OK; exit 0;; 
        esac
        #if number not in list
        echo Digital Variable "${number}" is OK && exit 0
else
        case "${number}" in 
        1) echo $s1 is Unknown; exit -1;;
        75) echo $s75 is Unknown; exit -1;;
        27) echo $s27 is Unknown; exit -1;; 
        41) echo $s41 is Unknown; exit -1;; 
        65) echo $s65 is Unknown; exit -1;; 
        66) echo $s66 is Unknown; exit -1;; 
        118) echo $s118 is Unknown; exit -1;; 
        esac
        echo Unknown error && exit -1
fi