# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

plugins=(git)

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


# mise puts the right node/go/pnpm on PATH per directory, reading each project's
# mise.toml on cd. Nothing is global: outside a project there is no toolchain.
eval "$(mise activate zsh)"

export PATH="/opt/homebrew/opt/curl/bin:$PATH"

alias rm="echo do not directly delete any type of file! USE trash"

alias sublime='open -a "Sublime Text"'

# Root of the cold-backup archive tree. Override per-invocation to test
# against a scratch location: `COLD_BACKUP_REMOTE=/tmp/x cold-backup-prune`.
COLD_BACKUP_REMOTE="${COLD_BACKUP_REMOTE:-dropbox kamer:Backups}"

# Cold backup — zip the repo you are standing in and stream it to Dropbox via
# rclone. No automatic trigger — run it yourself whenever you want a snapshot:
# `cold-backup`. Uploads to "dropbox kamer:Backups/<repo>/<repo>-<ts>.zip",
# where <repo> is the basename of the repository root, not of $PWD — running
# from a subdirectory backs up the whole repo, not just that subtree.
#
# File list comes from `git ls-files --cached --others --exclude-standard` —
# tracked + untracked-but-not-ignored files, per each project's own
# .gitignore. No hand-maintained per-folder exclude list to keep in sync
# across projects. Requires running inside a git repo.
cold-backup() {
	setopt localoptions pipefail
	command -v rclone >/dev/null 2>&1 || { echo "[cold-backup] rclone not found in PATH" >&2; return 1; }
	command -v zip    >/dev/null 2>&1 || { echo "[cold-backup] zip not found in PATH" >&2; return 1; }

	local root name stamp dir target part files nfiles origin
	root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "[cold-backup] not inside a git repo" >&2; return 1; }
	name=$(basename "$root")
	stamp=$(date -u +%Y-%m-%dT%H-%M-%SZ)
	dir="${COLD_BACKUP_REMOTE}/${name}"
	target="${dir}/${name}-${stamp}.zip"
	part="${target}.part"

	# Two repos can share a basename (~/Code/api and ~/work/api), which would
	# silently merge their archives into one folder — and leave cold-backup-prune
	# deleting the other project's backups. The folder records the repo root that
	# owns it; a mismatch is a hard stop rather than a silent merge.
	origin=$(rclone cat "${dir}/.origin" 2>/dev/null)
	if [ -n "$origin" ] && [ "$origin" != "$root" ]; then
		echo "[cold-backup] ${dir} belongs to ${origin}, not ${root}" >&2
		echo "[cold-backup] point COLD_BACKUP_REMOTE elsewhere, or reset with: rclone deletefile \"${dir}/.origin\"" >&2
		return 1
	fi

	# Belt-and-suspenders on top of .gitignore: strip secret-shaped paths
	# even if a project's .gitignore doesn't already cover them.
	files=$(git -C "$root" ls-files --cached --others --exclude-standard \
		| grep -Ev '(^|/)\.env(\.|$)' \
		| grep -Ev '\.(pem|key)$' \
		| grep -Ev '(^|/)id_(rsa|ed25519)' \
		| grep -Ev '(^|/)\.(aws|ssh)/' \
		| grep -Ev '(^|/)[^/]*(credentials|secrets)[^/]*\.json$')
	if [ -z "$files" ]; then
		echo "[cold-backup] no files to back up, aborting" >&2
		return 0
	fi
	nfiles=$(printf '%s\n' "$files" | awk 'END{print NR}')

	echo "[cold-backup] zipping ${nfiles} files from ${root} -> ${target}"
	# Upload under a .part name and rename only once zip exited clean: rclone
	# rcat cannot tell a dead producer from a clean EOF and exits 0 either way,
	# so a truncated archive would otherwise land under a real name and count as
	# one of the newest that prune keeps. .part never matches prune's *.zip.
	printf '%s\n' "$files" | (cd "$root" && zip -q -X - -@) | rclone rcat "$part" || {
		echo "[cold-backup] upload failed, discarding ${part}" >&2
		rclone deletefile "$part" >/dev/null 2>&1
		return 1
	}
	rclone moveto "$part" "$target" || { echo "[cold-backup] could not finalize ${target}" >&2; return 1; }
	[ -n "$origin" ] || printf '%s' "$root" | rclone rcat "${dir}/.origin" >/dev/null 2>&1
	echo "[cold-backup] uploaded -> ${target}"
}

