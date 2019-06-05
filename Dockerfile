FROM node:lts-alpine

COPY ./rootfs /

RUN apk add --no-cache bash git ncurses mc && \
    cd /home/node && \
    git clone --depth=1 https://github.com/Bash-it/bash-it.git .bash_it && \
    ln -s /home/node/coolersport /home/node/.bash_it/themes/coolersport && \
    chown -R node:node /home/node && \
    chmod +x /entrypoint.sh && \
    su -s /bin/bash node -c 'export BASH_IT=/home/node/.bash_it && \
                             source /home/node/.bash_it/bash_it.sh && \
                             bash-it enable completion defaults dirs git npm && \
                             bash-it enable plugin base edit-mode-vi'

ENTRYPOINT ["/entrypoint.sh"]