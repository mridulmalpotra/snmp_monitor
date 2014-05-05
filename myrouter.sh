#!/bin/bash

echo "Program Started..."

while [[ true ]]; 
do
		in=`snmpget -v1 -c public 192.168.0.34 interfaces.ifTable.ifEntry.ifInOctets.10 | tr -d '\n' | awk '{print $NF}'`
		out=`snmpget -v1 -c public 192.168.0.34 interfaces.ifTable.ifEntry.ifOutOctets.10 | tr -d '\n' | awk '{print $NF}'`
		n=`date "+"%s""`
		rrdtool update myrouter.rrd $n:$in:$out
		rrdtool graph myrouter-day.png --start -60             DEF:inoctets=myrouter.rrd:input:AVERAGE             DEF:outoctets=myrouter.rrd:output:AVERAGE             AREA:inoctets#00FF00:"In traffic"             LINE1:outoctets#FF0000:"Out traffic"
		sleep 10
done