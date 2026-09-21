# 🐳 update-container.sh — Automatiza actualizaciones Docker Compose

[![GitHub](https://img.shields.io/github/stars/JLalib/update-container.sh?style=social)](https://github.com/JLalib/update-container.sh)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker)](https://docs.docker.com/compose/)
[![License](https://img.shields.io/github/license/JLalib/update-container.sh)](LICENSE)

Script Bash profesional para actualizar contenedores Docker Compose de forma segura, idempotente y lista para producción. Pull + Up + Prune en un solo comando.

---

## 📋 Descripción general

**update-container.sh** automatiza el ciclo completo de actualización de contenedores Docker Compose autohospedados: descarga imágenes nuevas (`docker compose pull`), relanza servicios (`docker compose up -d`) y limpia imágenes obsoletas (`docker image prune -f`). Incluye validación segura de entrada, error handling robusto, modo dual (interactivo o por argumento) y salida visual con emojis. Diseñado para homelabs y sysadmins que buscan reducir riesgo operacional y ahorrar tiempo en mantenimiento.

---

## ✨ Características principales

- 🔄 **Modo dual**: interactivo (pide nombre) o por argumento (`./update-container.sh authentik`)
- 🛡️ **Validación segura**: previene path traversal (`../`, `/`) y entradas vacías
- ⚙️ **Error handling robusto**: `set -uo pipefail`, cada paso validado, salida inmediata en error
- 📥 **Pull + Up combo**: `docker compose pull` → `docker compose up -d` en secuencia atómica
- 🧹 **Limpieza automática**: `docker image prune -f` libera espacio de imágenes dangling
- 🎨 **Feedback visual**: emojis 📥🚀✅❌🧹 para progreso claro en consola
- 🏠 **Personalizable con `$HOME`**: estructura `$HOME/docker/<contenedor>/`, funciona con cualquier usuario
- ♻️ **Idempotente**: seguro ejecutar múltiples veces, mismo resultado
- ⏰ **Cron-ready**: automatiza updates nocturnos pasando nombre por argumento
- 📦 **Zero dependencias**: solo Bash + Docker CLI (v2 `docker compose`)

---

## 📋 Requisitos del sistema

- **Bash** ≥ 4.0 (compatible con Linux, macOS, WSL)
- **Docker Engine** ≥ 20.10 con **Docker Compose v2** (`docker compose` plugin)
- **Permisos** de ejecución sobre el script (`chmod +x`)
- **Estructura de directorios** `$HOME/docker/<contenedor>/docker-compose.yml`
- **Conexión a red** para pull de imágenes desde registry (Docker Hub, GHCR, etc.)

---

## 🐳 Instalación

### Opción A: Descarga directa (recomendada)

```bash
cd ~
wget https://raw.githubusercontent.com/JLalib/update-container.sh/main/update-container.sh
chmod +x update-container.sh
```

### Opción B: Copia manual

```bash
# Crea el archivo
cat > update-container.sh << 'EOF'
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
EOF
chmod +x update-container.sh
```

### Verificar estructura de directorios

El script espera esta organización:

```text
$HOME/docker/
├── authentik/
│   └── docker-compose.yml
├── dawarich/
│   └── docker-compose.yml
├── heimdall/
│   └── docker-compose.yml
└── update-container.sh   # (opcional, puede estar en ~/)
```

> 💡 **Tip**: Si tu estructura difiere (ej. `/opt/docker/`), edita la variable `DOCKER_BASE_DIR` en el script.

---

## ⚙️ Configuración

1. **Personalizar `DOCKER_BASE_DIR`** (línea 13 del script):
   ```bash
   DOCKER_BASE_DIR="$HOME/docker"  # Cambia si usas otra ruta base
   ```
2. **Asegurar permisos de Docker**: tu usuario debe estar en el grupo `docker` o usar `sudo`.
3. **Verificar Docker Compose v2**: `docker compose version` debe mostrar v2.x.
4. **Ubicar el script**: en `~/` (recomendado) o en `$HOME/docker/`.
5. **Opcional: alias en `.bashrc`** para acceso global:
   ```bash
   alias update-container='~/update-container.sh'
   ```

---

## 🚀 Primeros pasos

1. **Descarga e instala** el script (sección Instalación).
2. **Prepara un contenedor** con su `docker-compose.yml` en `$HOME/docker/<nombre>/`.
3. **Ejecuta en modo interactivo**:
   ```bash
   ./update-container.sh
   # Por favor, introduce el nombre del contenedor: authentik
   ```
4. **O ejecuta directo con argumento**:
   ```bash
   ./update-container.sh authentik
   ```
5. **Verifica salida**: verás 📥 Pull → 🚀 Up → ✅ Éxito → 🧹 Prune → ✅ Final.

---

## 💡 Casos de uso

- **Actualización manual puntual**: `./update-container.sh authentik` antes de dormir.
- **Cron job semanal**: actualiza `authentik` domingos 3 AM, `dawarich` lunes 4 AM.
- **Batch update**: loop sobre lista de contenedores en script wrapper.
- **Pre-backup + update**: `docker compose exec postgres pg_dump > backup.sql && ./update-container.sh dawarich`.
- **CI/CD ligero**: integra en pipelines simples que requieren pull + up sin dependencias extra.

---

## 🔒 Acceso remoto seguro

El script se ejecuta localmente en el host Docker. Para gestión remota:

- **SSH + script**: `ssh user@host './update-container.sh authentik'`
- **Ansible**: usa módulo `command` o `shell` con el script en el host destino.
- **Portainer / Watchtower**: alternativas GUI/daemon; este script es CLI minimalista y auditable.
- **Claves SSH sin passphrase + cron remoto**: para automatización entre hosts de confianza.

---

## 🛠️ Gestión y mantenimiento

| Acción | Comando / Método |
|--------|------------------|
| **Ver logs de cron** | `tail -f /var/log/update-container.log` |
| **Debug verbose** | Añade `set -x` tras `set -uo pipefail` en el script |
| **Probar sin cambios** | `docker compose pull && docker compose config` (dry-run) |
| **Rollback manual** | `docker compose down && docker compose up -d` (usa imágenes previas) |
| **Actualizar script** | `wget -O update-container.sh <url> && chmod +x update-container.sh` |
| **Añadir notificaciones** | Inserta `curl -X POST <webhook>` en bloques `if ! ...; then` |

**Solución de problemas comunes**:

- ❌ `"El directorio no existe"` → `ls -la ~/docker/authentik/` (verifica `docker-compose.yml`).
- ❌ `"docker compose command not found"` → instala plugin Compose v2 o cambia a `docker-compose` (v1) en líneas 40 y 46.
- ❌ `"Permission denied"` → `chmod +x update-container.sh` y usuario en grupo `docker`.
- ❌ **Cron no ejecuta** → usa ruta absoluta: `/home/usuario/update-container.sh authentik`.

---

## 📝 Licencia

MIT License — libre para uso personal, comercial, modificación y distribución. Ver [LICENSE](LICENSE).

---

> 📖 **Artículo original**: [Cómo instalar / actualizar contenedores Docker con Script "update-container.sh"](https://genbyte.blogspot.com/2026/08/como-instalar-actualizar-contenedores.html) — Genbyte Blog