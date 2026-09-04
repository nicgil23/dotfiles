#!/usr/bin/env bash

# Directorios y rutas de Spicetify
SPICETIFY_DIR="$HOME/.config/spicetify"
EXT_DIR="$SPICETIFY_DIR/Extensions"
EXT_FILE="$EXT_DIR/adblock.js"
CONFIG_FILE="$SPICETIFY_DIR/config-xpui.ini"
URL="https://raw.githubusercontent.com/rxri/spicetify-extensions/main/adblock/adblock.js"

mkdir -p "$EXT_DIR"

# 1. Verificar si adblock.js existe y no está vacío. Si no existe, descargarlo.
if [ ! -s "$EXT_FILE" ]; then
    echo "[Spicetify Check] Plugin adblockify no encontrado o vacío. Descargando..."
    curl -fsSL "$URL" -o "$EXT_FILE"
fi

if command -v spicetify &>/dev/null; then
    NEED_APPLY=0

    # 2. Verificar que adblock.js esté activo en la configuración de Spicetify
    if ! grep -q "adblock.js" "$CONFIG_FILE" 2>/dev/null; then
        echo "[Spicetify Check] Añadiendo adblock.js a las extensiones de Spicetify..."
        spicetify config extensions adblock.js
        spicetify config experimental_features 1
        NEED_APPLY=1
    fi

    # 3. Verificar si Spotify tiene Spicetify aplicado en /opt/spotify
    if ! grep -q "spicetify" /opt/spotify/Apps/xpui/index.html 2>/dev/null; then
        echo "[Spicetify Check] Detectado Spotify sin parchar (debido a una actualización de Spotify o desinstalación del parche)."
        NEED_APPLY=1
    fi

    # 4. Si se requiere (re)aplicar Spicetify
    if [ "$NEED_APPLY" -eq 1 ]; then
        echo "[Spicetify Check] Re-aplicando Spicetify y activando adblock..."
        
        # Corregir permisos de /opt/spotify si pacman los cambió a root
        if [ ! -w /opt/spotify ] || [ ! -w /opt/spotify/Apps ]; then
            echo "[Spicetify Check] Solicitando permisos para escribir en /opt/spotify..."
            pkexec chown -R "$USER:$USER" /opt/spotify 2>/dev/null || sudo chown -R "$USER:$USER" /opt/spotify 2>/dev/null
        fi

        pkill -x spotify 2>/dev/null
        spicetify apply || spicetify backup apply || spicetify restore backup apply
    fi
fi
