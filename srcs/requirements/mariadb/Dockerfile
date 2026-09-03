# bookworm is the name of the debian 12 (is not the latest version)
FROM debian:bookworm


# install mariadb-server, then remove the data directory that the
# package's post-install scripts create automatically during build:
# without this, Docker would copy that pre-existing content into
# our empty named volume on first start, tricking our script into
# thinking the database is already initialized
RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/mysql/* \
    && rm -rf /var/lib/apt/lists/*

# copy custom config to make MariaDB listen on all network interfaces,
# not just localhost, so other containers can reach it
COPY conf/mariadb.cnf /etc/mysql/mariadb.conf.d/inception.cnf

# copy from relative rute of the VM (where is the Docker )to the standard linux for conveninence
COPY tools/mariadb.sh /usr/local/bin/mariadb.sh

# enables execution permission of the scrip
RUN chmod +x /usr/local/bin/mariadb.sh

# this not open new port, just wait to use this port || 3306 is the standard port on which it listens
EXPOSE 3306

# This script is the only one executing when the process start
# square brackets with quotation marks (["command"]), called "exec form" to prevent unwanted processes that could be a problem with signals
ENTRYPOINT ["/usr/local/bin/mariadb.sh"]
