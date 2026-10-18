#!/bin/sh
set -eu

CERT=/etc/nginx/ssl/inception.crt
KEY=/etc/nginx/ssl/inception.key

if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
    echo "Generating TLS certificate..."

    openssl req -x509 -nodes \
        -days 365 \
        -newkey rsa:2048 \
        -keyout "$KEY" \
        -out "$CERT" \
        -subj "/CN=zal-qais.42.fr"

    chmod 600 "$KEY"
fi

echo "Checking NGINX configuration..."
nginx -t

echo "Starting NGINX..."
exec nginx -g 'daemon off;'
