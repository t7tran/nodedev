ARG NODE_VERSION
ARG VARIANT

FROM caddy:2 AS caddy

FROM node:${NODE_VERSION:?}-bookworm-slim
ARG VARIANT

COPY --from=caddy /usr/bin/caddy /usr/bin/
COPY --chown=node:node ./rootfs /

ENV PATH=/home/node/.npm-packages/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    DISPLAY=:0 \
    RESOLUTION=1280x720 \
    TZ=Australia/Melbourne

RUN bash /build.sh ${VARIANT} && \
    rm -rf /build.sh

ENTRYPOINT ["/entrypoint.sh"]
