#!/bin/bash
# ==============================================================================
# Captive Portal Detector & Login Notifier
# ==============================================================================
# Detecta automáticamente redes Wi-Fi que requieren autenticación web (como UCM)
# y envía una notificación interactiva con Nandoroid para abrir el portal en el
# navegador por defecto (xdg-open).
# ==============================================================================

PROBE_URLS=(
    "http://detectportal.firefox.com/canonical.html"
    "http://ping.archlinux.org/nm-check.txt"
    "http://connectivity-check.ubuntu.com"
)

# Estado interno
NOTIFIED_SSID=""

get_active_ssid() {
    local ssid
    ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 | head -n 1)
    if [ -z "$ssid" ]; then
        ssid=$(nmcli -t -f active,name,type connection show --active 2>/dev/null | grep ':802-11-wireless' | cut -d: -f2 | head -n 1)
    fi
    echo "${ssid:-Wi-Fi}"
}

get_portal_login_url() {
    local redirect_url=""
    for probe in "${PROBE_URLS[@]}"; do
        redirect_url=$(curl -s -I -m 3 "$probe" 2>/dev/null | grep -i "^location:" | awk '{print $2}' | tr -d '\r\n')
        if [ -n "$redirect_url" ]; then
            echo "$redirect_url"
            return 0
        fi
    done

    # Fallback: abrir una petición HTTP pura no-cifrada (neverssl.com).
    # En una red con portal cautivo (como UCM), el router intercepta esta petición
    # y la redirige inmediatamente a la pantalla de login.
    # En una red con internet, muestra un mensaje indicando que ya hay conexión.
    echo "http://neverssl.com"
}

check_connectivity_state() {
    # 1. Comprobación nativa de NetworkManager
    local nm_state
    nm_state=$(nmcli networking connectivity check 2>/dev/null)
    if [ "$nm_state" = "portal" ]; then
        echo "portal"
        return 0
    fi

    # 2. Comprobación HTTP en caso de que NetworkManager aún no haya actualizado el estado
    for probe in "${PROBE_URLS[@]}"; do
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" -m 3 "$probe" 2>/dev/null)
        if [[ "$http_code" =~ ^(301|302|303|307|308)$ ]]; then
            echo "portal"
            return 0
        fi
    done

    if [ "$nm_state" = "full" ]; then
        echo "full"
        return 0
    elif [ "$nm_state" = "limited" ]; then
        echo "limited"
        return 0
    else
        echo "none"
        return 0
    fi
}

send_portal_notification() {
    local ssid="$1"
    local login_url="$2"

    local action
    action=$(notify-send -a "NetworkManager" \
                         -i network-wireless-signal-good-symbolic \
                         -u normal \
                         -A "login=Iniciar sesión" \
                         "Inicio de sesión requerido" \
                         "La red '${ssid}' requiere iniciar sesión para acceder a internet.")

    if [ "$action" = "login" ] || [ "$action" = "0" ]; then
        xdg-open "$login_url" >/dev/null 2>&1 &
    fi
}

handle_portal_detection() {
    local ssid
    ssid=$(get_active_ssid)
    local login_url
    login_url=$(get_portal_login_url)

    if [ "$NOTIFIED_SSID" != "$ssid" ]; then
        NOTIFIED_SSID="$ssid"
        # Ejecutar en segundo plano para no bloquear el monitor
        send_portal_notification "$ssid" "$login_url" &
    fi
}

run_daemon() {
    echo "Iniciando monitor de portal cautivo..."
    
    # Comprobación inicial al arrancar
    local initial_state
    initial_state=$(check_connectivity_state)
    if [ "$initial_state" = "portal" ]; then
        handle_portal_detection
    fi

    # Escuchar eventos de cambio en NetworkManager
    nmcli monitor 2>/dev/null | while read -r line; do
        # Detectar si hay cambios en conectividad o conexión
        if echo "$line" | grep -qE "Connectivity is now 'portal'|in the 'connected' state|connected"; then
            sleep 2 # Pequeño margen para asignación DHCP/enrutamiento
            local state
            state=$(check_connectivity_state)
            if [ "$state" = "portal" ]; then
                handle_portal_detection
            elif [ "$state" = "full" ]; then
                NOTIFIED_SSID=""
            fi
        elif echo "$line" | grep -qE "Connectivity is now 'full'|disconnected"; then
            local current_state
            current_state=$(nmcli networking connectivity check 2>/dev/null)
            if [ "$current_state" = "full" ] || [ "$current_state" = "none" ]; then
                NOTIFIED_SSID=""
            fi
        fi
    done
}

case "$1" in
    daemon)
        run_daemon
        ;;
    check)
        state=$(check_connectivity_state)
        ssid=$(get_active_ssid)
        echo "Estado de conectividad: $state (Red: $ssid)"
        if [ "$state" = "portal" ]; then
            echo "Portal cautivo detectado. Enviando notificación..."
            url=$(get_portal_login_url)
            send_portal_notification "$ssid" "$url"
        fi
        ;;
    test)
        echo "Simulando detección de portal cautivo para la red 'UCM-WiFi'..."
        url=$(get_portal_login_url)
        send_portal_notification "UCM-WiFi" "$url"
        ;;
    open)
        url=$(get_portal_login_url)
        echo "Abriendo URL de portal ($url) en el navegador por defecto..."
        xdg-open "$url" >/dev/null 2>&1 &
        ;;
    *)
        echo "Uso: $0 {daemon|check|test|open}"
        exit 1
        ;;
esac
