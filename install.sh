#!/bin/bash

source .env

if [ "$(id -u)" != "0" ]; then
    echo "Este script debés ejecutarlo como root, gato" 1>&2
    exit 1
fi

echo "Script para simplificarnos la vida, chabón."

[[ -d /opt/exabgp/scripts/ ]] || mkdir -p /opt/exabgp/scripts/

echo "Instalando ScrubbingUNLP"

if [[ -d /opt/ScrubbingUNLP ]]; then
    echo "Ya existe una instalación de ScrubbingUNLP en /opt/ScrubbingUNLP, borrando..."
    rm -rf /opt/ScrubbingUNLP
else
    echo "Descargando ScrubbingUNLP en /opt/ScrubbingUNLP"
    git clone https://github.com/mateodurante/ScrubbingUNLP.git /opt/ScrubbingUNLP
    bash /opt/ScrubbingUNLP/install.sh
fi


if [[ -d /opt/WebScrub ]]; then
    echo "Ya existe una instalación de WebScrub en /opt/WebScrub, borrando..."
    rm -rf /opt/WebScrub
else
    echo "Descargando WebScrub en /opt/WebScrub"
    git clone https://github.com/mateodurante/WebScrub.git /opt/WebScrub
    cd /opt/WebScrub
    cp db.sqlite3.initial db.sqlite3
    sudo pip3 install -r requirements.txt
    python3 manage.py makemigrations
    python3 manage.py migrate
fi
