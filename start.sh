#!/bin/bash

SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source ${SCRIPT_PATH}/.env
FPROBE_PARAM=""
[ -z "$FPROBE_URL" ] || FPROBE_PARAM="-f ${FPROBE_URL}"

if [ "$(id -u)" != "0" ]; then
   echo "Ejecutar el script como usuario root" 1>&2
   exit 1
fi

echo "Verificando instalación de Scrubbing Center y ExaBGP."

[[ -d /opt/exabgp/scripts/ ]] || mkdir -p /opt/exabgp/scripts/

[[ ! -d /opt/ScrubbingUNLP/ ]] && echo "No existe una instalación de ScrubbingUNLP en /opt/ScrubbingUNLP, ejecutar install.sh" && exit 1

echo "Moviendo archivos de configuración .ini a /root"

cp ConfExaBGP/*.ini /root/

core_path=$(ps aux | grep -oP "/tmp/pycore.[0-9]+" | head -n 1)

echo "Moviendo .ini a los nodos del CORE"

cp /root/exabgpCentral.ini $core_path/WebScrub.conf/
cp /root/exabgpScrubbing1.ini $core_path/Scrubbing1.conf/
cp /root/exabgpScrubbing2.ini $core_path/Scrubbing2.conf/

echo "Ejecutando ExaBGP en los nodos de CORE."

/usr/sbin/vcmd -c $core_path/WebScrub -- bash -E -c "/opt/ScrubbingUNLP/start.sh -w http://163.10.252.2/ -b 163.10.252.2 -c /root/exabgpCentral.ini &" &

# sleep 5

/usr/sbin/vcmd -c $core_path/Scrubbing1 -- bash -E -c "/opt/ScrubbingUNLP/start.sh -w http://163.10.252.2/ -b 133.1.0.10 ${FPROBE_PARAM} -c /root/exabgpScrubbing1.ini &" &

# sleep 5

/usr/sbin/vcmd -c $core_path/Scrubbing2 -- bash -E -c "/opt/ScrubbingUNLP/start.sh -w http://163.10.252.2/ -b 10.0.8.10 ${FPROBE_PARAM} -c /root/exabgpScrubbing2.ini &" &

echo "Iniciando servicio web WebScrub en máquina WebScrub"

/usr/sbin/vcmd -c $core_path/WebScrub -- bash -E -c "cd /opt/WebScrub/ && python3 /opt/WebScrub/manage.py runserver 0.0.0.0:80" &

################################################ Túneles GRE ################################################

echo "Armado de túneles GRE desde clientes a los ScrubbingCenters"

# Túneles gre de unlp contra scrubbings:
/usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip tunnel add scrub1 mode gre remote 133.1.0.10 local 163.10.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip link set scrub1 up"

/usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip tunnel add cabase mode gre remote 10.0.8.10 local 163.10.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip link set cabase up"


# Túneles gre de CooperativaX contra scrubbings:
/usr/sbin/vcmd -c $core_path/GRE-unq -- bash -E -c "ip tunnel add scrub1 mode gre remote 133.1.0.10 local 207.248.75.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-unq -- bash -E -c "ip link set scrub1 up"

/usr/sbin/vcmd -c $core_path/GRE-unq -- bash -E -c "ip tunnel add cabase mode gre remote 10.0.8.10 local 207.248.75.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-unq -- bash -E -c "ip link set cabase up"


# Túneles gre de CooperativaY contra scrubbings:
/usr/sbin/vcmd -c $core_path/GRE-uba -- bash -E -c "ip tunnel add scrub1 mode gre remote 133.1.0.10 local 157.92.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-uba -- bash -E -c "ip link set scrub1 up"

/usr/sbin/vcmd -c $core_path/GRE-uba -- bash -E -c "ip tunnel add cabase mode gre remote 10.0.8.10 local 157.92.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-uba -- bash -E -c "ip link set cabase up"

# copiar imagen a servicio web:
cp /home/vagrant/.coregui/backgrounds/nasa.png $core_path/www-uba.conf/var.www/

echo "Configurando hosts y routers de la topologia con restore.sh"
bash SaveRestoreScripts/restore.sh configNodos/

[ -z "$FPROBE_URL" ] || echo "Iniciando fprobe para gateway de borde de UBA"
[ -z "$FPROBE_URL" ] || /usr/sbin/vcmd -c $core_path/gw-UBA -- bash -E -c "sleep 30; /usr/sbin/fprobe -i eth0 ${FPROBE_URL}" &

echo "seteo de rate limit del servidor"
/usr/sbin/vcmd -c $core_path/www-uba -- bash -E -c "tc qdisc add dev eth0 root tbf rate 1024mbit latency 10ms burst 1540"

# Ejecutamos el script atacante.sh
#bash ./atacante.sh