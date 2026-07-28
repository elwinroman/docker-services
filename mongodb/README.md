# MongoDB 4.4.14 service

This service runs MongoDB pinned to `4.4.14` using the repository service-per-folder convention: `docker-compose.yml`, `.env.example`, and numbered shell scripts.

## Quick path

```bash
bash 00_init.sh
bash 02_launch_mongodb.sh
```

`00_init.sh` creates `.env` from `.env.example` only when `.env` is missing, so existing local credentials are not overwritten.

## Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Builds the local MongoDB image pinned to `mongo:4.4.14`. |
| `docker-compose.yml` | Runs the MongoDB service with ports, credentials, healthcheck, and named volumes. |
| `.env.example` | Provides safe example values for local configuration. |
| `00_init.sh` | Creates `.env` from `.env.example` when needed. |
| `02_launch_mongodb.sh` | Starts the MongoDB service with Docker Compose. |

## Environment variables

| Variable | Default example | Description |
|----------|-----------------|-------------|
| `MONGODB_PORT` | `27017` | Host port mapped to the MongoDB container port. |
| `MONGODB_CONTAINER_NAME` | `mongodb_instance` | Docker container name. |
| `MONGODB_ROOT_USERNAME` | `root` | MongoDB root username. |
| `MONGODB_ROOT_PASSWORD` | `changeMeMongo123` | MongoDB root password example. Change it locally. |
| `MONGODB_DATABASE` | `appdb` | Database name reserved for initialization scripts; MongoDB creates databases lazily when data is written. |
| `MONGODB_DB_VOLUME` | `mongodb_data` | Named volume for `/data/db`. |
| `MONGODB_CONFIG_VOLUME` | `mongodb_config` | Named volume for `/data/configdb`. |

## Persistence

MongoDB data is persisted in Docker named volumes:

| Container path | Compose volume | Default Docker volume name |
|----------------|----------------|----------------------------|
| `/data/db` | `mongodb_data` | `mongodb_data` |
| `/data/configdb` | `mongodb_config` | `mongodb_config` |

## Healthcheck

The healthcheck uses the MongoDB 4.4-compatible `mongo` shell:

```bash
mongo --quiet --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --eval "db.adminCommand('ping').ok" localhost:27017/admin
```

## Connect locally

After the container is healthy, connect with:

```bash
docker exec -it mongodb_instance mongo -u root -p changeMeMongo123 --authenticationDatabase admin
```

If you changed `.env`, use those local values instead of the examples above.
