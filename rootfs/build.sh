#!/usr/bin/env bash

apk add git curl ncurses mc dpkg hstr

# Installs latest Chromium package for testing
# see https://github.com/puppeteer/puppeteer/blob/master/docs/troubleshooting.md#running-on-alpine
apk add \
      chromium \
      nss \
      freetype \
      freetype-dev \
      harfbuzz \
      ca-certificates \
      ttf-freefont

# install gosu
dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"
curl -fsSL "https://github.com/tianon/gosu/releases/download/1.12/gosu-$dpkgArch" -o /usr/local/bin/gosu
chmod +x /usr/local/bin/gosu
gosu nobody true

# install docker client
apk add docker
for gid in 497 998; do addgroup -g $gid docker$gid; addgroup node docker$gid; done

# install python3
apk add python3
if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi
python3 -m ensurepip
rm -r /usr/lib/python*/ensurepip
pip3 install --no-cache --upgrade pip setuptools wheel
if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi

# ensure the latest version of npm
yarn global add npm

# install ngrok & localtunnel
curl -fsSLo /tmp/ngrok.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip && unzip /tmp/ngrok.zip -d /usr/local/bin/
yarn global add localtunnel

# install packages globally
yarn global add @angular/cli
yarn global add @stencil/core
yarn global add http-server
yarn global add jshint
yarn global add uglify-js
yarn global add polymer-cli
yarn global add typescript

# set up the machine
cd /home/node
gosu node git clone --depth=1 https://github.com/Bash-it/bash-it.git .bash_it
gosu node ln -s /home/node/coolersport /home/node/.bash_it/themes/coolersport
gosu node bash -c 'export BASH_IT=/home/node/.bash_it
                   source /home/node/.bash_it/bash_it.sh
                   bash-it enable completion defaults dirs git npm
                   bash-it enable plugin base edit-mode-vi'

# entrypoint
chmod +x /entrypoint.sh

# cleanup
apk del dpkg
rm -rf /apk /tmp/* /var/cache/apk/*
yarn cache clean