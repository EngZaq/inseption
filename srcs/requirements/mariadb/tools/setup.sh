#!/bin/sh
set -eu

: "${MYSQL_DATABASE:?Missing MYSQL_DATABASE}"
: "${MYSQL_USER:?Missing MYSQL_USER}"

DB_PASS=$(cat /run/secrets/db_password)
ROOT_PASS=$(cat /run/secrets/db_root_password)

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initializing MariaDB..."

    mariadb-install-db \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --skip-test-db

    mariadbd \
        --user=mysql \
        --skip-networking \
        --socket=/run/mysqld/mysqld.sock &
    pid=$!

    until mariadb-admin --protocol=socket ping --silent; do
        if ! kill -0 "$pid" 2>/dev/null; then
            echo "MariaDB failed to start" >&2
            exit 1
        fi
        sleep 1
    done

    mariadb --protocol=socket <<SQL
ALTER USER 'root'@'localhost'
    IDENTIFIED BY '${ROOT_PASS}';

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%'
    IDENTIFIED BY '${DB_PASS}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.*
    TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
SQL

    mariadb-admin --protocol=socket \
        -uroot -p"${ROOT_PASS}" shutdown

    wait "$pid"
fi

echo "Starting MariaDB..."
exec mariadbd --user=mysql --console
