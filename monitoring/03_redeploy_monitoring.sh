#!/bin/bash
# Redeploy del stack de monitoreo preservando volúmenes/datos.
#
# Uso:
#   bash 03_redeploy_monitoring.sh                       → redeploy de todo el stack
#   bash 03_redeploy_monitoring.sh otel-collector        → redeploy solo del collector
#   bash 03_redeploy_monitoring.sh grafana loki           → redeploy de servicios puntuales
#   PRUNE_IMAGES=true bash 03_redeploy_monitoring.sh      → además limpia imágenes dangling
#
# Importante:
#   No usa `docker compose down -v`, por lo tanto conserva los volúmenes de
#   Grafana, Loki, Prometheus, Tempo y VictoriaMetrics.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo ">>> Asegurando red externa 'monitoring'..."
docker network inspect monitoring >/dev/null 2>&1 || docker network create monitoring

if [ "$#" -gt 0 ]; then
  echo ">>> Redeploy de servicios: $*"
  docker compose up -d --force-recreate "$@"
else
  echo ">>> Redeploy del stack monitoring..."
  docker compose up -d --force-recreate --remove-orphans
fi

if [ "${PRUNE_IMAGES:-false}" = "true" ]; then
  echo ">>> Limpiando imágenes dangling..."
  docker image prune -f
fi

echo ">>> Estado del stack monitoring:"
docker compose ps
