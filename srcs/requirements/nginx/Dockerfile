# base image
FROM debian:bookworm

# install nginx and openssl (needed to generate the self-signed certificate)
RUN apt-get update && apt-get install -y \
	nginx \
	openssl \
	&& rm -rf /var/lib/apt/lists/*

# create the folder where the certificate and private key will live
RUN mkdir -p /etc/nginx/ssl

# generate a self-signed TLS certificate valid for our domain
# -x509: output a certificate directly (not a signing request)
# -nodes: don't encrypt the private key (needed for unattended startup)
# -newkey rsa:2048: generate a new 2048-bit RSA key
# CN must match the domain we will use to access the site
RUN openssl req -x509 -nodes -days 365 \
	-newkey rsa:2048 \
	-keyout /etc/nginx/ssl/inception.key \
	-out /etc/nginx/ssl/inception.crt \
	-subj "/C=ES/ST=Andalusia/L=Malaga/O=42/CN=dperez-p.42.fr"


# copy our custom server configuration into nginx's config folder
COPY conf/nginx.conf /etc/nginx/sites-available/inception.conf

# enable our site by symlinking it into sites-enabled,
# and remove the default nginx welcome page config to avoid conflicts
RUN ln -s /etc/nginx/sites-available/inception.conf /etc/nginx/sites-enabled/ \
    && rm -f /etc/nginx/sites-enabled/default

# 443 is the only port allowed by the subject
EXPOSE 443

# start nginx in the foreground (-g "daemon off;") as PID 1
# no custom script needed since there's no initialization logic
ENTRYPOINT ["nginx", "-g", "daemon off;"]
