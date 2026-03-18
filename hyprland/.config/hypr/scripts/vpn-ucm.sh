#!/bin/bash
# Script para automatizar la conexión GlobalProtect UCM
# Dependencias: notify-send, openconnect, gp-saml-gui

GATEWAY="galeria.ucm.es"

# Si existe una conexión a VPN previa se para su ejecución; en caso contrario se inicia una nueva
if pgrep -x "openconnect" >/dev/null; then
  pkexec pkill -SIGINT openconnect
  notify-send "VPN UCM" "Conexión con ${GATEWAY} detenida"
  exit 0
fi

# Solicitamos la conexión de tipo SAML
VPN_CMD=$(gp-saml-gui --gateway "$GATEWAY" 2>&1 | awk "/^[[:space:]]*echo/,/${GATEWAY}/" | sed "s/sudo /pkexec /")
echo "${VPN_CMD}"

# Verificamos si se ha obtenido un comando válido
if [ $? -eq 0 ] && [ -n "$VPN_CMD" ]; then
  eval "$VPN_CMD --background"

  if pgrep -x "openconnect" >/dev/null; then
    notify-send "VPN UCM" "Autenticación exitosa. Conexión con ${GATEWAY} establecida correctamente."
  else 
    notify-send "VPN UCM" "Error al intentar conseguir establecer conexión con ${GATEWAY}."
  fi
else
  notify-send "VPN UCM" "Error al intentar conseguir el token de autenticación. Verifique sus credenciales o la conexión."
  exit 1
fi
