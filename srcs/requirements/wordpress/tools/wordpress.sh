#!/bin/bash
# stop the script immediately if any command fails
set -e

# read the wp_user password early, needed both for the readiness
# check below and later for creating wp-config.php
DB_PASSWORD=$(cat /run/secrets/db_password)
ADMIN_PASSWORD=$(grep WP_ADMIN_PASSWORD /run/secrets/credentials | cut -d '=' -f2-)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)


# wait until MariaDB (another container) is ready to accept connections
# before trying to install WordPress against it
# using wp_user here (not root) since root only allows connections
# from localhost, not from other containers (least privilege)
until mysqladmin ping -h mariadb -u"${MYSQL_USER}" -p"${DB_PASSWORD}" --silent; do
    sleep 1
done

# check if this is the first run: wp-config.php only exists once
# WordPress has already been downloaded and configured
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "wp-config.php not found, downloading and configuring WordPress..."
    wp core download --path=/var/www/html --allow-root

    wp config create \
        --path=/var/www/html \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost=mariadb \
        --allow-root
else
    echo "wp-config.php already exists, skipping download and config."
fi

# step 2: install WordPress (creates the admin user) if it doesn't exist yet
# checking the file alone isn't enough here: wp core install can report
# success even if the admin user wasn't actually created (e.g. empty
# variable), so we verify the user explicitly instead of trusting it
if wp user get "${WP_ADMIN_USER}" --path=/var/www/html --allow-root > /dev/null 2>&1; then
    echo "Admin user already exists, skipping wp core install."
else
    echo "Admin user not found, running wp core install..."
    wp core install \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root

    # verify again right after: if it still doesn't exist, something
    # is genuinely wrong (e.g. a required variable is empty) and we
    # want the script to fail loudly instead of continuing silently
    if wp user get "${WP_ADMIN_USER}" --path=/var/www/html --allow-root > /dev/null 2>&1; then
        echo "Admin user created and verified successfully."
    else
        echo "ERROR: admin user was not created correctly. Aborting."
        exit 1
    fi
fi

# step 3: create the second (non-admin) user if it doesn't exist yet
if wp user get "${WP_USER}" --path=/var/www/html --allow-root > /dev/null 2>&1; then
    echo "Second user already exists, skipping wp user create."
else
    echo "Second user not found, creating..."
    wp user create \
        --path=/var/www/html \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root

    if wp user get "${WP_USER}" --path=/var/www/html --allow-root > /dev/null 2>&1; then
        echo "Second user created and verified successfully."
    else
        echo "ERROR: second user was not created correctly. Aborting."
        exit 1
    fi
fi

# step 4: bonus - set up Redis object caching for WordPress
# WP_REDIS_HOST: the redis service, reachable by its Docker service name
# WP_REDIS_PORT: redis's standard port, --raw so it's stored as a real
# PHP integer (without --raw, wp-cli would quote it as a string)
wp config set WP_REDIS_HOST redis --path=/var/www/html --allow-root
wp config set WP_REDIS_PORT 6379 --path=/var/www/html --allow-root --raw

# check if the redis-cache plugin is already installed and active
if wp plugin is-active redis-cache --path=/var/www/html --allow-root > /dev/null 2>&1; then
    echo "Redis plugin is running successfully."
else
    echo "Redis starting..."
    wp plugin install redis-cache --activate --path=/var/www/html --allow-root

    if wp plugin is-active redis-cache --path=/var/www/html --allow-root > /dev/null 2>&1; then
        echo "Redis plugin installed and verified successfully."
    else
        echo "Error: redis plugin was not activated correctly. Aborting."
        exit 1
    fi
fi

# step 5: enable the redis-cache drop-in (the plugin can be "active"
# without this actually being enabled, as discovered while testing)
if wp redis status --path=/var/www/html --allow-root | grep -q "Status: Connected"; then
    echo "Redis object cache already enabled."
else
    echo "Enabling Redis object cache..."
    wp redis enable --path=/var/www/html --allow-root

    if wp redis status --path=/var/www/html --allow-root | grep -q "Status: Connected"; then
        echo "Redis object cache enabled and verified successfully."
    else
        echo "ERROR: Redis object cache was not enabled correctly. Aborting."
        exit 1
    fi
fi

# exec to replace the bash process and start php-fpm in the foreground as the container's main process (PID 1)
# -F to execute in foreground to keep (PID 1)
exec php-fpm8.2 -F
