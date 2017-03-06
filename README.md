## ExaBGP Scrubbing Center

#### Dependencias / paquetes necesarios:

* [ExaBGP](https://github.com/Exa-Networks/exabgp):
  * `cd /opt/`
  * `sudo git clone https://github.com/Exa-Networks/exabgp`

* MongoDB:
  * `sudo apt-get install mongodb`
  * Configurar la `bind_ip` en el archivo de configuración con la ip `0.0.0.0`.

* PyMongo:
  * `sudo pip install pymongo`

* Instalar además (para DJango y otras hierbas):
  * `sudo apt-get install redis-server`
  * `sudo apt-get install -y python-redis python-pip`
  * `sudo pip install rq`

#### Comandos que debemos ejecutar:

* Descargar el repositorio del servicio [WebScrub](https://gitlab.linti.unlp.edu.ar/certunlp/WebScrub) en cualquier otra carpeta que no sea dentro del repositorio de ScrubbingCenter:
  * `git clone https://gitlab.linti.unlp.edu.ar/certunlp/WebScrub.git`

* Pararse en la carpeta de este proyecto:
  * `git clone https://gitlab.linti.unlp.edu.ar/certunlp/ExaBGP-ScrubbingCenter.git && cd ExaBGP-ScrubbingCenter`

* Renombrar el archivo `.env-example` y configurar la variable `webapp_path` en el nuevo archivo `.env`:
  * `cp .env-example .env`

* Iniciar el CORE, levantar la topología y ejecutar el script restore en SaveRestoreScripts
  * `bash SaveRestoreScripts/restore.sh configNodos/`

* Ejecutar el script `start.sh` para levantar todas las configuraciones necesarias para generar los peerings entre ExaBGP y el servicio WebScrub en el CORE (este script hará todo el trabajo sucio, o casi, ya que no ejecuta el restore.sh):
  * `sudo bash start.sh`

* Para detener los servicios, ejecutar el script `stop.sh`
  * `sudo bash stop.sh`


===== Cosas viejas, hasta aquí ya no debe hacerse nada extra ====

* En la máquina del AS de UNLP:
  * `env exabgp.daemon.daemonize=false exabgp.tcp.bind=163.10.252.2 exabgp.daemon.user=root /opt/exabgp/sbin/exabgp ./exabgpUNLP.ini`

* En la máquina del Scrubbing:
  * `env exabgp.daemon.daemonize=false exabgp.tcp.bind=10.0.9.10 exabgp.daemon.user=root /opt/exabgp/sbin/exabgp ./exabgpScrubbing.ini`


Falta
Que el n36 del scrubbing haga un ip route del tráfico flowspec que le anuncia la UNLP de vuelta a traves del gre.

Continuará...

* Anunciando una ruta (probar desde máquina de UNLP):
  * `curl --form "command=announce route 107.10.0.0/24 next-hop self" http://localhost:5000/`.
* Anunciando una regla de FW:
  * `curl --form "command=announce flow route { match { source 163.10.42.236/32; destination 0.0.0.0/0; protocol icmp; } then { discard; } } " http://localhost:5000/`.
