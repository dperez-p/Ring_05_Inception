# User Documentation

## What services does this provide?

This project runs a WordPress website, accessible through your web
browser. Behind the scenes, three components work together:

- A **web server (NGINX)**: handles all incoming connections securely
  (HTTPS).
- **WordPress**: the website itself, where content is created and
  managed.
- A **database (MariaDB)**: stores everything WordPress needs (posts,
  users, settings).

As an end user, you only need to interact with the website itself and
its administration panel -- the rest runs automatically in the
background.

## Starting and stopping the project

From the root of the project folder, on the virtual machine:

- **To start the website**: run `make`
- **To stop it**: run `make down`

Starting the project for the first time may take a minute or two, as
it needs to set everything up. After that, starting and stopping is
quick.

## Accessing the website and the admin panel

- **Website**: open your browser and go to `https://dperez-p.42.fr`
- **Admin panel**: go to `https://dperez-p.42.fr/wp-admin` and log in
  with the administrator credentials (see "Locating credentials"
  below).

> Note: since this project uses a self-signed TLS certificate (not
> issued by a recognized authority), your browser will show a
> security warning the first time you visit. This is expected -- click
> "Advanced" and proceed to the site.

## Locating credentials

All passwords and login credentials are stored in the `secrets/`
folder, at the root of the project (this folder is never shared or
uploaded anywhere, for security reasons).

- **Admin panel username and password**:
  `secrets/credentials.txt`
- **Database passwords**: not needed for regular use of the website,
  only relevant for developers (see `DEV_DOC.md`).

To view the admin credentials, run:
```bash
cat secrets/credentials.txt
```

## Checking that services are running correctly

From the project's root folder, run:
```bash
docker compose -f srcs/docker-compose.yml ps
```

You should see three containers (`mariadb`, `wordpress`, `nginx`),
all with a status of `Up`. If any of them shows a different status
(e.g. `Restarting` or `Exited`), something went wrong -- see
`DEV_DOC.md` for troubleshooting steps.

You can also simply visit `https://dperez-p.42.fr` in your browser:
if the website loads, all three services are working together
correctly.

## Bonus: Adminer (database management)

A visual database management tool is available at
`https://dperez-p.42.fr/adminer/`. Log in with the database
credentials found in `secrets/db_password.txt` (username `wp_user`,
database `wordpress`).
