# base image
FROM debian:bookworm

# install php-fpm and required extensions:
# - php-fpm: runs PHP and speaks FastCGI to NGINX
# - php-mysql: lets PHP connect to MariaDB
# - php-curl: used by WordPress for HTTP requests (updates, checks, plugins)
# - php-gd: image handling (thumbnails, resizing)
# - php-mbstring: multibyte text handling (UTF-8, accents)
# - php-xml: used by WordPress (feeds, import/export)
# - php-zip: needed to install plugins/themes packed as .zip
# - curl: command-line tool to download WP-CLI later
# - mariadb-client provides mysqladmin/mysql to check DB readiness
# - php-redis: lets PHP connect to Redis (needed forr the redis-cache plugin)
RUN apt-get update && apt-get install -y \
	php-fpm \
	php-mysql \
	php-curl \
	php-gd \
	php-mbstring \
	php-xml \
	php-zip \
	curl \
	mariadb-client \
	php-redis \
	&& rm -rf /var/lib/apt/lists/*


# download WP-CLI's official stable build (maintained by the wp-cli
# project itself at this fixed, ever-current URL, in their dedicated
# "builds" repo — not a version-pinned release, since WP-CLI itself
# is a tool we run once, not part of the running application)
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# override the default php-fpm pool config to listen on a TCP port
# instead of a unix socket, so nginx (another container) can reach it
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# copy the entrypoint script (same pattern as MariaDB)
COPY tools/wordpress.sh /usr/local/bin/wordpress.sh
RUN chmod +x /usr/local/bin/wordpress.sh

# 9000 is the standard port php-fpm listens on for fastCGI connections
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wordpress.sh"]
