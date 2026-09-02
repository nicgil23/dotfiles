#!/usr/bin/env bash

# Directorios y rutas de Spicetify
EXT_DIR="$HOME/.config/spicetify/Extensions"
EXT_FILE="$EXT_DIR/adblock.js"
URL="https://raw.githubusercontent.com/rxri/spicetify-extensions/main/adblock/adblock.js"

if [ ! -f "$EXT_FILE" ]; then
    echo "[Spicetify Check] Plugin adblockify NO encontrado. Descargando e instalando..."
    mkdir -p "$EXT_DIR"
    
    if curl -fsSL "$URL" -o "$EXT_FILE"; then
        echo "[Spicetify Check] Descarga completada con éxito."
    else
        echo "[Spicetify Check] ERROR: No se pudo descargar la extensión." >&2
        exit 1
    fi
    
    if command -v spicetify &> /dev/null; then
        echo "[Spicetify Check] Activando extensión en Spicetify..."
        spicetify config extensions adblock.js
        spicetify config experimental_features 1
        pkill -x spotify 2>/dev/null
        spicetify apply || spicetify restore backup apply
    fi
fi
