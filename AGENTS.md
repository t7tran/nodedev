# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this repo is

This repo builds a Docker image (`ghcr.io/t7tran/nodedev`) that is a batteries-included Node.js
development environment. It is **not** a Node.js application — there is no `package.json` at the root.
The "code" is almost entirely the Dockerfile plus a `rootfs/` overlay and a large provisioning shell
script. The end product is a container that a developer runs against their own project directory.

## Build & test

There is no local build/test tooling; images are built via `docker buildx` (see `.github/workflows/`).
To build a variant locally, mirror what CI does:

```bash
# full variant (default), Node LTS
docker buildx build --build-arg NODE_VERSION=lts -t nodedev:lts .

# slim variant
docker buildx build --build-arg NODE_VERSION=lts --build-arg VARIANT=slim -t nodedev:lts-slim .

# developer variant
docker buildx build --build-arg NODE_VERSION=lts --build-arg VARIANT=dev -t nodedev:lts-dev .
```

`NODE_VERSION` accepts `lts`, `current`, or a major version (`18`, `20`, `22`) — it is passed straight
to the `node:${NODE_VERSION}-bookworm-slim` base image tag. CI builds `linux/amd64,linux/arm64`;
`rootfs/build.sh` branches on `$dpkgArch` (`arm64` vs `amd64`) for several downloads, so any new tool
install must handle both architectures.

To "test" a change, build the image and run it the way the README documents:

```bash
docker run -u $(id -u):$(id -g) -it --rm -v "$PWD":"$PWD":z -w "$PWD" nodedev:lts bash
```

## Architecture

Three files carry essentially all the logic:

- **`Dockerfile`** — thin. Copies the Caddy binary from `caddy:2`, overlays `rootfs/` onto `/`, sets
  `PATH`/`DISPLAY`/`RESOLUTION`/`TZ`, then runs `bash /build.sh ${VARIANT}` and deletes it. Entrypoint
  is `/entrypoint.sh`.
- **`rootfs/build.sh`** — the heart of the image. A single provisioning script run at build time that
  installs every tool. Pinned tool versions live in the `*_VERSION` variables at the top.
- **`rootfs/`** — files overlaid onto the container filesystem verbatim (`chown node:node`), e.g.
  `entrypoint.sh`, supervisor config, XFCE startup, and the `node` user's shell dotfiles.

### The VARIANT axis (most important concept)

`build.sh` takes one argument, `VARIANT` (default `full`), and gates installs with three tiers.
When adding or moving a tool, put it in the correct tier:

- **slim** — the base. Only unconditional installs run (git, curl, jq, yq, gosu, sqlite3, python3-pip,
  npm/pnpm, antigravity CLI, uv, playwright). Everything wrapped in a variant check is excluded.
- **`!= slim`** (i.e. `full` **and** `dev`) — adds interactive/CLI tooling: hstr, mc, tilix, vim,
  supercronic, git-credential-oauth, mysql/postgres clients, MS fonts, gcloud SDK, global npm packages
  (`@angular/cli`, `@ionic/cli`, `@stencil/core`, typescript, …), code-server, VSCodium, Claude
  Desktop, ttyd, and the browser-based remote desktop stack (Xvfb + x11vnc + noVNC + XFCE).
- **`== full`** — the heaviest additions: Chromium + Cypress/Playwright browser deps, the Docker CLI
  (+ docker-compose), graphviz/JRE for PlantUML, LibreOffice, cloudflared, tmate.

Note the guards are literal string comparisons. `dev` gets everything `!= slim` provides but **not**
the `== full` block — so, e.g., Docker CLI and LibreOffice are full-only.

### Runtime model

- **`rootfs/entrypoint.sh`** prepends `./node_modules/.bin` to `PATH`, and if started as root
  (`id -u == 0`) `chown`s the persistent dirs and drops to the `node` user via `gosu`; otherwise it
  `exec`s the command directly. The README runs it with `-u $(id -u):$(id -g)` so the container matches
  the host user and bind-mounted files stay writable — the non-root path.
- **Remote desktop** (non-slim): `supervisord` (`rootfs/etc/supervisord.conf`) supervises Xvfb on
  `:0`, x11vnc on `5901`, noVNC/websockify on `6901`, and XFCE via `rootfs/usr/bin/xstartup`. This is
  only wired up if the container is started with supervisord as its command.
- **Persistence**: `/home/node/store` (bash history) and `/home/node/.cache` are the dirs
  `entrypoint.sh` fixes ownership on — intended as mount points that survive container recreation.

### Recurring workarounds to preserve

Several installs carry non-obvious fixes; keep them when editing nearby code:

- GUI Electron/Chromium apps (Chrome, VSCodium, Claude Desktop) are launched with `--no-sandbox` and
  `--password-store=basic` — the container has no sandbox and no unlockable keyring in the VNC session.
- Claude Desktop's 217 MB `/usr/bin/claude-desktop` is replaced with a small wrapper script for the
  flags above; `update-desktop-database` is run so the `claude://` OAuth callback scheme resolves.
- `minizlib` is pinned to `3.0.0` (3.0.1 breaks npm).
- `git-credential-oauth` and `docker-compose` are pinned versions fetched from GitHub releases.

## Conventions

- Tool versions are pinned via `*_VERSION` variables at the top of `build.sh`; upgrade there, not inline.
  A commit that bumps a tool is the standard change in this repo (see git history).
- `build.sh` runs under `set -e`; keep it idempotent-ish and fail-fast. Group related installs and add a
  brief comment saying what each block installs, matching the existing style.
- Clean up at the end (the tail of `build.sh` does `apt clean`, removes apt lists, `/tmp`, npm cache) —
  don't leave build artefacts that bloat image layers.
