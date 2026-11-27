#!/usr/bin/env bash
# Syncs Helium's Web Store extensions with helium/extensions.txt (dump | install).
# Only the extensions travel, not their data: Tampermonkey scripts need their own backup.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST_FILE="$REPO/helium/extensions.txt"
HELIUM_DATA_DIR="$HOME/Library/Application Support/net.imput.helium"
EXTERNAL_EXTENSIONS_DIR="$HELIUM_DATA_DIR/External Extensions"
WEBSTORE_UPDATE_URL="https://clients2.google.com/service/update2/crx"

# Prints the display name, resolving __MSG_key__ through the default locale.
extension_name() {
	local manifest_dir="$1" raw_name message_key default_locale
	raw_name="$(jq -r '.name' "$manifest_dir/manifest.json")"
	case "$raw_name" in
	__MSG_*__)
		message_key="${raw_name#__MSG_}"
		message_key="${message_key%__}"
		default_locale="$(jq -r '.default_locale // "en"' "$manifest_dir/manifest.json")"
		jq -r --arg key "$message_key" \
			'to_entries[] | select((.key | ascii_downcase) == ($key | ascii_downcase)) | .value.message' \
			"$manifest_dir/_locales/$default_locale/messages.json" 2>/dev/null | head -1
		;;
	*) printf '%s\n' "$raw_name" ;;
	esac
}

dump() {
	local profile_dir extension_dir version_dir extension_id
	local entries_file
	entries_file="$(mktemp -t helium-extensions.XXXXXX)"
	trap 'trash "$entries_file" 2>/dev/null || true' EXIT

	# Unpacked and component extensions are skipped: only Web Store ones can be reinstalled by id.
	for profile_dir in "$HELIUM_DATA_DIR"/Default "$HELIUM_DATA_DIR"/Profile\ *; do
		[ -d "$profile_dir/Extensions" ] || continue
		for extension_dir in "$profile_dir/Extensions"/*/; do
			version_dir="$(find "$extension_dir" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -1)"
			[ -f "$version_dir/manifest.json" ] || continue
			[ "$(jq -r '.update_url // ""' "$version_dir/manifest.json")" = "$WEBSTORE_UPDATE_URL" ] || continue
			extension_id="$(basename "$extension_dir")"
			printf '%s  %s\n' "$extension_id" "$(extension_name "$version_dir")" >> "$entries_file"
		done
	done

	mkdir -p "$(dirname "$LIST_FILE")"
	{
		echo "# Helium extensions from the Chrome Web Store, one id per line (text after it is a label)."
		echo "# Regenerate with: make helium-dump"
		echo "# Install with:    make helium"
		echo
		sort -u -k1,1 "$entries_file"
	} > "$LIST_FILE"
	printf '%d extensions written to %s\n' "$(grep -cvE '^(#|$)' "$LIST_FILE")" "${LIST_FILE#"$REPO"/}"
}

install() {
	local extension_id existing_file
	local -a listed_ids=()

	while read -r extension_id _; do
		case "$extension_id" in '' | \#*) continue ;; esac
		listed_ids+=("$extension_id")
	done < "$LIST_FILE"

	mkdir -p "$EXTERNAL_EXTENSIONS_DIR"
	for extension_id in "${listed_ids[@]}"; do
		printf '{ "external_update_url": "%s" }\n' "$WEBSTORE_UPDATE_URL" \
			> "$EXTERNAL_EXTENSIONS_DIR/$extension_id.json"
	done

	# An entry dropped from the list is removed here, so Helium stops installing it.
	for existing_file in "$EXTERNAL_EXTENSIONS_DIR"/*.json; do
		[ -e "$existing_file" ] || continue
		extension_id="$(basename "$existing_file" .json)"
		if ! printf '%s\n' "${listed_ids[@]}" | grep -qxF "$extension_id"; then
			trash "$existing_file"
			printf '  - %s\n' "$extension_id"
		fi
	done

	printf '%d extensions registered — restart Helium to install them\n' "${#listed_ids[@]}"
}

case "${1:-}" in
dump) dump ;;
install) install ;;
*)
	echo "usage: $(basename "$0") dump|install" >&2
	exit 2
	;;
esac
