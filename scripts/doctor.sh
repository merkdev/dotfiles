#!/usr/bin/env bash
# Beklenen symlink'lerin gercekten repoya bakip bakmadigini dogrular.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bad=0

check() {
	local src="$REPO/$1" dst="$2" pretty="${2/#$HOME/~}"

	if [ ! -L "$dst" ]; then
		if [ -e "$dst" ]; then
			printf '  X %s — symlink degil, gercek dosya\n' "$pretty"
		else
			printf '  X %s — yok\n' "$pretty"
		fi
		bad=$((bad + 1))
	elif [ "$(readlink "$dst")" != "$src" ]; then
		printf '  X %s — baska yere bakiyor: %s\n' "$pretty" "$(readlink "$dst")"
		bad=$((bad + 1))
	else
		printf '  . %s\n' "$pretty"
	fi
}

check home/.zshrc                "$HOME/.zshrc"
check home/.zshenv               "$HOME/.zshenv"
check home/.zprofile             "$HOME/.zprofile"
check home/.gitconfig            "$HOME/.gitconfig"
check home/.gitignore_global     "$HOME/.gitignore_global"
check warp/settings.toml         "$HOME/.warp/settings.toml"
check warp/themes                "$HOME/.warp/themes"
check warp/tab_configs           "$HOME/.warp/tab_configs"
check sublime/Preferences.sublime-settings \
	"$HOME/Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings"

if [ "$bad" -gt 0 ]; then
	printf '\n%d sorun — duzeltmek icin: make link\n' "$bad"
	exit 1
fi
echo
echo "hepsi yerinde"
