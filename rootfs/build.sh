#!/usr/bin/env bash

DOCKER_COMPOSE_VERSION=5.1.4
GIT_CREDENTIAL_OAUTH_VERSION=0.17.2-p.1
LIBRE_OFFICE_VERSION=26.2.4
NODE_MAJOR_VERSION=`node -v | cut -d. -f1 | sed 's/v//'`
SUPERCRONIC_VERSION=0.2.46
TTYD_VERSION=1.7.7
VARIANT=${1:-full}
YQ_VERSION=4.53.3

set -e

dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"

# activate contrib
sed -i 's/^Components: main$/& contrib/' /etc/apt/sources.list.d/debian.sources
apt update && apt upgrade -y && apt autoremove -y

# apk add git curl ncurses dpkg hstr
apt install -y git git-lfs curl jq dpkg iputils-ping

# install yq
curl -fsSL https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION:?}/yq_linux_${dpkgArch} -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq

if [[ "$VARIANT" != "slim" ]]; then
  apt install -y hstr mc tilix vim

  curl -fsSL https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION:?}/supercronic-linux-amd64 -o /usr/local/bin/supercronic
  chmod +x /usr/local/bin/supercronic

  # install git-credential-oauth
  # curl -fsSL https://github.com/hickford/git-credential-oauth/releases/download/v${GIT_CREDENTIAL_OAUTH_VERSION:?}/git-credential-oauth_${GIT_CREDENTIAL_OAUTH_VERSION:?}_linux_${dpkgArch}.tar.gz | tar -C /usr/bin -xvzf - --wildcards --no-anchored git-credential-oauth
  curl -fsSL https://github.com/t7tran/git-credential-oauth/releases/download/v${GIT_CREDENTIAL_OAUTH_VERSION:?}/git-credential-oauth_${GIT_CREDENTIAL_OAUTH_VERSION:?}_linux_${dpkgArch}.tar.gz | tar -C /usr/bin -xvzf - --wildcards --no-anchored git-credential-oauth
fi

# install gosu
curl -fsSL "https://github.com/tianon/gosu/releases/download/1.19/gosu-$dpkgArch" -o /usr/local/bin/gosu
chmod +x /usr/local/bin/gosu
gosu nobody true

if [[ "$VARIANT" == "full" ]]; then
  # Installs latest Chromium package for testing
  apt install -y chromium chromium-l10n ca-certificates fonts-freefont-ttf libnss3 libharfbuzz-bin
  apt install -y libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth

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
curl -L https://www.npmjs.com/install.sh | sh
# install pnpm
npm i -g pnpm

if [[ "$VARIANT" == "full" ]]; then
  # install cloudflared, and tmate
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg > /usr/share/keyrings/cloudflare-main.gpg
  echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared noble main' > /etc/apt/sources.list.d/cloudflared.list
  apt update && apt install -y cloudflared tmate
fi

if [[ "$VARIANT" != "slim" ]]; then
  # install gcloud SDK -----------------------------------------------------
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
  apt update && apt install -y google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin
  gosu node gcloud config set core/disable_usage_reporting true
  gosu node gcloud config set component_manager/disable_update_check true
  gosu node gcloud config set metrics/environment github_docker_image
  echo -e '[compute]\ngce_metadata_read_timeout_sec = 30' >> /usr/lib/google-cloud-sdk/properties

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

# install antigravity cli
curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir /usr/local/bin
if [[ "$VARIANT" == "slim" ]]; then
  # install keyring required for antigravity cli auth token storage
  apt install -y dbus-x11 gnome-keyring libsecret-tools
fi

# install uv - for installing tools like crewai
curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh

# install playwright & deps
npm i -g playwright
if [ "$dpkgArch" = "arm64" ]; then
  playwright install chromium --with-deps
else
  playwright install chrome --with-deps
fi

if [[ "$VARIANT" != "slim" ]]; then
  # certutil is needed to import certificates into chrome NSS trust store
  apt install -y libnss3-tools

  # install code-server
  curl -fsSL https://code-server.dev/install.sh | sh

  # install codium
  curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor -o /usr/share/keyrings/vscodium-archive-keyring.gpg
  echo -e 'Types: deb\nURIs: https://download.vscodium.com/debs\nSuites: vscodium\nComponents: main\nArchitectures: amd64 arm64\nSigned-by: /usr/share/keyrings/vscodium-archive-keyring.gpg' > /etc/apt/sources.list.d/vscodium.sources
  apt update
  apt install -y codium
  sed -i 's/"$ELECTRON" "$CLI"/"$ELECTRON" "$CLI" --no-sandbox/g' /usr/share/codium/bin/codium
  sed -i 's#Exec=/usr/share/codium/codium#Exec=/usr/share/codium/codium --no-sandbox#g' /usr/share/applications/codium.desktop
  sed -i 's#Exec=/usr/share/codium/codium#Exec=/usr/share/codium/codium --no-sandbox#g' /usr/share/applications/codium-url-handler.desktop

  # install claude-desktop (official Anthropic apt repo: https://code.claude.com/docs/en/desktop-linux)
  curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc https://downloads.claude.ai/claude-desktop/key.asc
  cat > /etc/apt/sources.list.d/claude-desktop.sources <<EOF
Types: deb
URIs: https://downloads.claude.ai/claude-desktop/apt/stable
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/claude-desktop-archive-keyring.asc
Architectures: ${dpkgArch}
EOF
  apt update
  apt install -y claude-desktop
  # the official package ships an electron binary at /usr/bin/claude-desktop (a 217MB copy
  # of /usr/lib/claude-desktop/claude-desktop); replace it with a wrapper that forces
  # --no-sandbox so it can run in the container (chromium refuses to start otherwise)
  rm -f /usr/bin/claude-desktop
  cat > /usr/bin/claude-desktop <<'EOF'
#!/bin/sh
exec /usr/lib/claude-desktop/claude-desktop --no-sandbox "$@"
EOF
  chmod +x /usr/bin/claude-desktop

  # install ttyd for terminal over http
  if [ "$dpkgArch" = "arm64" ]; then
    curl -fsSLo /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION:?}/ttyd.aarch64
  else
    curl -fsSLo /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION:?}/ttyd.x86_64
  fi
  chmod +x /usr/local/bin/ttyd

  # support for remote desktop via browser
  export DEBIAN_FRONTEND=noninteractive
  apt install -y  tzdata keyboard-configuration \
                  xvfb dbus-x11 x11vnc openssl xfce4 adwaita-icon-theme supervisor \
                  zenity \
                  desktop-file-utils \
                  thunar-archive-plugin

  # build the desktop MIME/scheme handler cache so the browser can hand custom URL
  # schemes back to their apps - in particular claude:// so that Claude Desktop's
  # browser-based OAuth login returns to the app once authentication completes.
  # the claude-desktop package can't do this on install because desktop-file-utils
  # (and thus its dpkg trigger) isn't present at that point.
  update-desktop-database /usr/share/applications
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
