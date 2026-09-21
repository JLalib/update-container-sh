# 🐳 update-container.sh

[![GitHub stars](https://img.shields.io/github/stars/JLalib/update-container.sh?style=for-the-badge&logo=github)](https://github.com/JLalib/update-container.sh/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/JLalib/update-container.sh?style=for-the-badge&logo=github)](https://github.com/JLalib/update-container.sh/network/members)
[![GitHub issues](https://img.shields.io/github/issues/JLalib/update-container.sh?style=for-the-badge&logo=github)](https://github.com/JLalib/update-container.sh/issues)
[![Docker](https://img.shields.io/badge/Docker-Compatible-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

## 📋 Descripción general

**update-container.sh** es un script Bash profesional diseñado para automatizar la actualización de contenedores Docker Compose autohospedados. Ejecuta el flujo completo de mantenimiento: descarga de nuevas imágenes (`docker compose pull`), relanzamiento de servicios (`docker compose up -d`) y limpieza de imágenes obsoletas (`docker image prune -f`).

Está pensado para **homelabs** y administradores de sistemas que buscan reducir el riesgo operacional y el tiempo invertido en tareas repetitivas, ofreciendo validación segura de entrada, manejo robusto de errores (`set -uo pipefail`) y salida visual amigable con emojis. Funciona en modo interactivo (pide el nombre) o por argumento (ideal para `cron`), asumiendo una estructura de directorios estándar en `$HOME/docker/`.

## ✨ Características principales

- 🔄 **Modo dual**: Interactivo (prompt) o por argumento CLI (`./update-container.sh authentik`).
- 🛡️ **Validación segura**: Previene *path traversal* (`../`, `/`) y entradas vacías.
- ⚙️ **Error handling robusto**: `set -uo pipefail`; cada paso validado individualmente; fallo detiene ejecución inmediata.
- 📥 **Pull + Up atómico**: `docker compose pull` → `docker compose up -d` en secuencia garantizada.
- 🧹 **Limpieza automática**: `docker image prune -f` libera espacio de imágenes *dangling* tras actualizar.
- 🎨 **Feedback visual**: Emojis y colores en consola (📥🚀✅❌🧹) para seguimiento claro.
- 🏠 **Rutas relativas a `$HOME`**: Funciona con cualquier usuario sin *hardcodear* paths (`$HOME/docker/`).
- ♻️ **Idempotente**: Seguro de ejecutar múltiples veces; mismo resultado.
- ⏰ **Cron-ready**: Diseñado para automatización programada sin intervención manual.
- 📦 **Zero dependencias**: Solo Bash puro + Docker CLI (v2 `docker compose`).

## 📋 Requisitos del sistema

- **OS**: Linux (cualquier distro con Bash), macOS, WSL2.
- **Shell**: Bash ≥ 4.0 (usa `[[ ]]`, `read -rp`, `pipefail`).
- **Docker Engine**: ≥ 20.10 (con plugin Compose v2 integrado: `docker compose`).
- **Permisos**: Usuario en grupo `docker` o `sudo` (script no usa `sudo` internamente).
- **Estructura esperada**: Directorio `$HOME/docker/<contenedor>/docker-compose.yml`.

## 🐳 Instalación

### Opción A: Descarga directa (recomendada)

```bash
cd ~
wget https://raw.githubusercontent.com/JLalib/update-container.sh/main/update-container.sh
```

### Opción B: Clonar repositorio

```bash
git clone https://github.com/JLalib/update-container.sh.git
cd update-container.sh
```

### Paso 2: Dar permisos de ejecución

```bash
chmod +x update-container.sh
```

### Paso 3: Verificar estructura de directorios

El script espera tus stacks en `$HOME/docker/`:

```text
$HOME/docker/
├── authentik/
│   └── docker-compose.yml
├── dawarich/
│   └── docker-compose.yml
├── heimdall/
│   └── docker-compose.yml
└── update-container.sh   # (opcional, puedes dejarlo en ~/)
```

> 💡 **Tip**: Si tu base es distinta (ej. `/opt/docker/`), edita la variable `DOCKER_BASE_DIR` en la línea 13 del script.

## ⚙️ Configuración

1. **Directorio base**: Modifica `DOCKER_BASE_DIR="$HOME/docker"` (línea 13) si tus stacks están en otra ruta.
2. **Usuario Docker**: Asegúrate de que el usuario que ejecuta el script pertenezca al grupo `docker`:
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```
3. **Editor preferido**: Para editar el script usa `nano`, `vim` o `code`:
   ```bash
   nano update-container.sh
   ```
4. **Logs persistentes (opcional)**: Redirige salida a archivo en `cron` (ver [Gestión y mantenimiento](#-gestión-y-mantenimiento)).

## 🚀 Primeros pasos

1. **Descarga y prepara el script** (ver [Instalación](#-instalación)).
2. **Coloca tus `docker-compose.yml`** en `$HOME/docker/<nombre-servicio>/`.
3. **Ejecuta en modo interactivo** para probar:
   ```bash
   ./update-container.sh
   # Introduce: authentik
   ```
4. **Verifica salida exitosa**:
   ```text
   El nombre del contenedor es: authentik
   📥 Descargando imágenes nuevas...
   🚀 Levantando el contenedor...
   ✅ Contenedor actualizado y en ejecución.
   🧹 Eliminando imágenes obsoletas de Docker...
   ✅ Todo se ha actualizado correctamente.
   ```
5. **Automatiza con cron** (ver [Casos de uso](#-casos-de-uso)).

## 💡 Casos de uso

- **Actualización manual puntual**: `./update-container.sh authentik` (un solo comando).
- **Mantenimiento programado (cron)**: Updates nocturnos semanales sin intervención.
- **Batch update multi-servicio**: Loop en bash actualiza toda la pila homelab ordenadamente.
- **Pre-backup hook**: Ejecutar script tras confirmar backup de BD (`pg_dump`, `mysqldump`).
- **CI/CD ligero**: Integrar en pipelines simples que requieran pull/up de stacks compose.
- **Entornos multi-usuario**: Cada usuario gestiona sus contenedores en su `$HOME/docker/`.

## 🔒 Acceso remoto seguro

Aunque el script se ejecuta localmente, la automatización remota segura implica:

1. **SSH con claves**: Configura acceso sin contraseña (`ssh-copy-id user@host`).
2. **Comando forzado (opcional)**: En `~/.ssh/authorized_keys` limita la clave a solo ejecutar el script:
   ```text
   command="/home/user/update-container.sh authentik",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAA...
   ```
3. **Sudoers sin pass (si hace falta docker)**: `/etc/sudoers.d/docker-update`:
   ```text
   user ALL=(ALL) NOPASSWD: /usr/bin/docker compose pull, /usr/bin/docker compose up -d, /usr/bin/docker image prune -f
   ```
   > ⚠️ Preferible añadir usuario a grupo `docker` antes que `sudo`.

## 🛠️ Gestión y mantenimiento

### Actualizar el propio script

```bash
cd ~
wget -N https://raw.githubusercontent.com/JLalib/update-container.sh/main/update-container.sh
chmod +x update-container.sh
```

### Cron jobs recomendados

Edita `crontab -e` (usa **rutas absolutas**):

```cron
# Actualizar authentik cada domingo 03:00
0 3 * * 0 /home/usuario/update-container.sh authentik >> /var/log/update-authentik.log 2>&1

# Actualizar dawarich cada lunes 04:00
0 4 * * 1 /home/usuario/update-container.sh dawarich >> /var/log/update-dawarich.log 2>&1

# Batch update todos los domingos 02:00
0 2 * * 0 for app in authentik dawarich heimdall; do /home/usuario/update-container.sh "$app" >> /var/log/update-batch.log 2>&1; done
```

### Rotación de logs (logrotate)

Crea `/etc/logrotate.d/update-container`:

```text
/var/log/update-*.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 640 usuario usuario
}
```

### Debugging verbose

Añade `set -x` tras `set -uo pipefail` para traza completa:

```bash
set -uo pipefail
set -x  # Imprime cada comando antes de ejecutar
```

## 📝 Licencia

Este proyecto está licenciado bajo la **Licencia MIT** - ver el archivo [LICENSE](LICENSE) para detalles.

---

> 📖 **Artículo original**: [Cómo instalar / actualizar contenedores Docker con Script "update-container.sh"](https://genbyte.blogspot.com/2026/08/como-instalar-actualizar-contenedores.html) en **Genbyte**.