# Prune old cold-backup archives for the current repo: keep the newest N
# (first argument, default 10) and delete the rest. Never deletes without
# showing the list and asking first; anything that is not a *.zip in that
# folder is out of scope.
cold-backup-prune() {
	setopt localoptions pipefail
	command -v rclone >/dev/null 2>&1 || { echo "[cold-backup-prune] rclone not found in PATH" >&2; return 1; }

	local root name dir listing all old parts reply f keep=${1:-10} ntotal nold nfail=0 origin
	root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "[cold-backup-prune] not inside a git repo" >&2; return 1; }
	name=$(basename "$root")
	dir="${COLD_BACKUP_REMOTE}/${name}"

	# Refuse to prune a folder another repo of the same basename owns; see the
	# .origin note in cold-backup.
	origin=$(rclone cat "${dir}/.origin" 2>/dev/null)
	if [ -n "$origin" ] && [ "$origin" != "$root" ]; then
		echo "[cold-backup-prune] ${dir} belongs to ${origin}, not ${root} — refusing to prune" >&2
		return 1
	fi

	# rclone exit 3 = directory not found, i.e. this project was never backed
	# up. That is not an error; anything else (auth, network, config) is.
	listing=$(rclone lsf "$dir" --files-only 2>/dev/null)
	case $? in
		0) ;;
		3) echo "[cold-backup-prune] no backups yet for ${name}"; return 0 ;;
		*) echo "[cold-backup-prune] cannot list ${dir}" >&2; return 1 ;;
	esac
	# One listing, filtered locally: *.zip is what we prune, *.zip.part is an
	# upload that died before it could be renamed.
	parts=$(printf '%s\n' "$listing" | grep -E '\.zip\.part$')
	# Sorted by name, which for these archives is sorted by UTC timestamp.
	all=$(printf '%s\n' "$listing" | grep -E '\.zip$' | sort)
	if [ -z "$all" ]; then
		echo "[cold-backup-prune] no backups found in ${dir}"
		[ -z "$parts" ] || printf '[cold-backup-prune] stale partial upload: %s\n' ${(f)parts} >&2
		return 0
	fi

	ntotal=$(printf '%s\n' "$all" | awk 'END{print NR}')
	if [ "$ntotal" -le "$keep" ]; then
		echo "[cold-backup-prune] ${ntotal} backup(s) in ${dir}, nothing to prune (keeping ${keep})"
		[ -z "$parts" ] || printf '[cold-backup-prune] stale partial upload: %s\n' ${(f)parts} >&2
		return 0
	fi
	nold=$((ntotal - keep))
	old=$(printf '%s\n' "$all" | head -n "$nold")

	echo "[cold-backup-prune] ${dir}"
	printf '  delete: %s\n' ${(f)old}
	echo "[cold-backup-prune] ${ntotal} archives: keeping ${keep} newest, deleting ${nold}"
	[ -z "$parts" ] || printf '[cold-backup-prune] stale partial upload (left alone): %s\n' ${(f)parts}
	[ -n "$origin" ] || echo "[cold-backup-prune] note: ${dir} has no .origin marker, ownership unverified"
	read -r "reply?[cold-backup-prune] proceed? (y/N) "
	case "$reply" in
		y|Y) ;;
		*) echo "[cold-backup-prune] aborted, nothing deleted"; return 0 ;;
	esac

	while IFS= read -r f; do
		[ -n "$f" ] || continue
		rclone deletefile "${dir}/${f}" || { echo "[cold-backup-prune] failed to delete ${f}" >&2; nfail=$((nfail + 1)); }
	done <<< "$old"

	if [ "$nfail" -gt 0 ]; then
		echo "[cold-backup-prune] deleted $((nold - nfail))/${nold}, ${nfail} failed" >&2
		return 1
	fi
	echo "[cold-backup-prune] deleted ${nold}, ${keep} newest kept"
}


# Postgres runs in Docker; this is only the client (psql, pg_dump), and libpq
# is keg-only so brew does not link it into the prefix.
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# corepack — keep it disabled even when it ships with the installed node
alias corepack='echo "corepack is disabled on purpose. Use pnpm directly." >&2; false'


source $ZSH/oh-my-zsh.sh
eval "$(rbenv init - zsh)"


# Claude Code
export PATH="$HOME/.local/bin:$PATH"

# --- zsh plugins ---
# These two must stay last: syntax-highlighting wraps the widgets defined
# before it, so loading it ahead of oh-my-zsh breaks the highlighting.
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
