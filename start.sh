#!/bin/bash

source .env

if [ "$(id -u)" != "0" ]; then
   echo "Este script debés ejecutarlo como root, gato" 1>&2
   exit 1
fi

echo "Script para simplificarnos la vida, chabón."

[[ -d /opt/exabgp/scripts/ ]] || mkdir -p /opt/exabgp/scripts/

echo "Moviendo archivos de configuración .ini a /root"

cp ConfExaBGP/*.ini /root/

echo "Moviendo scripts de Python a /opt/exabgp/scripts/"

cp ConfExaBGP/*.py /opt/exabgp/scripts/

core_path=$(ps aux | grep -oP "/tmp/pycore.[0-9]+" | head -n 1)

echo "Moviendo .ini a los nodos del CORE"

cp /root/exabgpUNLP.ini $core_path/n32.conf/
cp /root/exabgpSyper.ini $core_path/ExaBGPSyper.conf/
cp /root/exabgpScrubbing.ini $core_path/n36.conf/

echo "Ejecutando ExaBGP en ambos nodos de CORE."

/usr/sbin/vcmd -c $core_path/n32 -- bash -E -c "env exabgp.daemon.daemonize=false exabgp.tcp.bind=163.10.252.2 exabgp.daemon.user=root /opt/exabgp/sbin/exabgp $core_path/n32.conf/exabgpUNLP.ini" &

sleep 5

/usr/sbin/vcmd -c $core_path/ExaBGPSyper -- bash -E -c "env exabgp.daemon.daemonize=false exabgp.tcp.bind=193.81.8.2 exabgp.daemon.user=root /opt/exabgp/sbin/exabgp $core_path/ExaBGPSyper.conf/exabgpSyper.ini" &

sleep 5

/usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "env exabgp.daemon.daemonize=false exabgp.tcp.bind=10.0.9.10 exabgp.daemon.user=root /opt/exabgp/sbin/exabgp $core_path/n36.conf/exabgpScrubbing.ini" &

echo "Instalando módulo PyMongo en máquina de UNLP"

/usr/sbin/vcmd -c $core_path/n32 -- bash -E -c "pip3 install pymongo"

echo "Iniciando mongodb en máquina de UNLP"

[[ -d /tmp/data/unlp ]] || mkdir -p /tmp/data/unlp

/usr/sbin/vcmd -c $core_path/n32 -- bash -E -c "mongod --dbpath /tmp/data/unlp" &

echo "Iniciando servicio web en máquina de UNLP"

/usr/sbin/vcmd -c $core_path/n32 -- bash -E -c "python3 $webapp_path/manage.py runserver 0.0.0.0:80" &

# ================ Máquina Syper ===================

echo "Instalando módulo PyMongo en máquina de Syper"

/usr/sbin/vcmd -c $core_path/ExaBGPSyper -- bash -E -c "pip3 install pymongo"

echo "Iniciando mongodb en máquina de Syper"

[[ -d /tmp/data/syper ]] || mkdir -p /tmp/data/syper

/usr/sbin/vcmd -c $core_path/ExaBGPSyper -- bash -E -c "mongod --dbpath /tmp/data/syper" &

echo "Iniciando servicio web en máquina de Syper"

/usr/sbin/vcmd -c $core_path/ExaBGPSyper -- bash -E -c "python3 $webapp_path/manage.py runserver 0.0.0.0:80" &
