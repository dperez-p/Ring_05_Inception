# base image
FROM debian:bookworm

#install redis server
RUN apt-get update && apt-get install -y \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

# redis standard port
EXPOSE 6379

# start redis in the foreground, bound to all interfaces so
# wordpress (another container) can reach it
ENTRYPOINT ["redis-server", "--bind", "0.0.0.0", "--protected-mode", "no"]
