*This project has been created as part of the 42 curriculum by dperez-p.*

## Description

Inception is a system administration project that sets up a small
web infrastructure entirely with Docker, running inside a virtual
machine. The goal is to build a working WordPress website served
over HTTPS, backed by a MariaDB database, without relying on any
pre-built Docker images other than the base Debian image.

The infrastructure is composed of five custom-built services, each
running in its own container:
- **NGINX**: the only entrypoint to the infrastructure, serving the
  site over HTTPS (TLSv1.2/TLSv1.3 only) on port 443.
- **WordPress + php-fpm**: processes the PHP code of the WordPress CMS.
- **MariaDB**: stores the WordPress database.
- **Adminer** *(bonus)*: a web-based database management tool.
- **Redis** *(bonus)*: an object cache for WordPress, reducing
  repeated database queries.

## Instructions

### Prerequisites
- A virtual machine running Debian 12 (or similar), with Docker and
  Docker Compose installed.
- A username (referred to as `login` below) matching the one used
  throughout the project's configuration.

### Setup
1. Clone this repository into your virtual machine.
2. Make sure the `secrets/` folder contains the required files
   (`db_root_password.txt`, `db_password.txt`, `wp_user_password.txt`,
   `credentials.txt`) with your own values -- these are not included
   in the repository for security reasons **We will see an example**.
3. Make sure `srcs/.env` is filled in with your own domain, database
   names, and usernames.
4. Add your domain to your local DNS resolution (e.g. your host's
   `hosts` file) pointing to the virtual machine's IP address.

### Secrets format

Create a `secrets/` folder at the root of the repository (it is
git-ignored) with the following files:

**`secrets/db_root_password.txt`**
```
your_root_password_here
```

**`secrets/db_password.txt`**
```
your_wp_user_password_here
```

**`secrets/wp_user_password.txt`**
```
your_second_user_password_here
```

**`secrets/credentials.txt`**
```
WP_ADMIN_USER=your_admin_username
WP_ADMIN_PASSWORD=your_admin_password
```

> Note: the admin username must not contain "admin" or "administrator"
> (e.g. `admin`, `administrator`, `admin-123`), as required by the
> subject.


### Running the project
From the root of the repository:
```bash
make        # builds the images and starts all containers
make down   # stops the containers
make clean  # stops the containers and removes the built images
make fclean # clean + removes all persistent data (full reset)
make re     # fclean + make (full rebuild from scratch)
```

Once running, the site is available at `https://dperez-p.42.fr/`.

## Resources

### Documentation
- [Docker Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
- [MariaDB documentation](https://mariadb.com/kb/en/)
- [WP-CLI documentation](https://wp-cli.org/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [Inception 42: A Comprehensive Guide to Dockerizing Your First Infrastructure (Part III)](https://devabdilah.medium.com/inception-42-a-comprehensive-guide-to-dockerizing-your-first-infrastructure-part-iii-a10e93e9d922) -- followed as a conceptual guide for the project's structure


### AI usage

AI was used throughout this project as a learning tool,
following a guided, question-and-answer approach rather than having
it generate finished code. Specifically, it was used for:

- **Learning core concepts**: understanding Docker fundamentals
  (images vs containers, layers, build context), PID 1 and why
  daemonizing processes inside a container is discouraged, the
  difference between named volumes and bind mounts, and the roles
  of Docker secrets vs environment variables.
- **Bash/syntax guidance**: since the guide followed
  ([devabdilah's Inception walkthrough](#)) explained the
  architecture conceptually but included little actual code, AI was
  used to learn bash syntax and conventions not previously known --
  e.g. `if`/`until` constructs, `cut`/`grep` for parsing files,
  Docker Compose flags like `--build`, `-d`, `--rmi`.
- **Debugging real errors**: every Dockerfile, script, and
  configuration file was written manually and then tested by
  actually running `docker compose up`. AI was used to interpret
  error messages (e.g. MariaDB socket errors, php-fpm listening on
  a unix socket instead of TCP, WP-CLI silently failing on an empty
  variable) and reason through the fix, rather than being given the
  fix directly -- each bug was diagnosed by inspecting logs and
  container state (`docker exec`, `docker logs`) before applying
  any change.
- **Code review**: reviewing hand-written Dockerfiles, shell
  scripts, and the `docker-compose.yml` for syntax errors, spelling
  mistakes in comments, and suggesting more robust patterns. For
  example, the WordPress entrypoint script was first written with a
  single `if` block wrapping the entire installation (download,
  config, admin user, second user) -- after a real bug was found
  where `wp core install` silently reported success despite an
  empty required variable, because WP-CLI's exit code alone wasn't a 
  reliable success signal.
  The script was then refactored into independent, granular checks
  for each step (config file existence, admin user existence, second
  user existence), each verified explicitly rather than assumed from
  a single outer condition.

All AI-suggested concepts were tested and verified in the actual
running infrastructure before being considered correct, and every
line of configuration was written by hand rather than copy-pasted.

## Project description

### Virtual Machines vs Docker

A virtual machine emulates an entire computer, including its own
kernel, running fully isolated from the host system. Docker, on the
other hand, packages an application with everything it needs to run
(a Dockerfile is essentially a "recipe" of steps to build that
environment), but containers share the host's kernel instead of
having their own -- making them much lighter and faster to start than
a full VM.

This project runs Docker *inside* a virtual machine: the VM provides
a fully isolated environment to safely experiment with system
configuration (networking, a local domain, root access) without
touching the host machine, while Docker is used inside it to build
and run the actual infrastructure as required by the subject.

### Secrets vs Environment Variables

Regular environment variables (stored in `.env`) are convenient for
non-sensitive configuration (domain names, database names, usernames),
but they are easily exposed: they show up in plain text if someone
runs `docker inspect` on a container, and can leak into logs or
process listings.

Docker secrets are mounted as files inside the container (under
`/run/secrets/`) with restricted permissions, and are not exposed
through `docker inspect` or the container's environment variables.
For this reason, all passwords in this project (database root and
user passwords, WordPress admin credentials) are stored as Docker
secrets, while non-sensitive configuration lives in `.env`. Each
container is also only given the secrets it actually needs (e.g.
MariaDB never receives WordPress's admin credentials), following the
principle of least privilege.

### Docker Network vs Host Network

Using `network: host` would make a container share the host's
network stack directly, with no isolation and no automatic name
resolution between services. This project instead defines its own
custom bridge network (`inception`), which does two things: it
isolates the containers from the host's network (only NGINX
explicitly publishes a port to the outside, via `443:443`), and it
lets containers reach each other by service name (e.g. `wordpress`
connecting to `mariadb`) through Docker's internal DNS, instead of
relying on hardcoded IP addresses.

### Docker Volumes vs Bind Mounts

A bind mount maps a host path directly into a container
(`/host/path:/container/path`), with no management layer -- Docker
doesn't track it as an entity of its own. A named volume, in
contrast, is declared first as a named entity at the top level of
the `docker-compose.yml`, then referenced by that name inside each
service, and is fully managed by Docker (visible with
`docker volume ls`, with its own lifecycle). This project uses named
volumes for both the WordPress files and the MariaDB database, with
`driver_opts` configured so Docker stores their data under
`/home/dperez-p/data/` on the host, as required by the subject --
combining Docker's management with a specific, predictable storage
location.
