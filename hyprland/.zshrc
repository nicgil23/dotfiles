# Path to your Oh My Zsh installation.
export ZSH="$HOME/.config/ohmyzsh"

# Themes
ZSH_THEME="robbyrussell"

# Oh My ZSH loader
source $ZSH/oh-my-zsh.sh

# Plugins
plugins=(git)

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
    local backup_dir="$HOME/dotfiles/"
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

aura() {
    kitty cava &
    kitty cmatrix &
    kitty pipes-rs &
    btop
}
