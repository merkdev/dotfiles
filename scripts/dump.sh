#!/usr/bin/env bash
# Regenerate the Brewfile, keeping hand-added entries: manual and Mac App Store
# installs are invisible to brew, so a plain `brew bundle dump` drops them.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILE="$REPO/Brewfile"
TMP="$(mktemp -t Brewfile.XXXXXX)"
trap 'rm -f "$TMP" "$TMP.old" "$TMP.kept"' EXIT

# Snapshot the current file: the redirect at the end truncates $FILE, so
# everything that reads the old content must read this copy instead.
if [ -f "$FILE" ]; then
	cp "$FILE" "$TMP.old"
else
	: > "$TMP.old"
fi

brew bundle dump --file="$TMP" --force

# Node ships corepack and npm inside its own lib, so `npm ls -g` reports them
# as globals and the dump would tell a clean machine to install them.
grep -vE '^npm "(corepack|npm)"$' "$TMP" > "$TMP.npm" && mv "$TMP.npm" "$TMP"

ENTRY='^(brew|cask|tap|go|uv|cargo|npm|vscode|mas) '

# Entries the old file had that the fresh dump does not know about.
comm -23 \
	<(grep -E "$ENTRY" "$TMP.old" | sort -u) \
	<(grep -E "$ENTRY" "$TMP"     | sort -u) \
	> "$TMP.kept"

{
	echo "# Brewfile — everything installed on this machine."
	echo "# Regenerate with: make dump"
	echo "# Install with:    make brew   (or: brew bundle)"
	echo
	cat "$TMP"

	if [ -s "$TMP.kept" ]; then
		echo
		echo "# Installed by hand or from the Mac App Store, so brew does not see them"
		echo "# and cannot regenerate these lines. Kept by scripts/dump.sh."
		echo
		# Carry each entry over with the comment above it. The blank-line reset
		# stops the section header being read as the first entry's comment.
		awk 'NR == FNR { want[$0] = 1; next }
		     /^[[:space:]]*$/ { buf = ""; next }
		     /^#/ { buf = buf $0 "\n"; next }
		     $0 in want { printf "%s%s\n", buf, $0 }
		     { buf = "" }' "$TMP.kept" "$TMP.old"
	fi
} > "$FILE"

n_kept=$(grep -cE "$ENTRY" "$TMP.kept" || true)
n_total=$(grep -cE "$ENTRY" "$FILE")
printf '%d entries, %d of them preserved from the previous file\n' "$n_total" "$n_kept"
