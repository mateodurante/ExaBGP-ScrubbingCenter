#!/bin/bash

if [ "$(id -u)" != "0" ]; then
    echo "Este script debés ejecutarlo como root" 1>&2
    exit 1
fi

echo "Script para simplificarnos la vida."

[[ -d /opt/exabgp/scripts/ ]] || mkdir -p /opt/exabgp/scripts/

echo "Instalando ScrubbingUNLP"

if [[ -d /opt/ScrubbingUNLP ]]; then
    echo "Ya existe una instalación de ScrubbingUNLP en /opt/ScrubbingUNLP, borrando..."
    sudo rm -rf /opt/ScrubbingUNLP
fi

echo "Descargando ScrubbingUNLP en /opt/ScrubbingUNLP"
# git clone https://github.com/mateodurante/ScrubbingUNLP.git /opt/ScrubbingUNLP || { echo 'No se pudo clonar ScrubbingUNLP' ; exit 1; }
cp -r ../ScrubbingUNLP /opt/
bash /opt/ScrubbingUNLP/install.sh || { echo 'No se pudo instalar ScrubbingUNLP' ; exit 1; }

if [[ -d /opt/WebScrub ]]; then
    echo "Ya existe una instalación de WebScrub en /opt/WebScrub, borrando..."
    sudo rm -rf /opt/WebScrub
fi

echo "Descargando WebScrub en /opt/WebScrub"
# git clone https://github.com/mateodurante/WebScrub.git /opt/WebScrub || { echo 'No se pudo clonar WebScrub' ; exit 1; }
cp -r ../WebScrub /opt/
cp fixtures.yaml /opt/WebScrub/
cd /opt/WebScrub
cp db.sqlite3.initial db.sqlite3
sudo pip3 install -r requirements.txt
python3 manage.py makemigrations
python3 manage.py migrate
sudo python3 manage.py loaddata fixtures.yaml --format yaml
