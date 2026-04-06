#!/bin/bash

export PATH=$PATH:`pwd`/node_modules/.bin
[[ `id -u` == '0' ]] && chown node:node /home/node/store /home/node/.cache 2>/dev/null

[[ `id -u` == '0' ]] && exec gosu node "$@" || exec "$@"