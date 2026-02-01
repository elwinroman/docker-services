# Servidor de Agregación de Logs con Grafana y Loki

Entorno Docker Compose para almacenar y visualizar logs usando Grafana y Loki.

## Instalación

```shell
cd grafana-loki
cp .env.example .env
# Edita .env con tus credenciales (GF_SECURITY_ADMIN_PASSWORD, SMTP, etc)
./01_create_environment.sh
```

## Levantar servicios

```shell
docker compose up -d
docker compose -f compose-loki.yml up -d
```

## URLs de acceso

- **Grafana**: http://localhost:3001 (admin/admin)
- **Loki API**: http://localhost:3100

## Configurar Loki en Grafana

1. Grafana → **Connections** → **Data sources** → **Add data source** → **Loki**
2. URL: `http://loki:3100`
3. **Save & Test**

## Enviar logs a Loki

```bash
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d '{
    "streams": [{
      "stream": {"job": "test", "level": "info"},
      "values": [["'$(date +%s)000000000'", "mensaje"]]
    }]
  }'
```

## Comprobaciones

```shell
docker compose logs -f grafana
docker compose -f compose-loki.yml logs -f loki
```

## Seguridad con Nginx

### Crear credenciales

```shell
sudo htpasswd -c /etc/nginx/.htpasswd admin
```

### Certificado SSL

**Let's Encrypt:**
```shell
sudo certbot --nginx -d grafana.romeltek.com -d loki.romeltek.com
```

**Autofirmado:**
```shell
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/nginx-selfsigned.key \
  -out /etc/nginx/ssl/nginx-selfsigned.crt \
  -subj "/C=ES/ST=Madrid/L=Madrid/O=MiOrg/CN=localhost"
```

### Configuración Nginx

**Grafana** (`/etc/nginx/sites-available/grafana.romeltek.com`):

```nginx
server {
    listen 80;
    server_name grafana.romeltek.com;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade; # websocket
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Loki** (`/etc/nginx/sites-available/loki.romeltek.com`):

```nginx
server {
    listen 80;
    server_name loki.romeltek.com;

    auth_basic "Grafana";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        proxy_pass http://localhost:3100;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        client_max_body_size 50M; # para logs grandes
    }
}
```

### Activar configuraciones

```shell
sudo ln -s /etc/nginx/sites-available/grafana.romeltek.com /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/loki.romeltek.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Firewall

```shell
sudo ufw allow 'Nginx Full'
sudo ufw deny 3001
sudo ufw deny 3100
```

### Enviar logs con autenticación

```bash
curl -X POST https://usuario:pass@loki.romeltek.com/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d '{
    "streams": [{
      "stream": {"job": "test"},
      "values": [["'$(date +%s)000000000'", "mensaje"]]
    }]
  }'
```

**Promtail:**
```yaml
clients:
  - url: https://loki.romeltek.com/loki/api/v1/push
    basic_auth:
      username: admin
      password: tu_contraseña
```

## Limpieza

```shell
docker compose down
docker compose -f compose-loki.yml down
sudo rm -rf grafana-data volumes-loki
```
