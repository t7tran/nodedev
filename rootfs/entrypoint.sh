#!/bin/bash

export PATH=$PATH:`pwd`/node_modules/.bin
chown node:node /home/node/store 2>/dev/null

[[ `id -u` == '0' ]] && exec gosu node "$@" || exec "$@"