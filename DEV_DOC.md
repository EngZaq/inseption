# Inception — Developer Documentation

## Prerequisites

Use a Debian 12 Linux **virtual machine** (the Docker host), Docker Engine, Docker Compose V2 (`docker compose`), Git, Make, OpenSSL, and internet access during builds. Running directly on the 42 desktop without a VM does not satisfy this project's VM requirement. Ensure the VM has sufficient disk space and permission to publish HTTPS port 443.

## Fresh VM preparation

The subject requires the named-volume contents to be stored under `/home/zal-qais/data` and forbids bind-backed volumes. This implementation uses ordinary Docker named volumes and configures Docker's storage root in the VM:

```bash
sudo systemctl stop docker.service docker.socket
sudo mkdir -p /home/zal-qais/data/docker /etc/docker
```

For a **fresh Docker installation with no existing Docker state**, create `/etc/docker/daemon.json`:

```json
{ "data-root": "/home/zal-qais/data/docker" }
```

Then run `sudo systemctl start docker` and verify `docker info --format '{{.DockerRootDir}}'`. **Do not overwrite an existing Docker daemon configuration or move an existing data-root without separately backing up and migrating its images and volumes.** The data-root change affects all Docker-managed data, not only this project.

For a different 42 login, change the host directory path and domain to match your account. Verify the actual 42 subject/evaluation environment before using a custom daemon location.

## Clone, configure, and run

```bash
git clone git@github.com:EngZaq/inseption.git inception
cd inception
cp srcs/.env.example srcs/.env
nano srcs/.env
mkdir -p secrets
umask 077
openssl rand -hex 24 > secrets/db_password.txt
openssl rand -hex 24 > secrets/db_root_password.txt
openssl rand -hex 24 > secrets/wp_admin_password.txt
openssl rand -hex 24 > secrets/wp_user_password.txt
chmod 600 secrets/*.txt
make
make ps
```

Choose distinct, valid WordPress email addresses and a non-`admin` administrator username. The project uses `srcs/.env` for configuration values and Docker secrets for passwords. A fresh installation creates volumes with Compose. Existing installations might have volumes created manually; inspect before migrating or deleting them.

Add the required local hostname mapping inside the VM (or on the client connecting to the VM), for example `127.0.0.1 zal-qais.42.fr` in `/etc/hosts` if the browser is running in the VM. Open `https://zal-qais.42.fr`.

## Source layout and runtime behavior

- `srcs/requirements/mariadb/Dockerfile`: Debian + MariaDB. `tools/setup.sh` initializes a new database/user and executes `mariadbd` in the foreground.
- `srcs/requirements/wordpress/Dockerfile`: Debian + PHP-FPM and WP-CLI. `tools/setup.sh` waits for MariaDB, installs WordPress when missing, creates two users, and executes `php-fpm8.2 -F`.
- `srcs/requirements/nginx/Dockerfile`: Debian + NGINX/OpenSSL. The startup script creates a development TLS certificate and runs NGINX in the foreground.
- `srcs/docker-compose.yml`: three containers, bridge network, two named volumes, secrets, and port 443 only.
- `Makefile`: common lifecycle commands; builds images through Compose.

Each service uses a dedicated container and main foreground process rather than `tail -f` or a sleep loop.

## Maintenance commands

```bash
make                # build and start
make down           # remove containers and project network; volumes survive
make restart        # rebuild/recreate with existing data
make logs
make ps
docker volume ls
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
docker network inspect srcs_inception
docker compose -f srcs/docker-compose.yml --env-file srcs/.env config --quiet
```

The volume mountpoints should be under `/home/zal-qais/data/docker/volumes/`, and inspection should show no bind-backed driver options. Never use `down -v` or remove volumes as a normal reset operation.

## Diagnostics

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env ps -a
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs --tail=50 mariadb wordpress nginx
curl -kI https://zal-qais.42.fr
openssl s_client -connect localhost:443 -tls1_2 </dev/null
openssl s_client -connect localhost:443 -tls1_3 </dev/null
```

- `exec format error`: verify the startup script begins with `#!/bin/sh` at byte 1, has Unix LF line endings, and rebuild the affected image.
- MariaDB `Permission denied`: inspect volume ownership; the database process needs writable access as `mysql`. Do not apply world-writable permissions or erase data.
- WordPress `Error establishing a database connection`: verify MariaDB logs, credentials, and availability on the bridge network.
- `502 Bad Gateway`: verify PHP-FPM is healthy and NGINX can resolve `wordpress:9000`.
- Duplicate WordPress email: inspect existing users with WP-CLI; do not reset the database as a shortcut.

## Persistent storage and safe backups

The database volume mounts at `/var/lib/mysql`; the site volume mounts at `/var/www/html` (NGINX reads it read-only). On the custom Docker root, inspect the actual mountpoint with `docker volume inspect` rather than assuming a path. To take consistent backups, stop the application and database first (e.g. `make down`), archive the two named-volume contents or take a database dump, and copy the backup outside the VM. Restore with containers stopped and preserve correct ownership. Never commit backup archives or secrets.

## Evaluation preparation

Validate a clean setup from the Git repository, the VM requirement, image build paths and names, allowed base images, domain mapping, two WordPress users, TLS 1.2/1.3 only, published port 443 only, Docker secrets, automatic restart, named-volume persistence, and documentation. The current documentation describes the implemented environment; it does **not** claim a fresh-VM reproduction was already tested.
