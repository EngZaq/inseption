#!/bin/sh
set -eu

: "${MYSQL_DATABASE:?Missing MYSQL_DATABASE}"
: "${MYSQL_USER:?Missing MYSQL_USER}"

DB_PASS=$(cat /run/secrets/db_password)
ROOT_PASS=$(cat /run/secrets/db_root_password)

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# Initialize system tables only once.
if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initializing MariaDB system tables..."

    mariadb-install-db \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --skip-test-db
fi

# Start MariaDB locally for database/user setup.
echo "Starting temporary MariaDB..."

mariadbd \
    --user=mysql \
    --skip-networking \
    --socket=/run/mysqld/mysqld.sock &

pid=$!

trap 'kill "$pid" 2>/dev/null || true' EXIT

ready=0
for i in $(seq 1 30); do
    if mariadb-admin --protocol=socket ping --silent; then
        ready=1
        break
    fi

    if ! kill -0 "$pid" 2>/dev/null; then
        echo "MariaDB startup failed" >&2
        exit 1
    fi

    sleep 1
done

if [ "$ready" -ne 1 ]; then
    echo "MariaDB startup timed out" >&2
    exit 1
fi

# Configure the WordPress database and account.
# On an existing installation, authenticate using
# the root password from the local secret.
if mariadb --protocol=socket -uroot \
    -p"$ROOT_PASS" -e "SELECT 1" >/dev/null 2>&1; then

    AUTH="-p$ROOT_PASS"

elif mariadb --protocol=socket -uroot \
    -e "SELECT 1" >/dev/null 2>&1; then

    AUTH=""

else
    echo "Cannot authenticate to MariaDB as root" >&2
    exit 1
fi

mariadb --protocol=socket -uroot $AUTH <<SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%'
    IDENTIFIED BY '${DB_PASS}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.*
    TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
SQL

# Set the root password on a fresh installation
# where root initially has passwordless socket access.
if [ -z "$AUTH" ]; then
    mariadb --protocol=socket -uroot <<SQL
ALTER USER 'root'@'localhost'
    IDENTIFIED BY '${ROOT_PASS}';
SQL
fi

echo "Stopping temporary MariaDB..."

mariadb-admin --protocol=socket \
    -uroot -p"$ROOT_PASS" shutdown

wait "$pid"
trap - EXIT

echo "Starting MariaDB normally..."

exec mariadbd --user=mysql --console
