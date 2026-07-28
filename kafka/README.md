# Kafka 3.0.8 service

This service runs Kafka pinned to `3.0.8` with ZooKeeper for a stable local Kafka 3.0.x setup. It follows the repository service-per-folder convention: `docker-compose.yml`, `.env.example`, and numbered shell scripts.

## Quick path

```bash
bash 00_init.sh
bash 02_launch_kafka.sh
```

`00_init.sh` creates `.env` from `.env.example` only when `.env` is missing, so existing local configuration is not overwritten.

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Runs ZooKeeper and Kafka with pinned images, listeners, healthchecks, and named volumes. |
| `.env.example` | Provides safe example values for local configuration. |
| `00_init.sh` | Creates `.env` from `.env.example` when needed. |
| `02_launch_kafka.sh` | Starts the Kafka service with Docker Compose. |

## Environment variables

| Variable | Default example | Description |
|----------|-----------------|-------------|
| `KAFKA_VERSION` | `3.0.8` | Kafka image tag. |
| `KAFKA_PORT` | `9092` | Host port mapped to the Kafka external listener. |
| `KAFKA_CONTAINER_NAME` | `kafka_instance` | Kafka container name. |
| `KAFKA_BROKER_ID` | `1` | Kafka broker ID. |
| `KAFKA_ADVERTISED_HOST` | `localhost` | Hostname advertised to clients outside Docker Compose. |
| `KAFKA_AUTO_CREATE_TOPICS_ENABLE` | `true` | Enables topic creation when producers/consumers reference missing topics. |
| `KAFKA_DATA_VOLUME` | `kafka_data` | Named volume for Kafka data. |
| `ZOOKEEPER_VERSION` | `3.8.4` | ZooKeeper image tag. |
| `ZOOKEEPER_PORT` | `2181` | Host port mapped to ZooKeeper. |
| `ZOOKEEPER_CONTAINER_NAME` | `kafka_zookeeper_instance` | ZooKeeper container name. |
| `ZOOKEEPER_DATA_VOLUME` | `kafka_zookeeper_data` | Named volume for ZooKeeper data. |

## Listeners

| Listener | Address | Use case |
|----------|---------|----------|
| `PLAINTEXT` | `kafka:9092` | Container-to-container access inside the Compose network. |
| `EXTERNAL` | `${KAFKA_ADVERTISED_HOST}:${KAFKA_PORT}` | Local host access, for example `localhost:9092`. |

## Persistence

Kafka and ZooKeeper data are persisted in Docker named volumes:

| Service | Container path | Compose volume | Default Docker volume name |
|---------|----------------|----------------|----------------------------|
| Kafka | `/bitnami/kafka` | `kafka_data` | `kafka_data` |
| ZooKeeper | `/bitnami/zookeeper` | `zookeeper_data` | `kafka_zookeeper_data` |

## Healthcheck

The Kafka healthcheck verifies that the broker can list topics:

```bash
/opt/bitnami/kafka/bin/kafka-topics.sh --bootstrap-server 127.0.0.1:9092 --list
```

## Connect locally

After the container is healthy, list topics from your host using the configured external listener:

```bash
docker exec -it kafka_instance /opt/bitnami/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
```

If you changed `.env`, use those local values instead of the examples above.
