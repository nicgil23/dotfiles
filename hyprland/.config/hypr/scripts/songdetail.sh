#!/bin/bash

# Obtenemos el nombre del reproductor activo
player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null)

# Asignamos el icono basándonos en el origen
case "$player" in
"spotify")
  icon=""
  ;;
"firefox" | "chromium" | "brave" | "chrome")
  icon=""
  ;;
*)
  icon=""
  ;;
esac

# Generamos la salida con el icono detectado
song_info=$(playerctl metadata --format "$icon  {{title}} - {{artist}}" 2>/dev/null)

# Verificamos si hay algo reproduciéndose para evitar una cadena vacía
if [ -z "$song_info" ]; then
  echo ""
else
  echo "$song_info"
fi

