#!/usr/bin/env bash

DOCKER_COMPOSE_VERSION=2.23.1
LIBRE_OFFICE_VERSION=7.6.2

set -e

# activate contrib
sed -i 's/bullseye main/bullseye main contrib/g' /etc/apt/sources.list
apt update && apt upgrade -y && apt autoremove -y

# apk add git curl ncurses mc dpkg hstr
apt install -y vim git git-lfs curl mc jq dpkg iputils-ping
# libncurses5-dev libncursesw5-dev # was needed by hstr???

# install hstr
#curl -fsSL https://github.com/dvorka/hstr/releases/download/2.4/hstr_2.4.0-1_amd64.deb -o /tmp/hstr.deb
#apt install -y libncursesw5 libtinfo5 readline-common libreadline-dev
#dpkg -i /tmp/hstr.deb
apt install -y hstr

# Installs latest Chromium package for testing
apt install -y chromium chromium-l10n ca-certificates fonts-freefont-ttf libnss3 libharfbuzz-bin
apt install -y libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb

# install gosu
dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"
curl -fsSL "https://github.com/tianon/gosu/releases/download/1.17/gosu-$dpkgArch" -o /usr/local/bin/gosu
chmod +x /usr/local/bin/gosu
gosu nobody true

# install docker client
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update && apt install -y docker-ce docker-ce-cli containerd.io
adduser node docker
for gid in 497 998; do addgroup --gid $gid docker$gid; adduser node docker$gid; done

# install docker compose
apt install -y docker-compose-plugin
curl -fsSL "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# install mysql client
apt install -y default-mysql-client

# install postgresql client
apt install -y postgresql-client

# install python3 + pip
apt install -y python3-pip

# install graphviz and java for PlantUML
apt install -y graphviz default-jre

# install LibreOffice
curl -fsSLo /tmp/LibreOffice.tar.gz https://download.documentfoundation.org/libreoffice/stable/${LIBRE_OFFICE_VERSION}/deb/x86_64/LibreOffice_${LIBRE_OFFICE_VERSION}_Linux_x86-64_deb.tar.gz
# Install required dependencies for LibreOffice 7.0+
apt install -y libxinerama1 libfontconfig1 libdbus-glib-1-2 libcairo2 libcups2 libglu1-mesa libsm6
cd /tmp
tar -zxvf LibreOffice.tar.gz
cd LibreOffice*/DEBS
dpkg -i *.deb
# install Microsoft fonts
apt install -y ttf-mscorefonts-installer
# install fonts for special characters, such as chinese ideograms
apt install -y fonts-wqy-zenhei

# ensure the latest version of npm
yarn global add npm
# install pnpm
yarn global add pnpm

# install ngrok & localtunnel
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list && apt update && apt install ngrok
yarn global add localtunnel

# install packages globally
yarn global add \
                @angular/cli \
                @stencil/core \
                @ionic/cli \
                http-server \
                jshint \
                uglify-js \
                polymer-cli \
                typescript

# set ionic global config
cd /tmp
npm init -y
tsc --init
touch stencil.config.js index.js
echo 'exports.config = {};' > stencil.config.js
stencil telemetry off
ionic config set -g npmClient yarn
ionic config set -g telemetry false

rm -rf package.json tsconfig.json
chown node:node stencil.config.js index.js
gosu node npm init -y
gosu node tsc --init
gosu node stencil telemetry off
gosu node ionic config set -g npmClient yarn
gosu node ionic config set -g telemetry false

# set up the machine
cd /home/node
gosu node git clone --depth=1 https://github.com/Bash-it/bash-it.git .bash_it
gosu node ln -s /home/node/t7tran /home/node/.bash_it/themes/t7tran
gosu node bash -c 'export BASH_IT=/home/node/.bash_it
                   source /home/node/.bash_it/bash_it.sh
                   bash-it enable completion defaults dirs git npm
                   bash-it enable plugin base edit-mode-vi'
git clone https://github.com/t7tran/aliases.git /home/node/t7tran/aliases
ln -s /home/node/t7tran/aliases/.bash_aliases /home/node/.bash_aliases

# entrypoint
gosu node mkdir -p /home/node/.cache
chmod +x /entrypoint.sh

# setup terminal locale
apt install -y locales
echo "LC_ALL=en_US.UTF-8" >> /etc/environment
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen en_US.UTF-8

# cleanup
apt autoremove -y
apt clean
rm -rf /var/lib/apt/lists/* /tmp/*
yarn cache clean