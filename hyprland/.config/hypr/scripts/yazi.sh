#!/usr/bin/env zsh
# Script que hace que yazi pueda servir también de navegador

local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
yazi "$@" --cwd-file="$tmp"
if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
	cd -- "$cwd"
fi
rm -f -- "$tmp"

# Se ejecuta en zsh
exec zsh
