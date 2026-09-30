#!/bin/bash

# 1. Configuración de ruta base
BASE_PATH="/home/genbyte/docker"

# 2. Obtener nombre del contenedor (argumento o prompt)
micontenedor=${1:-$(read -p "Introduce el nombre del contenedor: " temp && echo $temp)}
TARGET_DIR="$BASE_PATH/$micontenedor"

# 3. IDENTIFICAR EL ARCHIVO DE CONFIGURACIÓN (YAML o YML)
if [ -f "$TARGET_DIR/compose.yaml" ]; then
    COMPOSE_FILE="$TARGET_DIR/compose.yaml"
elif [ -f "$TARGET_DIR/compose.yml" ]; then
    COMPOSE_FILE="$TARGET_DIR/compose.yml"
elif [ -f "$TARGET_DIR/docker-compose.yml" ]; then
    COMPOSE_FILE="$TARGET_DIR/docker-compose.yml"
elif [ -f "$TARGET_DIR/docker-compose.yaml" ]; then
    COMPOSE_FILE="$TARGET_DIR/docker-compose.yaml"
else
    echo "❌ Error: No se encontró ningún archivo de compose en $TARGET_DIR"
    exit 1
fi

echo "📂 Usando configuración: $(basename $COMPOSE_FILE)"

# 4. CAPTURAR ESTADO PREVIO (¿Estaba corriendo?)
# Filtramos por el primer servicio definido en el archivo
IS_RUNNING=$(docker compose -f "$COMPOSE_FILE" ps --format "{{.State}}" | grep -i "running")

if [ ! -z "$IS_RUNNING" ]; then
    ESTADO_PREVIO="running"
    echo "▶️ El contenedor está actualmente ENCENDIDO."
else
    ESTADO_PREVIO="stopped"
    echo "⏸️ El contenedor está actualmente PARADO."
fi

# 5. ACTUALIZACIÓN (Pull)
echo "🚀 Buscando actualizaciones en el registro..."
docker compose -f "$COMPOSE_FILE" pull

# 6. RECREAR SIN ARRANCAR (Aplica la nueva imagen)
# --no-start es vital para no encender lo que estaba apagado
docker compose -f "$COMPOSE_FILE" up --no-start --remove-orphans

# 7. RESTAURAR ESTADO SI CORRESPONDÍA
if [ "$ESTADO_PREVIO" == "running" ]; then
    echo "⚡ Reiniciando para aplicar cambios..."
    docker compose -f "$COMPOSE_FILE" up -d
else
    echo "✅ Imagen actualizada. El contenedor permanece PARADO como estaba."
fi

# 8. LIMPIEZA
docker image prune -f
echo "✨ Proceso finalizado con éxito."
