#!/bin/bash

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

cp /root/exabgpCentral.ini $core_path/n32.conf/
cp /root/exabgpScrubbing1.ini $core_path/n36.conf/
cp /root/exabgpScrubbing2.ini $core_path/ScrubCABASE.conf/

echo "Ejecutando ExaBGP en los nodos de CORE."

/usr/sbin/vcmd -c $core_path/n32 -- bash -E -c "/opt/ScrubbingUNLP/start.sh -b 163.20.252.2 -c /root/exabgpCentral.ini"

sleep 5

/usr/sbin/vcmd -c $core_path/n36 -- bash -E -c "/opt/ScrubbingUNLP/start.sh -b 133.1.0.10 -c /root/exabgpScrubbing1.ini"

sleep 5

/usr/sbin/vcmd -c $core_path/ScrubCABASE -- bash -E -c "/opt/ScrubbingUNLP/start.sh -b 10.0.8.10 -c /root/exabgpScrubbing2.ini"

echo "Iniciando servicio web WebScrub en máquina n32"

/usr/sbin/vcmd -c $core_path/n32 -- bash -E -c "python3 /opt/WebScrub/manage.py runserver 0.0.0.0:80" &


################################################ Túneles GRE ################################################

echo "Armado de túneles GRE desde clientes a los ScrubbingCenters"

# Túneles gre de unlp contra scrubbings:
/usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip tunnel add scrub1 mode gre remote 133.1.0.10 local 163.20.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip link set scrub1 up"

/usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip tunnel add cabase mode gre remote 10.0.8.10 local 163.20.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-unlp -- bash -E -c "ip link set cabase up"


# Túneles gre de CooperativaX contra scrubbings:
/usr/sbin/vcmd -c $core_path/GRE-X -- bash -E -c "ip tunnel add scrub1 mode gre remote 133.1.0.10 local 182.23.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-X -- bash -E -c "ip link set scrub1 up"

/usr/sbin/vcmd -c $core_path/GRE-X -- bash -E -c "ip tunnel add cabase mode gre remote 10.0.8.10 local 182.23.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-X -- bash -E -c "ip link set cabase up"


# Túneles gre de CooperativaY contra scrubbings:
/usr/sbin/vcmd -c $core_path/GRE-Y -- bash -E -c "ip tunnel add scrub1 mode gre remote 133.1.0.10 local 110.20.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-Y -- bash -E -c "ip link set scrub1 up"

/usr/sbin/vcmd -c $core_path/GRE-Y -- bash -E -c "ip tunnel add cabase mode gre remote 10.0.8.10 local 110.20.9.10 ttl 255"
/usr/sbin/vcmd -c $core_path/GRE-Y -- bash -E -c "ip link set cabase up"


echo "Configurando hosts y routers de la topologia con restore.sh"
bash SaveRestoreScripts/restore.sh configNodos/

# Ejecutamos el script atacante.sh
#bash ./atacante.sh