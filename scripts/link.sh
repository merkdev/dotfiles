#!/usr/bin/env bash
# Repodaki konfigleri ev dizinine symlink'ler.
# Var olan gercek dosyalar silinmez, yanina .bak-<zaman> olarak tasinir.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY="${DRY_RUN:-0}"
n_linked=0 n_skipped=0 n_backed=0

link() {
	local src="$REPO/$1" dst="$2"

	if [ ! -e "$src" ]; then
		echo "  ! kaynak yok, atlandi: $1" >&2
		return 0
	fi

	# Zaten bize bakan bir symlink mi?
	if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
		printf '  = %s\n' "${dst/#$HOME/~}"
		n_skipped=$((n_skipped + 1))
		return 0
	fi

	if [ "$DRY" = "1" ]; then
		printf '  + %s -> %s\n' "${dst/#$HOME/~}" "$1"
		n_linked=$((n_linked + 1))
		return 0
	fi

	mkdir -p "$(dirname "$dst")"

	# Gercek dosya/dizin varsa once yedekle.
	if [ -e "$dst" ] && [ ! -L "$dst" ]; then
		mv "$dst" "${dst}.bak-${STAMP}"
		printf '  ~ yedek: %s\n' "${dst/#$HOME/~}.bak-${STAMP}"
		n_backed=$((n_backed + 1))
	elif [ -L "$dst" ]; then
		rm -f "$dst"
	fi

	ln -s "$src" "$dst"
	printf '  + %s -> %s\n' "${dst/#$HOME/~}" "$1"
	n_linked=$((n_linked + 1))
}

echo "dotfiles: $REPO"
[ "$DRY" = "1" ] && echo "(DRY_RUN — hicbir sey degismiyor)"

link home/.zshrc                "$HOME/.zshrc"
link home/.zshenv               "$HOME/.zshenv"
link home/.zprofile             "$HOME/.zprofile"
link home/.gitconfig            "$HOME/.gitconfig"
link home/.gitignore_global     "$HOME/.gitignore_global"

link warp/settings.toml         "$HOME/.warp/settings.toml"
link warp/themes                "$HOME/.warp/themes"
link warp/tab_configs           "$HOME/.warp/tab_configs"

link sublime/Preferences.sublime-settings \
	"$HOME/Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings"

printf '\n%d baglandi, %d zaten baglıydi, %d yedeklendi\n' "$n_linked" "$n_skipped" "$n_backed"
