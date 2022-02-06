## ExaBGP Scrubbing Center

#### Instalar:

`bash install.sh`

#### Ejecutar:

`bash start.sh`

#### Detener:

`bash stop.sh`

# VIEJO
#### Dependencias / paquetes necesarios:

* [ExaBGP](https://github.com/Exa-Networks/exabgp):
  * `cd /opt/`
  * `sudo git clone https://github.com/Exa-Networks/exabgp && cd exabgp/`
  * `sudo git checkout 4.2.11`
  * `sudo python3 -m zipapp -o /usr/local/sbin/exabgp -m exabgp.application:main  -p "/usr/bin/env python3" lib`

* Instalar además (para DJango y otras hierbas):
  * `sudo apt-get install -y redis-server python-redis python3-pip`
  * `sudo pip install rq`

* Utils:
  * `sudo apt install bridge-utils`

#### Comandos que debemos ejecutar:

* Descargar el repositorio del servicio [WebScrub](https://github.com/mateodurante/WebScrub.git) en cualquier otra carpeta que no sea dentro del repositorio de ScrubbingCenter:
  * `git clone https://github.com/mateodurante/WebScrub.git`
  * `cd WebScrub/`
  * `cp db.sqlite3.initial db.sqlite3`
  * `sudo pip3 install -r requirements.txt`

* Pararse en la carpeta de este proyecto:
  * `git clone https://github.com/mateodurante/ExaBGP-ScrubbingCenter.git && cd ExaBGP-ScrubbingCenter`
  * `sudo pip3 install -r requirements.txt`

* Renombrar el archivo `.env-example` y configurar la variable `webapp_path` en el nuevo archivo `.env`:
  * `cp .env-example .env`

* Iniciar el CORE, levantar la topología y ejecutar el script restore en SaveRestoreScripts
  * `bash SaveRestoreScripts/restore.sh configNodos/`

* Ejecutar el script `start.sh` para levantar todas las configuraciones necesarias para generar los peerings entre ExaBGP y el servicio WebScrub en el CORE (este script hará todo el trabajo sucio, o casi, ya que no ejecuta el restore.sh):
  * `sudo bash start.sh`

* Para detener los servicios, ejecutar el script `stop.sh`
  * `sudo bash stop.sh`

* **Contraseñas de los usuarios:**
 * **LEER EL README DEL REPO DE WEBSCRUBBING**.

```
admin	admin@admin.com
administrator	 	
coopx	coopx@coopx.com
coopy	coopy@coopy.com
redes	redes@redes.com
unlp	unlp@unlp.edu.ar
```


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
