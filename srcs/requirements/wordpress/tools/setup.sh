#!/bin/sh
set -eu

cd /var/www/html

DB_PASS="$(cat /run/secrets/db_password)"
ADMIN_PASS="$(cat /run/secrets/wp_admin_password)"
USER_PASS="$(cat /run/secrets/wp_user_password)"

echo "Waiting for MariaDB..."

ready=0
for i in $(seq 1 30); do
    if mariadb-admin ping \
        -h mariadb \
        -u"$MYSQL_USER" \
        -p"$DB_PASS" --silent 2>/dev/null; then
        ready=1
        break
    fi
    sleep 2
done

if [ "$ready" -ne 1 ]; then
    echo "MariaDB is not ready" >&2
    exit 1
fi

if [ ! -f wp-includes/version.php ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root
fi

if [ ! -f wp-config.php ]; then
    echo "Configuring WordPress..."
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASS" \
        --dbhost=mariadb:3306 \
        --allow-root
fi

if ! wp core is-installed --allow-root; then
    echo "Installing WordPress..."

    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="Inception42" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$ADMIN_PASS" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root
fi


if wp user get "$WP_USER" --allow-root >/dev/null 2>&1; then
    echo "WordPress user already exists."
elif wp user list --field=user_email --allow-root |
    grep -Fxq "$WP_USER_EMAIL"; then
    echo "ERROR: Email is already registered to another user." >&2
    exit 1
else
    echo "Creating second WordPress user..."

    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$USER_PASS" \
        --allow-root
fi


chown -R www-data:www-data /var/www/html
chmod 640 /var/www/html/wp-config.php

echo "WordPress ready. Starting PHP-FPM..."

exec php-fpm8.2 -F
