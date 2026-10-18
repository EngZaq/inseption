
FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nginx openssl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

COPY conf/default.conf /etc/nginx/sites-available/default
COPY tools/setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/setup.sh"]
