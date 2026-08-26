#!/usr/bin/env bash
# Symlinks the configs in this repo into the home directory.
# An existing real file is never deleted, it is moved aside as .bak-<stamp>.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY="${DRY_RUN:-0}"
n_linked=0 n_skipped=0 n_backed=0

link() {
	local src="$REPO/$1" dst="$2"

	if [ ! -e "$src" ]; then
		echo "  ! no such source, skipped: $1" >&2
		return 0
	fi

	# Already a symlink pointing at us?
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

	# Back up a real file or directory before replacing it.
	if [ -e "$dst" ] && [ ! -L "$dst" ]; then
		mv "$dst" "${dst}.bak-${STAMP}"
		printf '  ~ backed up: %s\n' "${dst/#$HOME/~}.bak-${STAMP}"
		n_backed=$((n_backed + 1))
	elif [ -L "$dst" ]; then
		rm -f "$dst"
	fi

	ln -s "$src" "$dst"
	printf '  + %s -> %s\n' "${dst/#$HOME/~}" "$1"
	n_linked=$((n_linked + 1))
}

echo "dotfiles: $REPO"
[ "$DRY" = "1" ] && echo "(DRY_RUN — nothing is changed)"

link home/.zshrc                "$HOME/.zshrc"
link home/.zprofile             "$HOME/.zprofile"
link home/.gitconfig            "$HOME/.gitconfig"
link home/.gitignore_global     "$HOME/.gitignore_global"

link warp/settings.toml         "$HOME/.warp/settings.toml"
link warp/themes                "$HOME/.warp/themes"
link warp/tab_configs           "$HOME/.warp/tab_configs"

link zed/settings.json           "$HOME/.config/zed/settings.json"
link zed/keymap.json             "$HOME/.config/zed/keymap.json"

link sublime/Preferences.sublime-settings \
	"$HOME/Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings"

# Same script under both names; it decides from $0 which one it is shadowing.
link bin/no-npm                 "$HOME/.local/bin/npm"
link bin/no-npm                 "$HOME/.local/bin/npx"
chmod +x "$REPO/bin/no-npm"

printf '\n%d linked, %d already linked, %d backed up\n' "$n_linked" "$n_skipped" "$n_backed"
