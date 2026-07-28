# Redis service

This service runs Redis using the official `redis:7.4.2-alpine` image. It follows the repository service-per-folder convention: `docker-compose.yml`, `.env.example`, and numbered shell scripts.

## Quick path

```bash
bash 00_init.sh
bash 02_launch_redis.sh
```

`00_init.sh` creates `.env` from `.env.example` only when `.env` is missing, so existing local configuration is not overwritten.

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Runs Redis with a pinned official image, persistence, healthcheck, named volume, and shared local integration network. |
| `.env.example` | Provides safe example values for local configuration. |
| `00_init.sh` | Creates `.env` from `.env.example` when needed. |
| `02_launch_redis.sh` | Starts the Redis service with Docker Compose. |

## Environment variables

| Variable | Default example | Description |
|----------|-----------------|-------------|
| `REDIS_VERSION` | `7.4.2-alpine` | Redis image tag. |
| `REDIS_PORT` | `6379` | Host port mapped to Redis. |
| `REDIS_CONTAINER_NAME` | `redis_instance` | Redis container name. |
| `REDIS_DATA_VOLUME` | `redis_data` | Named volume for Redis data. |

## Access patterns

| Client location | Host | Port | Notes |
|-----------------|------|------|-------|
| Host machine | `localhost` | `${REDIS_PORT}` | Use this for applications running directly on the host. |
| Dockerized Andes microservices | `redis` | `6379` | The Compose service is attached to the external `stress-test-network` for local DNS access. |

For `paymentmanagementb`, use these values when the service runs in Docker and is attached to the same network:

```env
THIS_REDIS_HOST=redis
THIS_REDIS_PORT=6379
```

No password is configured by default. Add authentication only if the consuming application is updated to send Redis credentials.

## Persistence

Redis data is persisted in a Docker named volume:

| Service | Container path | Compose volume | Default Docker volume name |
|---------|----------------|----------------|----------------------------|
| Redis | `/data` | `redis_data` | `redis_data` |

Redis is started with snapshotting and AOF enabled:

```bash
redis-server --save 60 1 --appendonly yes --loglevel notice
```

## Healthcheck

The Redis healthcheck verifies that the server responds to `PING`:

```bash
redis-cli -h 127.0.0.1 -p 6379 ping
```

## Connect locally

After the container is healthy, connect from your host using the configured host port:

```bash
docker exec -it redis_instance redis-cli ping
```

If you changed `.env`, use those local values instead of the examples above.
