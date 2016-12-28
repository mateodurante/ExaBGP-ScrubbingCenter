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
  * `sudo cp ConfExaBGP/syslog.py /usr/bin/syslog.py`
  * `sudo cp ConfExaBGP/*.ini /root/` (necesario para que funcione el hook, se debe mejorar).

* En la máquina del AS de UNLP:
  * `env exabgp.daemon.daemonize=false exabgp.tcp.bind=163.10.252.2 exabgp.daemon.user=root /opt/exabgp/sbin/exabgp ./exabgpUNLP.ini`

* En la máquina del Scrubbing:
  * `env exabgp.daemon.daemonize=false exabgp.tcp.bind=10.0.9.10 exabgp.daemon.user=root /opt/exabgp/sbin/exabgp ./exabgpScrubbing.ini`



Continuará...
