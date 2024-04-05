set docker storage prior to install in
/etc/docker/daemon.json

docker compose up -d
docker compose stop

## upgrade with
docker compose pull && docker compose up -d
