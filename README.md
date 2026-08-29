# 🐳 update-container.sh — Script de actualización automática para contenedores Docker Compose

[![GitHub release](https://img.shields.io/github/v/release/JLalib/update-container.sh?style=flat-square)](https://github.com/JLalib/update-container.sh/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlalib/update-container?style=flat-square)](https://hub.docker.com/r/jlalib/update-container)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Docker Compose](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker&logoColor=white)](https://docs.docker.com/compose/)

---

## 📋 Descripción general

**update-container.sh** es un script Bash profesional y *production-ready* que automatiza el ciclo completo de actualización de contenedores Docker Compose autohospedados. Diseñado para homelabs y entornos de sysadmin, ejecuta de forma segura y ordenada: **pull de imágenes nuevas → relanzamiento de servicios (up -d) → limpieza de imágenes obsoletas (prune)**, con validación de entrada robusta, *error handling* en cada paso y salida en consola amigable con emojis.

El script asume una estructura estándar bajo `$HOME/docker/<contenedor>/docker-compose.yml`, funciona con cualquier usuario (sin *hardcodear* rutas), soporta modo **interactivo** (pide nombre) y modo **argumento** (recibe nombre), y es **idempotente**: seguro para ejecutar múltiples veces o desde *cron jobs* nocturnos.

> 💡 **Propuesta clave**: Automatización Bash + Docker Compose. Pull → Up → Prune. Validación segura (`set -uo pipefail`). Limpieza automática. Cron-ready. Sin dependencias externas.

---

## ✨ Características principales

- 🔄 **Modo dual**: interactivo (prompt) o por argumento (`./update-container.sh authentik`)
- 🛡️ **Validación segura**: previene *path traversal* (`../`, `/`) y nombres vacíos
- ⚙️ **Error handling robusto**: `set -uo pipefail`; cada paso validado; fallo detiene ejecución
- 📥 **Pull + Up combo**: `docker compose pull` → `docker compose up -d` atómico
- 🧹 **Limpieza automática**: `docker image prune -f` libera espacio (imágenes *dangling*)
- 🎨 **Feedback visual**: emojis 📥🚀✅❌🧹 para progreso claro en consola
- 🏠 **Rutas flexibles**: usa `$HOME/docker/` — funciona con cualquier usuario
- ♻️ **Idempotente**: mismo resultado al ejecutar N veces; seguro para reintentos
- ⏰ **Cron-ready**: diseñado para *cron jobs* automatizados (argumento obligatorio)
- 📦 **Zero dependencies**: solo Bash + Docker CLI (v2 `docker compose`)

---

## 📋 Requisitos del sistema

- **Bash** ≥ 4.0 (compatible con `[[ ]]`, `read -rp`)
- **Docker Engine** ≥ 20.10 + **Docker Compose v2** (`docker compose` plugin)
- Usuario con permisos para ejecutar `docker` (grupo `docker` o `sudo`)
- Estructura de directorios: `$HOME/docker/<nombre-contenedor>/docker-compose.yml`
- Conexión a registro de imágenes (Docker Hub, GHCR, registry privado)

---

## 🐳 Instalación

### Opción A: Descarga directa (recomendada)

```bash
cd ~
wget https://raw.githubusercontent.com/JLalib/update-container.sh/main/update-container.sh
chmod +x update-container.sh
```

### Opción B: Clonar repositorio

```bash
git clone https://github.com/JLalib/update-container.sh.git
cd update-container.sh
chmod +x update-container.sh
# Opcional: mover a ~/ o /usr/local/bin/
cp update-container.sh ~/update-container.sh
```

### Opción C: Copia manual

Crea el archivo `update-container.sh` con el siguiente contenido:

```bash
#!/bin/bash
#
# update-container.sh
# Actualiza y relanza un contenedor Docker Compose ubicado en $HOME/docker/
# (usa el home del usuario que ejecuta el script, sea quien sea)
#
# Uso:
# ./update-container.sh -> pide el nombre por teclado
# ./update-container.sh nombre -> lo recibe como argumento

set -uo pipefail
# -u: variables no definidas dan error | pipefail: falla si falla algún comando en un pipe
# (Nota: no usamos -e a propósito, porque queremos capturar y reportar errores nosotros mismos)

DOCKER_BASE_DIR="$HOME/docker"

# --- 1. Obtener el nombre del contenedor (por argumento o interactivo) ---
if [ $# -ge 1 ]; then
    micontenedor="$1"
else
    read -rp "Por favor, introduce el nombre del contenedor: " micontenedor
fi

# Validación básica: que no esté vacío y no contenga rutas raras (../ etc.)
if [[ -z "$micontenedor" || "$micontenedor" == *..* || "$micontenedor" == */* ]]; then
    echo "❌ Nombre de contenedor no válido: '$micontenedor'" >&2
    exit 1
fi

contenedor_dir="${DOCKER_BASE_DIR}/${micontenedor}"
echo "El nombre del contenedor es: $micontenedor"

# --- 2. Verificar que el directorio existe ---
if [ ! -d "$contenedor_dir" ]; then
    echo "❌ El directorio $contenedor_dir no existe." >&2
    exit 1
fi

# --- 3. Cambiar al directorio ---
if ! cd "$contenedor_dir"; then
    echo "❌ No se pudo cambiar al directorio $contenedor_dir." >&2
    exit 1
fi

# --- 4. Pull + up, comprobando cada paso por separado ---
echo "📥 Descargando imágenes nuevas..."
if ! docker compose pull; then
    echo "❌ Hubo un problema al ejecutar 'docker compose pull'." >&2
    exit 1
fi

echo "🚀 Levantando el contenedor..."
if ! docker compose up -d; then
    echo "❌ Hubo un problema al ejecutar 'docker compose up -d'." >&2
    exit 1
fi

echo "✅ Contenedor actualizado y en ejecución."

# --- 5. Limpieza de imágenes obsoletas ---
echo "🧹 Eliminando imágenes obsoletas de Docker..."
docker image prune -f

echo "✅ Todo se ha actualizado correctamente."
```

---

## ⚙️ Configuración

1. **Estructura de directorios esperada**  
   El script busca `docker-compose.yml` en `$HOME/docker/<contenedor>/`. Ejemplo:

   ```
   $HOME/docker/
   ├── authentik/
   │   └── docker-compose.yml
   ├── dawarich/
   │   └── docker-compose.yml
   ├── heimdall/
   │   └── docker-compose.yml
   └── update-container.sh   (opcional, puede estar en ~/)
   ```

2. **Personalizar `DOCKER_BASE_DIR`** (opcional)  
   Si tus contenedores están en otra ruta (ej. `/opt/docker/`), edita la línea 13 del script:

   ```bash
   DOCKER_BASE_DIR="/opt/docker"  # o cualquier ruta absoluta
   ```

3. **Verificar Docker Compose v2**  
   El script usa `docker compose` (v2). Si tu sistema solo tiene `docker-compose` (v1), cambia las líneas 40 y 46:

   ```bash
   # Cambiar "docker compose" por "docker-compose"
   if ! docker-compose pull; then ...
   if ! docker-compose up -d; then ...
   ```

4. **Permisos de ejecución**  
   ```bash
   chmod +x update-container.sh
   ```

---

## 🚀 Primeros pasos

1. **Clona o descarga el script** (ver sección *Instalación*)
2. **Hazlo ejecutable**: `chmod +x update-container.sh`
3. **Verifica tu estructura** bajo `$HOME/docker/`:
   ```bash
   ls -la ~/docker/
   # Deberías ver carpetas como authentik/, dawarich/, etc. cada una con docker-compose.yml
   ```
4. **Ejecuta en modo interactivo** (primer test):
   ```bash
   ./update-container.sh
   # Introduce: authentik
   ```
5. **Ejecuta con argumento** (para cron/automatización):
   ```bash
   ./update-container.sh authentik
   ```
6. **Configura cron** (ver *Casos de uso* y *Gestión y mantenimiento*)

---

## 💡 Casos de uso

- 🔧 **Actualización manual puntual**: `./update-container.sh authentik` — actualiza un solo stack
- ⏰ **Automatización nocturna con cron**: actualizaciones semanales/diarias sin intervención
- 🔁 **Batch update multi-contenedor**: loop en script wrapper para actualizar todos los stacks
- 🛡️ **Pre-backup + update**: `docker compose exec db pg_dump > backup.sql && ./update-container.sh app`
- 📊 **Monitoreo con logs**: redirige salida a archivo para auditoría y alertas
- 🧪 **Entornos de staging**: mismo script, distinta `$HOME` o `DOCKER_BASE_DIR` por usuario

---

## 🔒 Acceso remoto seguro

> **Nota**: Este script se ejecuta **localmente** en el host Docker. No expone puertos ni servicios de red.
> Para gestión remota segura:
> - Usa **SSH** con claves ed25519: `ssh user@host ./update-container.sh authentik`
> - O **Ansible**/`ssh` + `command` module para orquestación multi-host
> - Evita exponer Docker socket (`/var/run/docker.sock`) por red

---

## 🛠️ Gestión y mantenimiento

### Cron jobs (actualización automática)

```bash
crontab -e
```

Ejemplos de entradas:

```cron
# Actualizar authentik cada domingo a las 03:00
0 3 * * 0 /home/usuario/update-container.sh authentik >> /var/log/update-container.log 2>&1

# Actualizar dawarich cada lunes a las 04:00
0 4 * * 1 /home/usuario/update-container.sh dawarich >> /var/log/update-container.log 2>&1

# Actualizar TODOS los contenedores (wrapper loop) cada domingo a las 02:00
0 2 * * 0 for app in authentik dawarich heimdall; do /home/usuario/update-container.sh "$app"; done >> /var/log/update-all.log 2>&1
```

> ⚠️ **Importante**: Usa **rutas absolutas** en cron (`/home/usuario/...`, no `./`). Cron no carga `.bashrc` ni `$PATH` completo.

### Logs y debugging

- **Ver logs de cron**: `journalctl -u cron -f` o revisa `/var/log/update-container.log`
- **Modo verbose (debug)**: añade `set -x` tras `set -uo pipefail` en el script
- **Capturar solo errores**: `./update-container.sh authentik 2> errors.log`

### Troubleshooting común

| Problema | Solución |
|----------|----------|
| `El directorio no existe` | Verifica `ls -la ~/docker/<contenedor>/` y que exista `docker-compose.yml` |
| `docker compose command not found` | Instala Docker Compose v2 plugin o cambia a `docker-compose` (v1) en el script |
| `Permission denied` | `chmod +x update-container.sh` y usuario en grupo `docker` |
| Cron no ejecuta | Usa ruta absoluta; verifica `cron` activo (`systemctl status cron`) |
| Pull falla (red/registry) | Revisa conectividad, credenciales (`docker login`), rate limits Docker Hub |

### Extensiones sugeridas (PRs bienvenidos)

- ✅ Verificar cambios de configuración antes de `up` (`docker compose config --quiet`)
- 🔄 Rollback automático si `up -d` falla (tags previos)
- 📬 Notificaciones (email, Telegram, Gotify, ntfy) en fallo/éxito
- 📦 Versión multi-contenedor: actualiza **todos** los stacks bajo `$HOME/docker/` sin argumentos
- 🏷️ Soporte para `.env` files y `COMPOSE_PROJECT_NAME`

---

## 📝 Licencia

Este proyecto está licenciado bajo la **Licencia MIT** — ver el archivo [LICENSE](LICENSE) para detalles.

```
MIT License

Copyright (c) 2026 JLalib

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

> 📖 **Artículo original**: [Cómo instalar / actualizar contenedores Docker con Script "update-container.sh"](https://genbyte.blogspot.com/2026/08/como-instalar-actualizar-contenedores.html) — Guía completa con análisis línea a línea, seguridad, cron y troubleshooting.