#!/bin/bash
# Reinicia datos de métricas y logs del stack de monitoreo.
#
# Borra los volúmenes de Prometheus, VictoriaMetrics y Loki, pero conserva:
# - Grafana dashboards/configuración
# - Tempo traces
#
# Uso:
#   bash 04_reset_metrics.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo ">>> Deteniendo servicios que usan volúmenes de métricas/logs..."
docker compose stop prometheus victoriametrics loki

echo ">>> Eliminando contenedores detenidos para liberar volúmenes..."
docker compose rm -f prometheus victoriametrics loki

echo ">>> Eliminando volúmenes de métricas/logs..."
docker volume rm monitoring_prometheus-data monitoring_victoriametrics-data monitoring_loki-data

echo ">>> Levantando servicios de métricas/logs..."
docker compose up -d prometheus victoriametrics loki

echo ">>> Métricas y logs reiniciados. Estado actual:"
docker compose ps prometheus victoriametrics loki
