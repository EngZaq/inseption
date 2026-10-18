*This project has been created as part of the 42 curriculum by zal-qais.*

# Inception

## Description

Inception is a 42 system administration project. It runs three independently built services inside a Debian 12 virtual machine, orchestrated by Docker Compose:

- **NGINX:** the only published entry point, HTTPS on port 443, TLS 1.2/1.3.
- **WordPress + PHP-FPM:** serves the PHP application on internal TCP port 9000.
- **MariaDB:** stores WordPress data on internal TCP port 3306.

Each image is built from a Debian Bookworm base using its own Dockerfile. Containers communicate through the `inception` bridge network. Two Docker named volumes preserve database and WordPress files through container recreation. Docker secrets supply passwords as mounted files.

**Request path:** browser → NGINX :443 → WordPress PHP-FPM :9000 → MariaDB :3306.

## Repository layout

```text
Makefile
README.md
USER_DOC.md
DEV_DOC.md
srcs/
  docker-compose.yml
  .env.example
  requirements/
    nginx/{Dockerfile,conf/,tools/}
    wordpress/{Dockerfile,conf/,tools/}
    mariadb/{Dockerfile,conf/,tools/}
secrets/                 # local only; ignored by Git
```

## Instructions

Run this project **inside a Linux virtual machine** with Docker Engine, Compose V2, Make, and internet access for image builds. See [DEV_DOC.md](DEV_DOC.md) for exact setup instructions, including Docker's data-root requirement and local secret creation.

After configuration:

```bash
make             # build and launch
make ps          # show service status
make logs        # follow logs
make down        # remove containers/network but preserve named volumes
make restart     # recreate containers
```

Map `zal-qais.42.fr` to the local VM IP address (or `127.0.0.1` when browsing inside the VM). Open `https://zal-qais.42.fr` and `https://zal-qais.42.fr/wp-admin`. The development TLS certificate is self-signed; the browser will display a trust warning.

## Design choices and comparisons

| Topic | Choice and reason | Alternative |
| --- | --- | --- |
| Virtual machine vs Docker | The Debian VM supplies an isolated guest OS; Docker isolates service processes inside that guest while sharing its kernel. Both are used, not substituted for each other. | A VM has its own kernel and higher resource overhead. |
| Secrets vs environment variables | Non-sensitive names and domain go into `srcs/.env`; passwords are local files mounted as Docker secrets. | Plain environment variables are easier to expose via configuration and diagnostics. |
| Docker network vs host network | A dedicated bridge network lets services resolve names such as `mariadb` and `wordpress`; only NGINX publishes 443. | Host networking removes this separation and is forbidden by the subject. |
| Named volumes vs bind mounts | Compose uses Docker-managed named volumes for both persistent directories, without `driver_opts: o: bind`. | Bind mounts expose a chosen host path directly and are forbidden for these two volumes in this subject. |

### Storage design

The current VM uses Docker's `data-root` set to `/home/zal-qais/data/docker` in `/etc/docker/daemon.json`. Hence ordinary Docker named volumes live beneath `/home/zal-qais/data/docker/volumes`. This is a **VM-level setup step**, not automatically configured by the Makefile. It also moves all Docker-managed image/container data, so inspect existing installations before changing it.

## Resources and AI usage

- [Docker Engine documentation](https://docs.docker.com/engine/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [WordPress CLI](https://wp-cli.org/)
- [MariaDB documentation](https://mariadb.com/docs/)

AI assistance was used to explain Docker, shell scripts, TLS, SSH, and container networking; help draft initial Dockerfiles, Compose, and startup scripts; and diagnose runtime errors (script format, WordPress user conflicts, volume permissions). Commands and configurations must be tested and understood by the project author; AI output is not a substitute for evaluation or peer review.

## Notes

The `secrets/` directory, `srcs/.env`, live database files, and VM image must not be committed. Never use `docker compose down -v` unless intentionally discarding the persistent site. This repository is a working implementation, but a full fresh-VM rebuild and final 42 peer-evaluation checks remain important.
