
FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    php-fpm php-mysql php-curl php-xml \
    php-mbstring php-zip curl ca-certificates \
    mariadb-client && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/php /var/www/html

RUN curl -fsSL \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -o /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup.sh"]

