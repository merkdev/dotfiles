#!/usr/bin/env bash
# Verifies that every expected symlink really points into this repo.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bad=0

check() {
	local src="$REPO/$1" dst="$2" pretty="${2/#$HOME/~}"

	if [ ! -L "$dst" ]; then
		if [ -e "$dst" ]; then
			printf '  X %s — not a symlink, a real file\n' "$pretty"
		else
			printf '  X %s — missing\n' "$pretty"
		fi
		bad=$((bad + 1))
	elif [ "$(readlink "$dst")" != "$src" ]; then
		printf '  X %s — points elsewhere: %s\n' "$pretty" "$(readlink "$dst")"
		bad=$((bad + 1))
	else
		printf '  . %s\n' "$pretty"
	fi
}

check home/.zshrc                "$HOME/.zshrc"
check home/.zprofile             "$HOME/.zprofile"
check home/.gitconfig            "$HOME/.gitconfig"
check home/.gitignore_global     "$HOME/.gitignore_global"
check warp/settings.toml         "$HOME/.warp/settings.toml"
check warp/themes                "$HOME/.warp/themes"
check warp/tab_configs           "$HOME/.warp/tab_configs"
check mise/config.toml           "$HOME/.config/mise/config.toml"
check zed/settings.json           "$HOME/.config/zed/settings.json"
check zed/keymap.json             "$HOME/.config/zed/keymap.json"

check sublime/Preferences.sublime-settings \
	"$HOME/Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings"

if [ "$bad" -gt 0 ]; then
	printf '\n%d problem(s) — fix with: make link\n' "$bad"
	exit 1
fi
echo
echo "all in place"
