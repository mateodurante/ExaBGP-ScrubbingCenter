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

#### Comandos que debemos ejecutar:

* Pararse en la carpeta de este proyecto:
  * `git clone https://gitlab.linti.unlp.edu.ar/certunlp/ExaBGP-ScrubbingCenter.git && cd ExaBGP-ScrubbingCenter`
  * `sudo mkdir -p /opt/exabgp/scripts/`
  * `sudo cp ConfExaBGP/*.py /opt/exabgp/scripts/`
  * `sudo cp ConfExaBGP/*.ini /root/` (necesario para que funcione el hook, se debe mejorar).

* En la máquina del AS de UNLP:
  * `env exabgp.daemon.daemonize=false exabgp.tcp.bind=163.10.252.2 exabgp.daemon.user=root /opt/exabgp/sbin/exabgp ./exabgpUNLP.ini`

* En la máquina del Scrubbing:
  * `env exabgp.daemon.daemonize=false exabgp.tcp.bind=10.0.9.10 exabgp.daemon.user=root /opt/exabgp/sbin/exabgp ./exabgpScrubbing.ini`



Continuará...

* Anunciando una ruta:
  * `curl --form "command=announce route 107.10.0.0/24 next-hop self" http://10.0.9.10:5000/` (editar ip servidor si no está corriendo Flask en 10.0.9.10).
* Anunciando una regla de FW:
  * `curl --form "command=announce flow route { match { source 163.10.42.236/32; destination 0.0.0.0/0; protocol icmp; } then { discard; } } " http://10.0.9.10:5000/`.
