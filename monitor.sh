#!/bin/bash

echo "Basic SNMP Server Monitoring"
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


echo
devid=`snmpget -v1 -c $com_str $ip_addr ipForwarding.0 | tail -c 3 | head -c 1`
uptime=`snmpget -v1 -c $com_str $ip_addr sysUpTime.0 | awk '{print $(NF-2) $(NF-1) $NF}'`
descr=`snmpget -v1 -c $com_str $ip_addr sysDescr.0 | awk -F '=' '{print $2}' | awk -F ':' '{print $NF}'`


echo
echo '==================================================================================='
echo '==================================================================================='
echo '                              DEVICE STATISTICS                                          '
echo 
echo 'IP Address: ' $ip_addr
printf "Device Type: "
if [ "$devid" = "2" ]; then
    echo "SWITCH"
elif [ "$devid" = "1" ]; then
    echo "ROUTER"
else
    echo "(Warning): Device not identified"
fi
echo 'Uptime: ' $uptime
echo 'Device Information: '$descr
echo
echo 'States to be monitored: '
snmpwalk -v1 -c $com_str $ip_addr interfaces.ifTable.ifEntry.ifDescr | grep -v GigabitEthernet
echo
read -p 'Enter vlan ID:' vlan
echo
echo
echo '==================================================================================='
echo '==================================================================================='

echo
read -p 'Press [ENTER] to continue...'

echo
echo
echo "Launching portal interface..."
sleep 1
sensible-browser ./monitor.html & PID=`jobs -p`

while [[ true ]]; 
do
		inp=`snmpget -v1 -c $com_str $ip_addr interfaces.ifTable.ifEntry.ifInOctets.$vlan | tr -d '\n' | awk '{print $NF}'`
		out=`snmpget -v1 -c $com_str $ip_addr interfaces.ifTable.ifEntry.ifOutOctets.$vlan | tr -d '\n' | awk '{print $NF}'`
		n=`date "+"%s""`
		echo `date "+"%s""`"created on:" `date` >> img_config.log
		rrdtool update monitor.rrd $n:$inp:$out
		rrdtool graph ./images/monitorin-10min.png --start -600 --vertical-label Bits-per-second \
            COMMENT:"Input" \
            DEF:inmaximum=monitor.rrd:input:MAX \
            DEF:inoctets=monitor.rrd:input:AVERAGE \
            AREA:inoctets#00FF00:"IN Average traffic" \
            LINE1:inmaximum#FF0000:"IN Maximum traffic" >> img_config.log
        rrdtool graph ./images/monitorout-10min.png --start -600 --vertical-label Bits-per-second \
            COMMENT:"Output" \
            DEF:outmaximum=monitor.rrd:output:MAX \
            DEF:outoctets=monitor.rrd:output:AVERAGE \
            AREA:outoctets#0000FF:"OUT Average traffic" \
            LINE1:outmaximum#FF0000:"OUT Maximum traffic" >> img_config.log
        rrdtool graph ./images/monitor-10min.png --start -600 --vertical-label Bits-per-second \
            COMMENT:"Input / Output" \
            DEF:outoctets=monitor.rrd:output:AVERAGE \
            DEF:inoctets=monitor.rrd:input:AVERAGE \
            AREA:inoctets#00FF00:"IN Average traffic" \
            LINE2:outoctets#0000FF:"OUT Average traffic" >> img_config.log
		rrdtool graph ./images/monitorin-1hr.png --start -3600 --vertical-label Bits-per-second \
            COMMENT:"Input" \
            DEF:inmaximum=monitor.rrd:input:MAX \
            DEF:inoctets=monitor.rrd:input:AVERAGE \
            AREA:inoctets#00FF00:"IN Average traffic" \
            LINE1:inmaximum#FF0000:"IN Maximum traffic" >> img_config.log
        rrdtool graph ./images/monitorout-1hr.png --start -3600 --vertical-label Bits-per-second \
            COMMENT:"Output" \
            DEF:outmaximum=monitor.rrd:output:MAX \
            DEF:outoctets=monitor.rrd:output:AVERAGE \
            AREA:outoctets#0000FF:"OUT Average traffic" \
            LINE1:outmaximum#FF0000:"OUT Maximum traffic" >> img_config.log
        rrdtool graph ./images/monitor-1hr.png --start -3600 --vertical-label Bits-per-second \
            COMMENT:"Input / Output" \
            DEF:outoctets=monitor.rrd:output:AVERAGE \
            DEF:inoctets=monitor.rrd:input:AVERAGE \
            AREA:inoctets#00FF00:"IN Average traffic" \
            LINE2:outoctets#0000FF:"OUT Average traffic" >> img_config.log
		rrdtool graph ./images/monitorin-1day.png --start -86400 --vertical-label Bits-per-second \
            COMMENT:"Input" \
            DEF:inmaximum=monitor.rrd:input:MAX \
            DEF:inoctets=monitor.rrd:input:AVERAGE \
            AREA:inoctets#00FF00:"IN Average traffic" \
            LINE1:inmaximum#FF0000:"IN Maximum traffic" >> img_config.log
        rrdtool graph ./images/monitorout-1day.png --start -86400 --vertical-label Bits-per-second \
            COMMENT:"Output" \
            DEF:outmaximum=monitor.rrd:output:MAX \
            DEF:outoctets=monitor.rrd:output:AVERAGE \
            AREA:outoctets#0000FF:"OUT Average traffic" \
            LINE1:outmaximum#FF0000:"OUT Maximum traffic" >> img_config.log
        rrdtool graph ./images/monitor-1day.png --start -86400 --vertical-label Bits-per-second \
            COMMENT:"Input / Output" \
            DEF:outoctets=monitor.rrd:output:AVERAGE \
            DEF:inoctets=monitor.rrd:input:AVERAGE \
            AREA:inoctets#00FF00:"IN Average traffic" \
            LINE2:outoctets#0000FF:"OUT Average traffic" >> img_config.log
		sleep 5
done
