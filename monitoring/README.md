# Stack general de monitoreo

Stack Docker Compose para centralizar observabilidad de varios proyectos.

Este stack agrupa:

- **Grafana**: UI para consultar dashboards, logs, métricas y traces.
- **Loki**: almacenamiento y consulta de logs.
- **Prometheus**: almacenamiento y consulta de métricas operativas.
- **VictoriaMetrics**: persistencia histórica de métricas.
- **OpenTelemetry Collector**: entrada OTLP para logs, métricas y traces generados por aplicaciones.
- **Tempo**: almacenamiento y consulta de traces.

Valkey se mantiene separado porque es cache/infraestructura de aplicación, no monitoreo.

## Arquitectura

```txt
Aplicaciones
  └─ OTLP  -> OpenTelemetry Collector
                ├─ logs     -> Loki
                ├─ métricas -> endpoint :9464 -> Prometheus -> VictoriaMetrics
                └─ traces   -> Tempo

Grafana
  ├─ consulta métricas recientes en Prometheus
  ├─ consulta métricas históricas en VictoriaMetrics
  ├─ consulta logs en Loki
  └─ consulta traces en Tempo
```

## Flujo de Datos

### Logs

```txt
App -> OpenTelemetry Collector -> Loki -> Grafana
```

Loki guarda logs en el volumen Docker `loki-data`.

Uso esperado:

- debugging
- auditoría operativa
- búsqueda por labels/mensaje
- correlación con `correlationId`, `session.id`, `userId`, etc.

Los logs deben llegar al Collector por OTLP. Las aplicaciones no deberían depender directamente de Loki.

### Métricas

```txt
App -> OpenTelemetry Collector -> Prometheus -> Grafana
                                      └─ remote_write -> VictoriaMetrics -> Grafana
```

Prometheus guarda métricas en el volumen Docker `prometheus-data`.
VictoriaMetrics guarda el histórico en el volumen Docker `victoriametrics-data`.

Uso esperado:

- TPS/RPS
- latencia p50/p95/p99
- error rate
- conteos por endpoint/status
- alertas operativas
- consultas históricas mensuales/anuales

### Traces

```txt
App -> OpenTelemetry Collector -> Tempo -> Grafana
```

Tempo guarda traces en el volumen Docker `tempo-data`.

Uso esperado:

- entender el recorrido de una request
- saber qué paso fue lento
- separar latencia entre API, cache, SQL, llamadas externas
- correlación futura con logs/métricas

## Instalación

```bash
cd D:/Repository/docker-services/monitoring
bash 00_init.sh
bash 01_create_environment.sh
```

`00_init.sh` crea `.env` desde `.env.example` solo si no existe.

`01_create_environment.sh` crea la red Docker externa:

```txt
monitoring
```

Los proyectos que quieran enviar datos a este stack deben conectarse a esa red.

## Levantar

```bash
bash 02_launch_monitoring.sh
```

Equivalente:

```bash
docker compose up -d
```

## URLs Locales

| Servicio | URL |
| --- | --- |
| Grafana | `http://localhost:4000` |
| Prometheus | `http://localhost:9090` |
| VictoriaMetrics | `http://localhost:8428` |
| VictoriaMetrics UI | `http://localhost:8428/vmui` |
| OTLP gRPC | `localhost:4317` |
| OTLP HTTP | `http://localhost:4318` |

Servicios solo internos en Docker:

| Servicio | URL interna |
| --- | --- |
| Loki | `http://loki:3100` |
| Tempo | `http://tempo:3200` |
| Collector metrics | `http://otel-collector:9464` |

## Datasources de Grafana

Grafana no guarda datos de observabilidad. Consulta sistemas externos llamados datasources.

Este stack provisiona automáticamente:

| Datasource | Tipo | URL |
| --- | --- | --- |
| Prometheus | métricas | `http://prometheus:9090` |
| VictoriaMetrics | métricas históricas | `http://victoriametrics:8428` |
| Loki | logs | `http://loki:3100` |
| Tempo | traces | `http://tempo:3200` |

Archivo:

```txt
config/grafana/provisioning/datasources/datasources.yml
```

## Servicios y Configuración

### Versiones de Imágenes

Las imágenes se fijan con tags explícitos en `compose.yml` para evitar cambios inesperados al ejecutar `docker compose pull`.

Para actualizar una versión:

1. Revisar changelog del servicio.
2. Hacer backup de los volúmenes relevantes.
3. Cambiar el tag en `compose.yml`.
4. Ejecutar `docker compose pull`.
5. Ejecutar `docker compose up -d`.
6. Validar Grafana, datasources y targets de Prometheus.

