#!/bin/bash
#stop if a command fails
set -e


# create the runtime directory MariaDB needs for its socket file
# (normally created by systemd on a real system, but there's no
# systemd inside a container, so we do it ourselves on every start)
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld


# check if this is the first run: MariaDB creates a "mysql" subfolder
# inside the datadir once it has been initialized, so its absence
# means the volume is empty (first boot)
if [ ! -d "/var/lib/mysql/mysql" ]; then
    	echo "First run, initializing MariaDB..."

	# create the base directory structure MariaDB needs to run
    	mariadb-install-db --user=mysql --datadir=/var/lib/mysql
	# start MariaDB temporarily in the background (&) so the script
        # can keep running the next lines instead of blocking here
	mysqld_safe --datadir=/var/lib/mysql &
	#wait (retry every second) until the server is ready to accept
	#connections, before trying to run any SQL against it
	until mysqladmin ping --silent; do
		sleep 1
	done
	
	#read passwords from docker secrets (never hardcoded)
	DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
	DB_PASSWORD=$(cat /run/secrets/db_password)

	#create the WordPress database, its user,  grant privileges,
	#and set a password for root (empty by default otherwise that means backdoor open)
	mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

	#cleanly stop the temporary background server: the final,
	#real server process will be started in foreground below
	mysqladmin -u root -p"${DB_ROOT_PASSWORD}" shutdown
fi

# start MariaDB in the foreground as the container's main process (PID 1)
# exec replace the bash for the  executed mysqld to be PID 1 with mysqld
exec mysqld --user=mysql --datadir=/var/lib/mysql


