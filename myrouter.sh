#!/bin/bash

echo "Program Started..."

while [[ true ]]; 
do
		in=`snmpget -v1 -c public 192.168.0.34 interfaces.ifTable.ifEntry.ifInOctets.10 | tr -d '\n' | awk '{print $NF}'`
		out=`snmpget -v1 -c public 192.168.0.34 interfaces.ifTable.ifEntry.ifOutOctets.10 | tr -d '\n' | awk '{print $NF}'`
		n=`date "+"%s""`
		echo "created on:" `date` >> img_config.log
		rrdtool update myrouter.rrd $n:$in:$out
		rrdtool graph myrouterin-1min.png --start -60 \
            DEF:inmaximum=myrouter.rrd:input:MAX \
            DEF:inoctets=myrouter.rrd:input:AVERAGE \
            AREA:inoctets#00FF00:"IN Average traffic" \
            LINE1:inmaximum#FF0000:"IN Maximum traffic" >> img_config.log
        rrdtool graph myrouterout-1min.png --start -60 \
            DEF:outmaximum=myrouter.rrd:output:MAX \
            DEF:outoctets=myrouter.rrd:output:AVERAGE \
            AREA:outoctets#00FF00:"OUT Average traffic" \
            LINE1:outmaximum#FF0000:"OUT Maximum traffic" >> img_config.log
		rrdtool graph myrouterin-10min.png --start -600 \
            DEF:inmaximum=myrouter.rrd:input:MAX \
            DEF:inoctets=myrouter.rrd:input:AVERAGE \
            AREA:inoctets#00FF00:"IN Average traffic" \
            LINE1:inmaximum#FF0000:"IN Maximum traffic" >> img_config.log
        rrdtool graph myrouterout-10min.png --start -600 \
            DEF:outmaximum=myrouter.rrd:output:MAX \
            DEF:outoctets=myrouter.rrd:output:AVERAGE \
            AREA:outoctets#00FF00:"OUT Average traffic" \
            LINE1:outmaximum#FF0000:"OUT Maximum traffic" >> img_config.log
		rrdtool graph myrouterin-1hr.png --start -3600 \
            DEF:inmaximum=myrouter.rrd:input:MAX \
            DEF:inoctets=myrouter.rrd:input:AVERAGE \
            AREA:inoctets#00FF00:"IN Average traffic" \
            LINE1:inmaximum#FF0000:"IN Maximum traffic" >> img_config.log
        rrdtool graph myrouterout-1hr.png --start -3600 \
            DEF:outmaximum=myrouter.rrd:output:MAX \
            DEF:outoctets=myrouter.rrd:output:AVERAGE \
            AREA:outoctets#00FF00:"OUT Average traffic" \
            LINE1:outmaximum#FF0000:"OUT Maximum traffic" >> img_config.log

		sleep 10
done