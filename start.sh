#!/bin/bash
# Cristian gato

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

cp /root/exabgpCentral.ini $core_path/WebService.conf/
cp /root/exabgpScrubbing1.ini $core_path/n36.conf/
cp /root/exabgpScrubbing2.ini $core_path/n52.conf/

echo "Ejecutando ExaBGP en ambos nodos de CORE."

/usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "env exabgp.daemon.daemonize=false exabgp.tcp.bind=100.0.9.10 exabgp.daemon.user=root /opt/exabgp/sbin/exabgp $core_path/n36.conf/exabgpScrubbing1.ini" &

sleep 5

/usr/sbin/vcmd -c $core_path/WebService -- bash -E -c "env exabgp.daemon.daemonize=false exabgp.tcp.bind=100.0.13.10 exabgp.daemon.user=root /opt/exabgp/sbin/exabgp $core_path/WebService.conf/exabgpCentral.ini" &

sleep 5

/usr/sbin/vcmd -c $core_path/n52 -- bash -E -c "env exabgp.daemon.daemonize=false exabgp.tcp.bind=100.0.15.10 exabgp.daemon.user=root /opt/exabgp/sbin/exabgp $core_path/n52.conf/exabgpScrubbing2.ini" &

echo "Instalando módulo PyMongo en máquina de WebService"

/usr/sbin/vcmd -c $core_path/WebService -- bash -E -c "pip3 install pymongo"

echo "Iniciando mongodb en máquina de WebService"

[[ -d /tmp/data/WebService ]] || mkdir -p /tmp/data/WebService

/usr/sbin/vcmd -c $core_path/WebService -- bash -E -c "mongod --dbpath /tmp/data/WebService" &

echo "Iniciando servicio web en máquina de WebService"

/usr/sbin/vcmd -c $core_path/WebService -- bash -E -c "python3 $webapp_path_repo/manage.py runsslserver 0.0.0.0:443" &

# Ejecutamos el script atacante.sh
#bash ./atacante.sh
