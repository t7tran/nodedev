ARG NODE_VERSION

FROM caddy:2 AS caddy

FROM node:${NODE_VERSION:?}-bookworm-slim

COPY --from=caddy /usr/bin/caddy /usr/bin/
COPY --chown=node:node ./rootfs /

RUN . /build.sh && \
    rm -rf /build.sh

ENTRYPOINT ["/entrypoint.sh"]
