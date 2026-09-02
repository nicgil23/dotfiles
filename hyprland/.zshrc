# ===== ENVIRONMENT AND PATH =====
export ZSH="$HOME/.config/ohmyzsh"

# Centralized PATH definition (without duplicates)
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

# Icon and Desktop app recognition for QuickShell and other launchers (Flatpak)
export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share"


# ===== OH-MY-ZSH CONFIGURATION =====
ZSH_THEME="robbyrussell"
plugins=(git)

# Load Oh My ZSH if the entry script exists
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
fi


# ===== ALIASES =====
# Use exa/eza for `ls` if available
if command -v exa &>/dev/null; then
    alias ls="eza -l"
elif command -v eza &>/dev/null; then
    alias ls="exa -l"
else
    alias ls="ls -l"
fi

alias obsidian-sync="$HOME/dotfiles/hyprland/.config/hypr/scripts/obsidian-sync.sh"
alias ff="fastfetch"


# ===== KEYBINDINGS =====
bindkey '^H' backward-kill-word # Ctrl + Backspace: delete word backward
bindkey '^[[3;5~' kill-word     # Ctrl + Delete: delete word forward


# ===== FUNCTIONS =====

# Load environment variables from a .env file if present in current directory
load-env() {
    if [ -f .env ]; then
        source .env
        echo "Environment variables loaded from .env"
    else
        echo "Error: .env file not found in this directory." >&2
        return 1
    fi
}

# Package backup function (Pacman, AUR, Flatpak)
backup_pkgs() {
    local backup_dir="$HOME/dotfiles/pkgs"
    mkdir -p "$backup_dir" || return 1

    # Official repository package list (Pacman)
    pacman -Qnq > "$backup_dir/lista_pacman.txt" 2>/dev/null

    # AUR package list
    pacman -Qmq > "$backup_dir/lista_aur.txt" 2>/dev/null

    # Flatpak application list
    if command -v flatpak &>/dev/null; then
        flatpak list --app --columns=application > "$backup_dir/lista_flatpak.txt"
    fi

    echo "Backup completed in $backup_dir"
}

# Yazi file manager wrapper (changes directory on exit)
y() {
    local tmp
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || return 1
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# Custom workspace layout for AutoTask project
clubed() {
    local autotask_dir="$HOME/workspace/AutoTask"
    local target_dir="$HOME/workspace/AutoTask/frontend"
    local chrome_cmd="google-chrome-stable"
    
    command -v google-chrome &>/dev/null && chrome_cmd="google-chrome"

    kitty --directory "$autotask_dir" &>/dev/null &

    if command -v hyprctl &>/dev/null; then
        hyprctl dispatch exec "[workspace 3] kitty --directory $autotask_dir agy" &>/dev/null
        hyprctl dispatch exec "[workspace 5] $chrome_cmd http://localhost:3000/" &>/dev/null
    else
        kitty --directory "$autotask_dir" agy &>/dev/null &
        "$chrome_cmd" http://localhost:3000/ &>/dev/null &
    fi

    cd "$target_dir" && npm run dev
}
