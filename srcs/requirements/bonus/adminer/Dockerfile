# base image
FROM debian:bookworm

# install php-fpm to run adminer, php-mysql so it can connect to
# MariaDB, and curl to download it
RUN apt-get update && apt-get install -y \
	php-fpm \
	php-mysql \
	curl \
	&& rm -rf /var/lib/apt/lists/*

# download adminer (a single-file database management tool),
# a fixed version for reproducibility, not "latest"
RUN mkdir -p /var/www/html && \
	curl -L -o /var/www/html/index.php \
	https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php

# override the default php-fpm pool config to listen on a TCP port
# instead of a unix socket, so nginx (another container) can reach it
COPY www.conf /etc/php/8.2/fpm/pool.d/www.conf

EXPOSE 9001

ENTRYPOINT ["php-fpm8.2", "-F"]