### Grafana

Definido en:

```txt
compose.yml
```

Variables principales:

| Variable | Uso |
| --- | --- |
| `GRAFANA_PORT` | Puerto publicado en el host. Default: `4000`. |
| `GF_SECURITY_ADMIN_USER` | Usuario administrador inicial. |
| `GF_SECURITY_ADMIN_PASSWORD` | Password administrador inicial. Cambiar antes de exponer. |
| `GF_USERS_ALLOW_SIGN_UP` | Permite registro de usuarios. Default: `false`. |
| `GF_SERVER_ROOT_URL` | URL pública si Grafana está detrás de Nginx/subpath. |
| `GF_SERVER_SERVE_FROM_SUB_PATH` | Usar `true` si Grafana se sirve desde `/grafana/`. |

La imagen de Grafana se fija directamente en `compose.yml`:

```yaml
image: grafana/grafana-oss:12.0.2
```

Persistencia:

```txt
grafana-data:/var/lib/grafana
```

### Loki

Definido en:

```txt
compose.yml
config/loki-config.yml
```

Parámetros principales:

| Parámetro | Valor actual | Significado |
| --- | --- | --- |
| `auth_enabled` | `false` | Sin auth interna. Debe quedar en red privada o detrás de Nginx/auth. |
| `LOKI_RETENTION_PERIOD` | `720h` | Retención de logs: 30 días. |
| `LOKI_MAX_QUERY_LOOKBACK` | `720h` | Máximo rango histórico consultable. |
| `retention_enabled` | `true` | Activa eliminación por retención desde el compactor. |
| `max_size_mb` | `100` | Cache embebida para acelerar consultas repetidas. |

Persistencia:

```txt
loki-data:/loki
```

Loki no publica puerto al host. Grafana lo consume dentro de Docker:

```txt
http://loki:3100
```

Para retención de 15 días:

```env
LOKI_RETENTION_PERIOD=360h
LOKI_MAX_QUERY_LOOKBACK=360h
```

Para retención de 90 días:

```env
LOKI_RETENTION_PERIOD=2160h
LOKI_MAX_QUERY_LOOKBACK=2160h
```

La imagen de Loki se fija directamente en `compose.yml`:

```yaml
image: grafana/loki:3.6.7
```

### Prometheus

Definido en:

```txt
compose.yml
config/prometheus.yml
```

Parámetros principales:

| Parámetro | Valor actual | Significado |
| --- | --- | --- |
| `scrape_interval` | `15s` | Cada cuánto recolecta métricas. |
| `evaluation_interval` | `15s` | Cada cuánto evalúa reglas/alertas. |
| `PROMETHEUS_RETENTION` | `15d` | Retención local de métricas. |

Persistencia:

```txt
prometheus-data:/prometheus
```

Targets configurados:

- `prometheus:9090`
- `otel-collector:9464`
- `loki:3100`
- `tempo:3200`
- `victoriametrics:8428`

Prometheus también envía métricas a VictoriaMetrics por `remote_write`:

```txt
http://victoriametrics:8428/api/v1/write
```

Para ver el estado:

```txt
http://localhost:9090/targets
```

La imagen de Prometheus se fija directamente en `compose.yml`:

```yaml
image: prom/prometheus:v3.4.2
```

### VictoriaMetrics

Definido en:

```txt
compose.yml
```

VictoriaMetrics recibe métricas desde Prometheus y funciona como almacenamiento persistente de mayor retención.

Parámetros principales:

| Parámetro | Valor actual | Significado |
| --- | --- | --- |
| `VICTORIAMETRICS_PORT` | `8428` | Puerto publicado en el host. |
| `VICTORIAMETRICS_RETENTION` | `12` | Retención histórica en meses. |
| `storageDataPath` | `/victoria-metrics-data` | Ruta interna donde guarda los datos. |

Persistencia:

```txt
victoriametrics-data:/victoria-metrics-data
```

Grafana consulta VictoriaMetrics usando datasource tipo Prometheus:

```txt
http://victoriametrics:8428
```

Uso recomendado:

- Prometheus: consultas recientes, estado de targets y alertas operativas.
- VictoriaMetrics: consultas históricas de TPS, errores y latencia.

La imagen de VictoriaMetrics se fija directamente en `compose.yml`:

```yaml
image: victoriametrics/victoria-metrics:v1.117.1
```

### OpenTelemetry Collector

Definido en:

```txt
compose.yml
config/otel-collector-config.yml
```

El Collector recibe datos OTLP desde las aplicaciones y los reenvía:

