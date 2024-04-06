
## Pre install

set docker storage prior to install in
/etc/docker/daemon.json

```
docker compose up -d
docker compose stop
```

## upgrade with

```
docker compose pull && docker compose up -d
```


## Backup

```
docker exec -t immich_postgres pg_dumpall -c -U postgres | gzip > "/path/to/backup/dump.sql.gz"
```


## Restore

```
docker compose down -v  # CAUTION! Deletes all Immich data to start from scratch.
docker compose pull     # Update to latest version of Immich (if desired)
docker compose create   # Create Docker containers for Immich apps without running them.
docker start immich_postgres    # Start Postgres server
sleep 10    # Wait for Postgres server to start up
gunzip < "/path/to/backup/dump.sql.gz" | docker exec -i immich_postgres psql -U postgres -d immich    # Restore Backup
docker compose up -d    # Start remainder of Immich apps
```
