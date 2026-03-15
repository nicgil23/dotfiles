#!/bin/bash

# Función para alternar el proceso
toggle_hypridle() {
    if pgrep -x "hypridle" > /dev/null; then
        pkill -x hypridle
    else
        hypridle &
    fi
}

# Función para enviar el estado a Waybar en formato JSON
get_status() {
    if pgrep -x "hypridle" > /dev/null; then
        echo '{"text": "", "class": "active", "tooltip": "Hypridle: Activo"}'
    else
        echo '{"text": "", "class": "inactive", "tooltip": "Hypridle: Desactivado"}'
    fi
}

# Lógica principal basada en el argumento
case "$1" in
    toggle)
        toggle_hypridle
        ;;
    status)
        get_status
        ;;
    *)
        echo "Uso: $0 {toggle|status}"
        exit 1
        ;;
esac