| Pipeline | Entrada | Salida |
| --- | --- | --- |
| `logs` | OTLP gRPC/HTTP | Loki `http://loki:3100/otlp` |
| `metrics` | OTLP gRPC/HTTP | Prometheus exporter `:9464` |
| `traces` | OTLP gRPC/HTTP | Tempo `tempo:4317` |

Puertos:

| Puerto | Protocolo | Uso |
| --- | --- | --- |
| `4317` | OTLP gRPC | Entrada para SDKs/agentes que usan gRPC. |
| `4318` | OTLP HTTP | Entrada recomendada para apps Node por simplicidad. |
| `9464` | Prometheus scrape | Endpoint que Prometheus scrapea. |

Procesadores:

| Procesador | Uso |
| --- | --- |
| `memory_limiter` | Evita que el Collector exceda la memoria asignada. |
| `batch` | Agrupa datos para reducir overhead. |

La API no debe enviar datos directamente a Loki, Prometheus, VictoriaMetrics o Tempo. Debe enviar OTLP al Collector:

```txt
App -> otel-collector:4318
  ├─ logs    -> loki:3100/otlp
  ├─ metrics -> otel-collector:9464 -> prometheus
  └─ traces  -> tempo:4317
```

La imagen del Collector se fija directamente en `compose.yml`:

```yaml
image: otel/opentelemetry-collector-contrib:0.128.0
```

### Tempo

Definido en:

```txt
compose.yml
config/tempo.yml
```

Tempo almacena traces, no logs ni métricas.

Parámetros principales:

| Parámetro | Valor actual | Significado |
| --- | --- | --- |
| `http_listen_port` | `3200` | API que consulta Grafana. |
| `TEMPO_TRACE_RETENTION` | `168h` | Retención de traces: 7 días. |
| `backend` | `local` | Almacenamiento local single-node. |

Persistencia:

```txt
tempo-data:/var/tempo
```

La imagen de Tempo se fija directamente en `compose.yml`:

```yaml
image: grafana/tempo:2.8.1
```

## Conectar un Proyecto Docker

El servicio debe estar en la red externa:

```yaml
networks:
  monitor:
    name: monitoring
    external: true
```

Para logs con Loki:

```env
LOKI_REPORTING_ENABLED=true
LOKI_HOST=http://loki:3100
```

Para OpenTelemetry:

```env
OTEL_ENABLED=true
OTEL_SERVICE_NAME=quality-tools-api
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
OTEL_METRIC_EXPORT_INTERVAL=15000
```

## Consultas Esperadas

### Logs

Desde Grafana Explore con Loki:

```logql
{app="qt-api"}
```

Ejemplo por usuario:

```logql
{app="qt-api"} | json | user_userId = "1"
```

### Métricas

Desde Grafana Explore con Prometheus:

```promql
sum(rate(http_server_request_duration_seconds_count[1m]))
```

La métrica exacta puede variar según la instrumentación OpenTelemetry de la API.

Para histórico mensual/anual, usar el datasource VictoriaMetrics con PromQL/MetricsQL.

### Traces

Desde Grafana Explore con Tempo:

```txt
Buscar por traceId o por servicio cuando la API ya emita traces.
```

## Validación

Validar compose:

```bash
docker compose --env-file .env -f compose.yml config
```

Ver contenedores:

```bash
docker compose ps
```

Ver targets de Prometheus:

```txt
http://localhost:9090/targets
```

Probar Loki desde Grafana:

```bash
docker exec -it grafana wget -qO- http://loki:3100/ready
```

## Comandos Útiles

```bash
docker compose logs -f grafana
docker compose logs -f loki
docker compose logs -f prometheus
docker compose logs -f victoriametrics
docker compose logs -f otel-collector
docker compose logs -f tempo
docker compose down
```

## Seguridad

- Cambiar `GF_SECURITY_ADMIN_PASSWORD` antes de exponer Grafana.
- No publicar Loki, Tempo, Prometheus, VictoriaMetrics ni Collector si no es necesario.
- Si se exponen servicios, hacerlo detrás de Nginx con HTTPS y autenticación.
- Mantener `auth_enabled: false` en Loki solo si está en red privada.

## Límites Actuales

| Servicio | CPU | Memoria |
| --- | --- | --- |
| Grafana | `0.50` | `512m` |
| Loki | `1.00` | `1g` |
| Prometheus | `1.00` | `1g` |
| VictoriaMetrics | `1.00` | `1g` |
| OTel Collector | `0.50` | `256m` |
| Tempo | `0.50` | `512m` |
