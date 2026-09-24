#!/usr/bin/env bash

# Definición de variables
LOCAL_PATH="$HOME/Documents/Obsidian"
REMOTE_PATH="Obsidian:Mi unidad/DriveSyncFiles/La Enciclopedia del Conocimiento Universal"
LOG_DIR="$HOME/.cache/rclone"
LOG_FILE="$LOG_DIR/obsidian-sync.log"

mkdir -p "$LOG_DIR"

echo "=== Sincronización iniciada: $(date) ===" >> "$LOG_FILE"

# Ejecución de la sincronización con recuperación automática y expiración de bloqueos huérfanos
rclone bisync "$LOCAL_PATH" "$REMOTE_PATH" \
    --verbose \
    --conflict-resolve newer \
    --max-lock 15m \
    --recover \
    --resilient >> "$LOG_FILE" 2>&1

STATUS=$?

echo "=== Sincronización finalizada con código $STATUS: $(date) ===" >> "$LOG_FILE"

# Captura del estado de salida
if [ $STATUS -eq 0 ]; then
    notify-send "Sincronización exitosa" "Obsidian se ha sincronizado correctamente con Google Drive." --icon=obsidian
else
    notify-send "Fallo en la sincronización" "Error al sincronizar Obsidian. Consulta el log en $LOG_FILE" --urgency=critical --icon=dialog-error
fi

exit $STATUS