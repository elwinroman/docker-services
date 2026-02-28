### Descargar imagen
```
docker pull valkey/valkey:8.0.2-alpine3.21
```

### Iniciar instancia
```
docker run --name valkey_instance valkey/valkey:8.0.2-alpine3.21
```

### Iniciar instancia con persistencia de almacenamiento
```
docker run --name valkey_instance -d valkey/valkey:8.0.2-alpine3.21 valkey-server --save 60 1 --loglevel warning
```

### Docker-compose
Se mejora la configuración con docker-compose.yml, agregando volumenes, variables de entorno, para lo cual ejecuta en la ruta donde se ubica docker-compose.yml:
```
docker-compose up --build -d
```

### Scripts de inicialización
Se proveen scripts para facilitar el despliegue. Ejecutar en orden:

| Script                      | Descripción                                                             |
|-----------------------------|-------------------------------------------------------------------------|
| `00_init.sh`                | Copia `.env.example` a `.env` para configurar las variables de entorno. |
| `01_create_environment.sh`  | Crea el directorio `valkey-data` y le asigna los permisos necesarios.   |
| `02_launch_valkey.sh`       | Levanta el contenedor de Valkey con `docker compose`.                   |

```bash
bash 00_init.sh
bash 01_create_environment.sh
bash 02_launch_valkey.sh
```

#### Variables de entorno (`.env.sample`)
| Variable          | Valor por defecto | Descripción                        |
|-------------------|-------------------|------------------------------------|
| `VALKEY_PORT`     | `6379`            | Puerto expuesto por el contenedor. |
| `VALKEY_USER`     | `default`         | Usuario de acceso (solo lectura).  |
| `VALKEY_PASSWORD` | `P@ssword123`     | Contraseña de acceso al servidor.  |

### ¿Como cambiar el nombre de usuario?
Valkey (al igual que Redis) no admite múltiples usuarios en su configuración estándar. Solo permite establecer una contraseña global con --requirepass, pero no puedes definir un nombre de usuario personalizado en la configuración predeterminada.

Por defecto el usuario se creará como `default`

### Comandos
| Opción                              | Descripción                                                                 |
|-------------------------------------|-----------------------------------------------------------------------------|
| --save 60 1                         | Guarda el estado cada 60 segundos si hubo al menos 1 cambio.                |
| --appendonly yes                    | Habilita AOF (Append-Only File) para mayor persistencia.                    |
| --loglevel notice                   | Aumenta el nivel de logs (muestra información importante).                  |
| --require-pass ${VALKEY_PASSWORD}   | Establece una contraseña para acceder al servidor mediante una variable de entorno. |

Para la persistencia de data en docker, se hace uso de `volumes`, si no se coloca una ruta relativa, docker gestiona automáticamente el volumen
Para consultar la data ejecuta:
```
docker exec -it <nombre_contenedor> sh
```
y según la configuración del volumen ubicate en /data, 

### Como consultar directamente la data cache almacenada?
Con el siguiente comando puedes consultar
```
docker exec -it <nombre_contenedor> redis-cli -a "<password>"
```
Ejemplo
```
docker exec -it valkey_instance redis-cli -a "P@ssword1234"
```

O también se puede usar el software [Redis Insight](https://redis.io/downloads/#:~:text=Redis-,Insight,-Download%20a%20powerful) que permite visualizar y administrar data de Valkey (compatible con Redis).