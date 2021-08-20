#!/usr/bin/env bash

apt update && apt upgrade -y && apt autoremove -y

# apk add git curl ncurses mc dpkg hstr
apt install -y vim git curl mc jq dpkg iputils-ping libncurses5-dev libncursesw5-dev

# install hstr
curl -fsSL https://github.com/dvorka/hstr/releases/download/2.3/hstr_2.3.0-1_amd64.deb -o /tmp/hstr.deb
apt install -y libncursesw5 libtinfo5 readline-common libreadline7
dpkg -i /tmp/hstr.deb

# Installs latest Chromium package for testing
apt install -y chromium chromium-l10n ca-certificates fonts-freefont-ttf libnss3 libharfbuzz-bin
apt install libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb

# install gosu
dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"
curl -fsSL "https://github.com/tianon/gosu/releases/download/1.12/gosu-$dpkgArch" -o /usr/local/bin/gosu
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
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update && apt install -y docker-ce docker-ce-cli containerd.io
for gid in 497 998; do addgroup --gid $gid docker$gid; adduser node docker$gid; done

# install python3 + pip
apt install -y python3-pip

# install graphviz and openjdk for PlantUML
apt install -y graphviz
# see https://adoptopenjdk.net/installation.html?variant=openjdk11&jvmVariant=hotspot#x64_linux-jre
curl -fsSLo /opt/openjdk.tar.gz https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jre_x64_linux_hotspot_11.0.11_9.tar.gz
mkdir /opt/openjdk
tar xzf /opt/openjdk.tar.gz -C /opt/openjdk --strip-components 1
echo 'PATH=/opt/openjdk/bin:$PATH' >> /home/node/.profile

# ensure the latest version of npm
yarn global add npm

# install ngrok & localtunnel
curl -fsSLo /tmp/ngrok.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip && unzip /tmp/ngrok.zip -d /usr/local/bin/
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
ionic config set -g npmClient yarn
ionic config set -g telemetry false
echo "$( jq '."telemetry.stencil" = false' /root/.ionic/config.json )" > /root/.ionic/config.json

gosu node ionic config set -g npmClient yarn
gosu node ionic config set -g telemetry false
echo "$( jq '."telemetry.stencil" = false' /home/node/.ionic/config.json )" > /home/node/.ionic/config.json

# set up the machine
cd /home/node
gosu node git clone --depth=1 https://github.com/Bash-it/bash-it.git .bash_it
gosu node ln -s /home/node/coolersport /home/node/.bash_it/themes/coolersport
gosu node bash -c 'export BASH_IT=/home/node/.bash_it
                   source /home/node/.bash_it/bash_it.sh
                   bash-it enable completion defaults dirs git npm
                   bash-it enable plugin base edit-mode-vi'

# entrypoint
gosu node mkdir /home/node/.cache
chmod +x /entrypoint.sh

# cleanup
apt remove -y dpkg
apt clean
apt autoremove -y
rm -rf /var/lib/apt/lists/* /tmp/*
yarn cache clean