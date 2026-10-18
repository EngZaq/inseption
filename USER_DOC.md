# Inception — User Documentation

## Services provided

This stack hosts a WordPress website. NGINX serves HTTPS on port 443, WordPress runs with PHP-FPM, and MariaDB stores the site's database. The latter two services are reachable only on the internal Docker network.

## Start and stop

Run the commands from the repository root (`~/inception` in the original VM):

```bash
make         # builds and starts the stack
make ps      # displays container status
make logs    # live logs; Ctrl+C exits the log viewer
make stop    # stops containers
make start   # starts stopped containers
make down    # removes containers/network; retains named volumes
make restart # removes/recreates containers; retains named volumes
```

`make clean` also removes locally built service images, but does not intentionally delete volumes.

## Website and administration

- Site: `https://zal-qais.42.fr`
- Dashboard: `https://zal-qais.42.fr/wp-admin`
- Local hostname resolution must map that name to the VM's reachable IP, or to `127.0.0.1` when browsing *inside* the VM.
- The current locally generated certificate is self-signed. Check the hostname and certificate before accepting a browser exception; it is not publicly trusted.

Log in with the WordPress administrator username specified by `WP_ADMIN_USER` in the VM's local `srcs/.env`. It cannot contain `admin` or `administrator`. The site also has a second, non-administrator account. The MariaDB account `MYSQL_USER` is **not** a WordPress login.

## Credentials

- Non-secret configuration: `srcs/.env` (local, ignored by Git)
- Password files: `secrets/db_password.txt`, `secrets/db_root_password.txt`, `secrets/wp_admin_password.txt`, `secrets/wp_user_password.txt` (local, ignored by Git)
- Never commit, paste, or publicly share password file contents.
- On an already initialized installation, modifying initial setup variables does not automatically rename existing WordPress accounts or reset their passwords. Change existing users through the WordPress administration interface or carefully with WP-CLI.

## Verify service health

```bash
make ps
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs --tail=30
curl -kI https://zal-qais.42.fr
```

A successful basic HTTPS request should return `HTTP/1.1 200 OK`. The `-k` flag is only for a self-signed development certificate. A container listed briefly as `Up` might still be restarting; inspect logs if the website fails.

To list WordPress accounts without showing passwords:

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env exec wordpress wp user list --allow-root
```

## Persistent data and backups

The `srcs_mariadb_data` and `srcs_wordpress_data` named volumes hold the database and WordPress files. On the configured VM they live beneath `/home/zal-qais/data/docker/volumes/`. Normal container recreation keeps them. Back up the data before performing storage migration or destructive operations, and keep backups outside the VM.

**Warning:** `docker compose down -v` or `docker volume rm` can permanently delete site data. Do not use these for ordinary shutdown.
