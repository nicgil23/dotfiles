#!/bin/bash

notified_100=false
notified_20=false
notified_10=false

bat_path=$(ls -d /sys/class/power_supply/BAT* | head -n 1)

if [ -z "$bat_path" ]; then
  echo "No se encontró ninguna batería."
  exit 1
fi

while true; do
  nivel=$(cat "$bat_path/capacity")
  estado=$(cat "$bat_path/status")

  if [ "$estado" = "Charging" ] || [ "$estado" = "Full" ]; then
    notified_20=false
    notified_10=false

    if [ "$nivel" -ge 100 ] && [ "$notified_100" = false ]; then
      notify-send -u normal "Batería" "La batería está al 100%."
      notified_100=true
    fi
  elif [ "$estado" = "Discharging" ]; then
    notified_100=false

    if [ "$nivel" -le 10 ] && [ "$notified_10" = false ]; then
      notify-send -u critical "Batería muy baja" "Queda un 10% de batería."
      notified_10=true
      notified_20=true
    elif [ "$nivel" -le 20 ] && [ "$notified_20" = false ]; then
      notify-send -u normal "Batería baja" "Queda un 20% de batería."
      notified_20=true
    fi
  fi

  sleep 60
done