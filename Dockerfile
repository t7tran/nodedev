ARG NODE_VERSION

FROM caddy:2 AS caddy

FROM node:${NODE_VERSION:?}-bookworm-slim

COPY --from=caddy /usr/bin/caddy /usr/bin/
COPY --chown=node:node ./rootfs /

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/node/.npm-packages/bin

RUN . /build.sh && \
    rm -rf /build.sh

ENTRYPOINT ["/entrypoint.sh"]
