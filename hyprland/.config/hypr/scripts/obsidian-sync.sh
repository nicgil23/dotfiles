#!/usr/bin/env bash

# Definición de variables para mayor claridad
LOCAL_PATH="$HOME/Documents/Obsidian"
REMOTE_PATH="Obsidian:Mi unidad/DriveSyncFiles/La Enciclopedia del Conocimiento Universal"

# Ejecución del comando
rclone bisync "$LOCAL_PATH" "$REMOTE_PATH" --verbose --conflict-resolve newer

# Captura del estado de salida del comando anterior
if [ $? -eq 0 ]; then
    notify-send "Sincronización exitosa" "Obsidian se ha sincronizado correctamente con Google Drive." --icon=distributor-logo-archlinux
else
    notify-send "Fallo en la sincronización" "Se ha producido un error al sincronizar Obsidian. Revise los logs o ejecute manualmente." --urgency=critical --icon=dialog-error
fi