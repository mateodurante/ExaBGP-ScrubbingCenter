## ExaBGP Scrubbing Center

### Demo del funcionamiento del ScrubbingUNLP

* Se recomienda utilizar la máquina virtual provista en https://github.com/cristianbarbaro/vagrant-coreemu o utilizar una máquina que cuente con CORE instalado. Esta máquina virtual ya tiene creada las rutas necesarias para acceder a los recursos de la demo desde la máquina host, además instala todas las dependencias necesarias para el correcto funcionamiento del CORE. 

* `git clone https://github.com/cristianbarbaro/vagrant-coreemu`

* Una vez clonado el repositorio, ingresar en la carpeta `shared` del proyecto de la máquina virtual y clonar este repositorio.

* `cd vagrant-coreemu/shared && git clone https://github.com/mateodurante/ExaBGP-ScrubbingCenter`


#### Instalar:

* `sudo bash install.sh` 

#### Ejecutar:

* Iniciar la topología en el core. 
* Ejecutar el comando `sudo bash start.sh`

#### Detener:

* `sudo bash stop.sh`

#### Descripción de los scripts:

* `install.sh` es el script instala las herramientas necesarias para ejecutar la demo. Es el encargado de instalar exaBGP, ScrubbingUNLP y WebScrub además de los dependencias necesarias para el funcionamiento de estos componentes.

* `start.sh` configura el entorno de la máquina en la cual ejecutará la demo e inicializa los servicios y componentes necesarios para su ejecución (WebScrub, ExaBGP, etc.). Además, es el encargado de cargar las configuraciones de los nodos en la topología del CORE. 

* `stop.sh` es el encargado de detener todos los servicios y procesos que se hayan inicializado durante la demo. 



```
admin	admin@admin.com
administrator	 	
coopx	coopx@coopx.com
coopy	coopy@coopy.com
redes	redes@redes.com
unlp	unlp@unlp.edu.ar
```
