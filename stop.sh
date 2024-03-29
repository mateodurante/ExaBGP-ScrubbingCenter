#!/bin/bash

for process in $(ps ax| grep bgp.py | awk '{print $1}'); 
do 
	kill -9 $process; 
done

http_api=$(ps ax | grep "/opt/exabgp/scripts/http_api.py" | awk '{print $1}')

kill -9 $http_api;

for webserver in $(ps ax | grep "manage.py" | awk '{print $1}');
do
	kill -9 $webserver; 
done

for process in $(ps ax | grep "ping" | awk '{print $1}');
do
	kill -9 $process;
done

for process in $(ps ax | grep "fprobe" | awk '{print $1}');
do
	kill -9 $process;
done

for process in $(ps ax | grep "python3\|/opt/exabgp" | awk '{print $1}');
do
	kill -9 $process;
done

#echo "Elimino las bases de datos de las aplicaciones para eliminar datos sucios"
#rm -r /tmp/data/WebService

exit 0
