#!/bin/bash

source .env

core_path=$(ps aux | grep -oP "/tmp/pycore.[0-9]+" | head -n 1)

# Pings contra dos servidores de cada organizacion:
#/usr/sbin/vcmd -c $core_path/n24 -- bash -E -c "ping 182.23.0.10" &>/dev/null & 
#/usr/sbin/vcmd -c $core_path/n24 -- bash -E -c "ping 193.81.7.10" &>/dev/null &

# Hping con SYN TCP al puerto 80:
/usr/sbin/vcmd -c $core_path/n5 -- bash -E -c "hping3 -S 182.23.0.10 -p 80" &>/dev/null &

/usr/sbin/vcmd -c $core_path/n24 -- bash -E -c "hping3 --udp 193.81.7.10 --rand-source -s 123 --flood" &>/dev/null &
