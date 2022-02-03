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

cp /root/exabgpCentral.ini $core_path/n32.conf/
cp /root/exabgpScrubbing1.ini $core_path/n36.conf/
cp /root/exabgpScrubbing2.ini $core_path/ScrubCABASE.conf/

echo "Ejecutando ExaBGP en los nodos de CORE."

/usr/sbin/vcmd -c $core_path/n32 -- bash -E -c "mkfifo /run/exabgp.{in,out}; chmod 777 /run/exabgp.{in,out}"
/usr/sbin/vcmd -c $core_path/n32 -- bash -E -c "env exabgp.daemon.daemonize=false exabgp.tcp.bind=163.20.252.2 exabgp.daemon.user=root exabgp $core_path/n32.conf/exabgpCentral.ini" &

sleep 5

/usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "mkfifo /run/exabgp.{in,out}; chmod 777 /run/exabgp.{in,out}"
/usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "env exabgp.daemon.daemonize=false exabgp.tcp.bind=133.1.0.10 exabgp.daemon.user=root exabgp $core_path/n36.conf/exabgpScrubbing1.ini" &

sleep 5

/usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "mkfifo /run/exabgp.{in,out}; chmod 777 /run/exabgp.{in,out}"
/usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "env exabgp.daemon.daemonize=false exabgp.tcp.bind=10.0.8.10 exabgp.daemon.user=root exabgp $core_path/ScrubCABASE.conf/exabgpScrubbing2.ini" &

# echo "Instalando módulo PyMongo en máquina de WebService"

# /usr/sbin/vcmd -c $core_path/n32 -- bash -E -c "pip3 install pymongo"

# echo "Iniciando mongodb en máquina de WebService"

# [[ -d /tmp/data/WebService ]] || mkdir -p /tmp/data/WebService

# /usr/sbin/vcmd -c $core_path/n32 -- bash -E -c "mongod --dbpath /tmp/data/WebService" &

echo "Iniciando servicio web en máquina de WebService"

/usr/sbin/vcmd -c $core_path/n32 -- bash -E -c "python3 $webapp_path_repo/manage.py makemigrations"
/usr/sbin/vcmd -c $core_path/n32 -- bash -E -c "python3 $webapp_path_repo/manage.py migrate"
/usr/sbin/vcmd -c $core_path/n32 -- bash -E -c "python3 $webapp_path_repo/manage.py runserver 0.0.0.0:80" &


################################################ Túneles GRE ################################################

echo "Armado de túneles GRE"

#networks = {
#	"33"  : ["133.1.0.10", "172.16.1.0/24"],	# Scrubbing 1
#	"5692" : ["163.20.9.10", "172.16.2.0/24"],	# UNLP
#	"52376"  : ["10.0.8.10", "172.16.3.0/24"],	# Scrubbing 2 (CABASE)
#	"6243"  : ["182.23.9.10", "172.16.4.0/24"], # CooperativaX
#	"3928"  : ["110.20.9.10", "172.16.5.0/24"], # CooperativaY
#}

# Túneles gre de unlp contra scrubbings:
/usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip tunnel add scrub1 mode gre remote 133.1.0.10 local 163.20.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip link set scrub1 up"
# /usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip addr add 172.16.2.1 dev scrub1"
# /usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip route add 172.16.1.0/24 dev scrub1"

/usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip tunnel add cabase mode gre remote 10.0.8.10 local 163.20.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip link set cabase up"
# /usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip addr add 172.16.2.2 dev cabase"
# /usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip route add 172.16.3.0/24 dev cabase"



# Túneles gre de CooperativaX contra scrubbings:
/usr/sbin/vcmd -c $core_path/GRE-X -- bash -E -c "ip tunnel add scrub1 mode gre remote 133.1.0.10 local 182.23.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-X -- bash -E -c "ip link set scrub1 up"
# /usr/sbin/vcmd -c $core_path/GRE-X -- bash -E -c "ip addr add 172.16.4.1 dev scrub1"
# /usr/sbin/vcmd -c $core_path/GRE-X -- bash -E -c "ip route add 172.16.1.0/24 dev scrub1"

/usr/sbin/vcmd -c $core_path/GRE-X -- bash -E -c "ip tunnel add cabase mode gre remote 10.0.8.10 local 182.23.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-X -- bash -E -c "ip link set cabase up"
# /usr/sbin/vcmd -c $core_path/GRE-X -- bash -E -c "ip addr add 172.16.4.2 dev cabase"
# /usr/sbin/vcmd -c $core_path/GRE-X -- bash -E -c "ip route add 172.16.3.0/24 dev cabase"



# Túneles gre de CooperativaY contra scrubbings:
/usr/sbin/vcmd -c $core_path/GRE-Y -- bash -E -c "ip tunnel add scrub1 mode gre remote 133.1.0.10 local 110.20.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-Y -- bash -E -c "ip link set scrub1 up"
# /usr/sbin/vcmd -c $core_path/GRE-Y -- bash -E -c "ip addr add 172.16.5.1 dev scrub1"
# /usr/sbin/vcmd -c $core_path/GRE-Y -- bash -E -c "ip route add 172.16.1.0/24 dev scrub1"

/usr/sbin/vcmd -c $core_path/GRE-Y -- bash -E -c "ip tunnel add cabase mode gre remote 10.0.8.10 local 110.20.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-Y -- bash -E -c "ip link set cabase up"
# /usr/sbin/vcmd -c $core_path/GRE-Y -- bash -E -c "ip addr add 172.16.5.2 dev cabase"
# /usr/sbin/vcmd -c $core_path/GRE-Y -- bash -E -c "ip route add 172.16.3.0/24 dev cabase"




# Túneles gre de Scrubbing 1 contra clientes:
# /usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "ip tunnel add 5692 mode gre remote 163.20.9.10 local 133.1.0.10 ttl 255"
# /usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "ip link set 5692 up"
# /usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "ip addr add 172.16.1.1 dev 5692"
# /usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "ip route add 172.16.2.0/24 dev 5692"

# /usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "ip tunnel add 6243 mode gre remote 182.23.9.10 local 133.1.0.10 ttl 255"
# /usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "ip link set 6243 up"
# /usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "ip addr add 172.16.1.2 dev 6243"
# /usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "ip route add 172.16.4.0/24 dev 6243"

# /usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "ip tunnel add 3928 mode gre remote 110.20.9.10 local 133.1.0.10 ttl 255"
# /usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "ip link set 3928 up"
# /usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "ip addr add 172.16.1.3 dev 3928"
# /usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "ip route add 172.16.5.0/24 dev 3928"



# Túneles gre de Scrubbing 2 (CABASE) contra clientes:
# /usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "ip tunnel add 5692 mode gre remote 163.20.9.10 local 10.0.8.10 ttl 255"
# /usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "ip link set 5692 up"
# /usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "ip addr add 172.16.3.1 dev 5692"
# /usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "ip route add 172.16.2.0/24 dev 5692"

# /usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "ip tunnel add 6243 mode gre remote 182.23.9.10 local 10.0.8.10 ttl 255"
# /usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "ip link set 6243 up"
# /usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "ip addr add 172.16.3.2 dev 6243"
# /usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "ip route add 172.16.4.0/24 dev 6243"

# /usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "ip tunnel add 3928 mode gre remote 110.20.9.10 local 10.0.8.10 ttl 255"
# /usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "ip link set 3928 up"
# /usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "ip addr add 172.16.3.3 dev 3928"
# /usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "ip route add 172.16.5.0/24 dev 3928"



# Ejecutamos el script atacante.sh
#bash ./atacante.sh