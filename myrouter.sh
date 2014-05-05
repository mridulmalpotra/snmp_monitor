#!/bin/bash

echo "Program Started..."
echo
read -p "Enter IP Address of Client: " ip_addr

printf "Verifying device status..."
ping -c3 $ip_addr > /dev/null && ping_status='UP' || ping_status='DOWN'
echo $ping_status
if [ "$ping_status" = "DOWN" ]; then
    echo "Device unresponsive or address error. Exiting..."
    exit 1
fi

echo
com_str="public"
echo "Enter community string for SNMP Client"
read -p "(Press enter for default value): " $com_str
echo
echo "Verifying SNMP status..."
snmpget -v1 -c $com_str $ip_addr SNMPv2-MIB::sysDescr.0 > snmp_out.log
size=`du -a | grep snmp_out.log | awk '{print $1}'`
if [ "$size" = "0" ]; then
    echo "SNMP not enabled on device. Exiting..."
    exit 1
fi
echo "SNMP Client found"

# echo
# devid=`snmpget -v1 -c public 192.168.0.34 ipForwarding.0 | tail -c 3 | head -c 1`
# if [ "$devid" = "2" ]; then
#     echo "Device identified as a SWITCH"
# elif [ "$devid" = "1" ]; then
#     echo "Device identified as a ROUTER"
# else
#     echo "Warning: Device not identified, continuing still..."
# fi

echo
echo "Launching portal interface..."
sleep 1
sensible-browser ./myrouter.html &
PID=`jobs -p`

while [[ true ]]; 
do
		in=`snmpget -v1 -c public $ip_addr interfaces.ifTable.ifEntry.ifInOctets.10 | tr -d '\n' | awk '{print $NF}'`
		out=`snmpget -v1 -c public $ip_addr interfaces.ifTable.ifEntry.ifOutOctets.10 | tr -d '\n' | awk '{print $NF}'`
		n=`date "+"%s""`
		echo "created on:" `date` >> img_config.log
		rrdtool update myrouter.rrd $n:$in:$out
		rrdtool graph ./images/myrouterin-1min.png --start -60 \
            DEF:inmaximum=myrouter.rrd:input:MAX \
            DEF:inoctets=myrouter.rrd:input:AVERAGE \
            AREA:inoctets#00FF00:"IN Average traffic" \
            LINE1:inmaximum#FF0000:"IN Maximum traffic" >> img_config.log
        rrdtool graph ./images/myrouterout-1min.png --start -60 \
            DEF:outmaximum=myrouter.rrd:output:MAX \
            DEF:outoctets=myrouter.rrd:output:AVERAGE \
            AREA:outoctets#00FF00:"OUT Average traffic" \
            LINE1:outmaximum#FF0000:"OUT Maximum traffic" >> img_config.log
		rrdtool graph ./images/myrouterin-10min.png --start -600 \
            DEF:inmaximum=myrouter.rrd:input:MAX \
            DEF:inoctets=myrouter.rrd:input:AVERAGE \
            AREA:inoctets#00FF00:"IN Average traffic" \
            LINE1:inmaximum#FF0000:"IN Maximum traffic" >> img_config.log
        rrdtool graph ./images/myrouterout-10min.png --start -600 \
            DEF:outmaximum=myrouter.rrd:output:MAX \
            DEF:outoctets=myrouter.rrd:output:AVERAGE \
            AREA:outoctets#00FF00:"OUT Average traffic" \
            LINE1:outmaximum#FF0000:"OUT Maximum traffic" >> img_config.log
		rrdtool graph ./images/myrouterin-1hr.png --start -3600 \
            DEF:inmaximum=myrouter.rrd:input:MAX \
            DEF:inoctets=myrouter.rrd:input:AVERAGE \
            AREA:inoctets#00FF00:"IN Average traffic" \
            LINE1:inmaximum#FF0000:"IN Maximum traffic" >> img_config.log
        rrdtool graph ./images/myrouterout-1hr.png --start -3600 \
            DEF:outmaximum=myrouter.rrd:output:MAX \
            DEF:outoctets=myrouter.rrd:output:AVERAGE \
            AREA:outoctets#00FF00:"OUT Average traffic" \
            LINE1:outmaximum#FF0000:"OUT Maximum traffic" >> img_config.log

		sleep 10
done

myExit() {
    kill $PID
    echo -en "Exiting..."
    sleep 1
    exit 0
}

trap myExit $SIGINT

