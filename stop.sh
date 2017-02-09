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

exit 0
