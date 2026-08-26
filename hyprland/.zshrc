# Path to your Oh My Zsh installation.
export ZSH="$HOME/.config/ohmyzsh"
export PATH="$HOME/go/bin:$PATH"

# Themes
ZSH_THEME="robbyrussell"

# Plugins
plugins=(git)

# Oh My ZSH loader
source $ZSH/oh-my-zsh.sh

# Alias
alias ls="exa -l"
alias obsidian-sync='~/dotfiles/hyprland/.config/hypr/scripts/obsidian-sync.sh'
alias ff='fastfetch'

# Funciones
load-env() {
  if [ -f .env ]; then
    source .env
    echo "Variables de entorno cargadas desde .env"
  else
    echo "Error: No se ha encontrado el archivo .env en este directorio."
  fi
}

backup_pkgs() {
    local backup_dir="$HOME/dotfiles/pkgs"
    mkdir -p "$backup_dir"

    # 1. Lista de paquetes de repositorios oficiales (Pacman)
    # -Qn lista paquetes instalados de bases de datos locales
    pacman -Qnq > "$backup_dir/lista_pacman.txt"

    # 2. Lista de paquetes de AUR (vía yay o pacman -Qm)
    # -Qm lista paquetes que no están en los repositorios oficiales
    pacman -Qmq > "$backup_dir/lista_aur.txt"

    # 3. Lista de aplicaciones Flatpak
    # --columns=application solo extrae el ID de la aplicación
    flatpak list --app --columns=application > "$backup_dir/lista_flatpak.txt"

    echo "Respaldo completado en $backup_dir"
}

# Función de yazi 
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Linea para que el laucher de quichshell reconozca los iconos de las APPs de flatpak
export XDG_DATA_DIRS=$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share

# Vontroles escritura por consola
bindkey '^H' backward-kill-word # Ctrl + Retroceso para borrar la palabra hacia atrás
bindkey '^[[3;5~' kill-word # Ctrl + Suprimir para borrar la palabra hacia adelante

# Antigravity



# Created by `pipx` on 2026-06-07 01:33:26
export PATH="$PATH:/home/hypr/.local/bin"


# Added by Antigravity CLI installer
export PATH="/home/hypr/.local/bin:$PATH"
