#!/usr/bin/env bash

DOCKER_COMPOSE_VERSION=5.1.1
LIBRE_OFFICE_VERSION=26.2.3
YQ_VERSION=4.53.2
NODE_MAJOR_VERSION=`node -v | cut -d. -f1 | sed 's/v//'`
GIT_CREDENTIAL_OAUTH_VERSION=0.17.2-p.1
VARIANT=${1:-full}

set -e

dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"

# activate contrib
sed -i 's/^Components: main$/& contrib/' /etc/apt/sources.list.d/debian.sources
apt update && apt upgrade -y && apt autoremove -y

# apk add git curl ncurses dpkg hstr
apt install -y git git-lfs curl jq dpkg iputils-ping

if [[ "$VARIANT" != "slim" ]]; then
  apt install -y vim tilix mc
fi

if [[ "$VARIANT" != "slim" ]]; then
  # install git-credential-oauth
  # curl -fsSL https://github.com/hickford/git-credential-oauth/releases/download/v${GIT_CREDENTIAL_OAUTH_VERSION:?}/git-credential-oauth_${GIT_CREDENTIAL_OAUTH_VERSION:?}_linux_${dpkgArch}.tar.gz | tar -C /usr/bin -xvzf - --wildcards --no-anchored git-credential-oauth
  curl -fsSL https://github.com/t7tran/git-credential-oauth/releases/download/v${GIT_CREDENTIAL_OAUTH_VERSION:?}/git-credential-oauth_${GIT_CREDENTIAL_OAUTH_VERSION:?}_linux_${dpkgArch}.tar.gz | tar -C /usr/bin -xvzf - --wildcards --no-anchored git-credential-oauth
fi

# install yq
curl -fsSL https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION:?}/yq_linux_${dpkgArch} -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq

if [[ "$VARIANT" != "slim" ]]; then
  # install hstr
  apt install -y hstr
fi

if [[ "$VARIANT" == "full" ]]; then
  # Installs latest Chromium package for testing
  apt install -y chromium chromium-l10n ca-certificates fonts-freefont-ttf libnss3 libharfbuzz-bin
  apt install -y libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth
fi

# install gosu
curl -fsSL "https://github.com/tianon/gosu/releases/download/1.19/gosu-$dpkgArch" -o /usr/local/bin/gosu
chmod +x /usr/local/bin/gosu
gosu nobody true

if [[ "$VARIANT" == "full" ]]; then
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
  for gid in 497 984 997 998 999; do
    groupname=`getent group $gid || true`
    if [[ -z "$groupname" ]]; then
      groupname=docker$gid
      addgroup --gid $gid docker$gid
    fi
    adduser node ${groupname%%:*} &>/dev/null || true
  done
fi

if [[ "$VARIANT" == "full" ]]; then
  # install docker compose
  apt install -y docker-compose-plugin
  curl -fsSL "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

if [[ "$VARIANT" != "slim" ]]; then
  # install mysql client
  apt install -y default-mysql-client

  # install postgresql client
  apt install -y postgresql-client
fi

# install sqlite3 for development
apt install -y sqlite3

# install python3 + pip
apt install -y python3-pip

if [[ "$VARIANT" == "full" ]]; then
  # install graphviz and java for PlantUML
  apt install -y graphviz default-jre
fi

if [[ "$VARIANT" == "full" ]]; then
  # install LibreOffice
  if [ "$dpkgArch" = "arm64" ]; then
    LO_DIR_ARCH="aarch64"
    LO_FILE_ARCH="aarch64"
  else
    LO_DIR_ARCH="x86_64"
    LO_FILE_ARCH="x86-64"
  fi
  curl -fsSLo /tmp/LibreOffice.tar.gz https://download.documentfoundation.org/libreoffice/stable/${LIBRE_OFFICE_VERSION}/deb/${LO_DIR_ARCH}/LibreOffice_${LIBRE_OFFICE_VERSION}_Linux_${LO_FILE_ARCH}_deb.tar.gz
  # Install required dependencies for LibreOffice 7.0+
  apt install -y libxinerama1 libfontconfig1 libdbus-glib-1-2 libcairo2 libcups2 libglu1-mesa libsm6
  cd /tmp
  tar -zxvf LibreOffice.tar.gz
  cd LibreOffice*/DEBS
  dpkg -i *.deb
fi

if [[ "$VARIANT" != "slim" ]]; then
  # install Microsoft fonts
  apt install -y ttf-mscorefonts-installer
  # install fonts for special characters, such as chinese ideograms
  apt install -y fonts-wqy-zenhei
fi

# ensure the latest version of npm
npm i -g npm
# install pnpm
npm i -g pnpm

if [[ "$VARIANT" == "full" ]]; then
  # install cloudflared, and tmate
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg > /usr/share/keyrings/cloudflare-main.gpg
  echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared noble main' > /etc/apt/sources.list.d/cloudflared.list
  apt update && apt install -y cloudflared tmate
fi

if [[ "$VARIANT" != "slim" ]]; then
  # install packages globally
  npm i -g \
            @angular/cli \
            @stencil/core \
            @ionic/cli \
            http-server \
            jshint \
            uglify-js \
            typescript
  # FIXME minizlib@3.0.1 breaks npm
  npm i -g minizlib@3.0.0
fi

# install playwright & deps
npm i -g playwright
if [ "$dpkgArch" = "arm64" ]; then
  playwright install chromium --with-deps
else
  playwright install chrome --with-deps
fi

if [[ "$VARIANT" != "slim" ]]; then
  # install code-server
  curl -fsSL https://code-server.dev/install.sh | sh
fi

if [[ "$VARIANT" != "slim" ]]; then
  # support for remote desktop via browser (novnc)
  export DEBIAN_FRONTEND=noninteractive
  apt install -y  tzdata keyboard-configuration \
                  xvfb dbus-x11 x11vnc openssl xfce4 adwaita-icon-theme supervisor \
                  zenity
fi

# hacky - to get chrome started properly in xfce environment, i.e. exo-open https://google.com.au
if [[ -x /opt/google/chrome/google-chrome ]]; then
  sed -i '/exec -a/ d' /opt/google/chrome/google-chrome
  echo 'exec -a "$0" "$HERE/chrome" --no-sandbox --disable-fre --no-default-browser-check --no-first-run --password-store=basic "$@"' >> /opt/google/chrome/google-chrome
fi

if [[ "$VARIANT" != "slim" ]]; then
  # set ionic global config
  cd /tmp
  npm init -y
  tsc --init
  sed -i '/noUncheckedSideEffectImports/d' tsconfig.json # stencil doesn't support this option yet
  touch stencil.config.js index.js
  echo 'exports.config = {};' > stencil.config.js
  stencil telemetry off
  ionic config set -g npmClient npm
  ionic config set -g telemetry false

  rm -rf package.json tsconfig.json
  chown node:node stencil.config.js index.js
  gosu node npm init -y
  gosu node tsc --init
  gosu node sed -i '/noUncheckedSideEffectImports/d' tsconfig.json # stencil doesn't support this option yet
  gosu node stencil telemetry off
  gosu node ionic config set -g npmClient npm
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
fi

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
npm cache clean --force
