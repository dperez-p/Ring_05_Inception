# Developer Documentation

## Setting up the environment from scratch

### Prerequisites
1. A virtual machine running **Debian 12 (Bookworm)** -- the
   "penultimate stable" version required by the subject, installed
   with only "SSH server" and "standard system utilities" (no
   desktop environment needed).
2. Update the system:
```bash
   sudo apt update && sudo apt upgrade -y
```
3. Install Docker Engine and the Docker Compose plugin, following
   Docker's official installation guide for Debian (using their
   official APT repository, not the outdated `docker.io` package
   from Debian's own repos):
   https://docs.docker.com/engine/install/debian/
4. Install `make`:
```bash
   sudo apt install -y make
```

### Configuration files and secrets

Before building the project, two things must be set up:

- **`srcs/.env`**: contains non-sensitive configuration (domain name,
database name, usernames). See `README.md` for the full list of variables.
- **`secrets/`**: contains all passwords, as individual files. See the "Secrets format" section in `README.md` for the exact format and an example of each file.

Neither of these is included in the repository (both are git-ignored), so they must be created manually on each new setup.

## Building and launching the project

The `Makefile`, at the root of the project, wraps the Docker Compose commands:

```bash
make        # builds the images (if needed) and starts all containers
make down   # stops the containers
make clean  # stops the containers and removes the built images
make fclean # clean + removes all persistent data (full reset)
make re     # fclean + make (full rebuild from scratch)
```

Under the hood, these targets call Docker Compose directly, e.g.:
```bash
docker compose -f srcs/docker-compose.yml up --build -d
```

The `-f srcs/docker-compose.yml` flag is needed because the
`docker-compose.yml` file lives inside `srcs/`, not at the project's
root.

## Managing containers and volumes

Useful commands for diagnosing issues:

- **Check container status**:
```bash
  docker compose -f srcs/docker-compose.yml ps
```

- **View logs of a specific service** (e.g. to see WordPress's
  installation steps or errors):
```bash
  docker logs wordpress
  docker logs mariadb
```

- **Open a shell inside a running container** (e.g. to inspect files
  or run commands manually, like `wp` or `mysql`):
```bash
  docker exec -it wordpress bash
  docker exec -it mariadb bash
```

- **Restart a single container** (without rebuilding or affecting
  the others):
```bash
  docker restart wordpress
```

- **Full data reset** (deletes all persistent data -- database
  content, WordPress files and users -- useful when a container gets
  stuck in a broken state):
```bash
  make fclean
```

## Data location and persistence

This project uses two Docker named volumes, both configured to store
their data on the host filesystem under `/home/dperez-p/data/`:

- **`db_data`** -> `/home/dperez-p/data/mariadb/`: the MariaDB
  database files.
- **`wordpress_data`** -> `/home/dperez-p/data/wordpress/`: the
  WordPress installation files (themes, plugins, uploads, core files).

Both are declared in `srcs/docker-compose.yml` with `driver_opts`
pointing to these host paths -- this means the data survives container
restarts, rebuilds, and even `make clean` (which only removes
images, not volumes). Only `make fclean` deletes this data, by
directly removing the contents of these host folders.

To inspect the data without entering a container, you can browse
these folders directly on the host, e.g.:
```bash
ls -la /home/dperez-p/data/wordpress/
```

## Bonus services

In addition to the mandatory stack, this project includes two bonus
services, both under `srcs/requirements/bonus/`:

### Adminer

A single-file PHP database management tool, served via NGINX under
`/adminer/` (same domain, same TLS certificate). Its Dockerfile
installs `php-fpm` and `php-mysql`, and downloads Adminer directly
from its GitHub releases (a fixed version, not `latest`). It has no
volume (no state of its own) and no secrets (credentials are typed
manually into its login form, not injected automatically).

### Redis (object cache)

A Redis server used as WordPress's object cache, to reduce repeated
database queries. Unlike MariaDB, it has no persistent volume: cached
data is disposable and always recomputable from MariaDB if lost.

WordPress's entrypoint script (`wordpress.sh`) sets the
`WP_REDIS_HOST`/`WP_REDIS_PORT` constants, installs and activates the
`redis-cache` plugin, and enables its cache drop-in -- each step
verified independently (the plugin can be "active" without the
drop-in actually being enabled).

To check Redis is actually working:
```bash
docker exec -it wordpress wp redis status --path=/var/www/html --allow-root
```
Look for `Status: Connected` in the output.
