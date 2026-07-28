FROM mongo:4.4.14

LABEL org.opencontainers.image.title="MongoDB" \
      org.opencontainers.image.description="MongoDB service image pinned to version 4.4.14" \
      org.opencontainers.image.version="4.4.14"

EXPOSE 27017

VOLUME ["/data/db", "/data/configdb"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD mongo --quiet --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --eval "db.adminCommand('ping').ok" localhost:27017/admin || exit 1

CMD ["mongod", "--bind_ip_all"]
