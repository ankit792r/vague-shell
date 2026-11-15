#!/bin/bash

# One JSON entry on stdout. With an argument, wl-paste --watch feeds the copy
# on stdin. Without one, this reads the current clipboard itself.

set -o pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
IMAGE_DIR="$STATE_DIR/clipboard-images"
mkdir -p "$IMAGE_DIR"

types=$(timeout 2s wl-paste --list-types 2>/dev/null || true)

if [[ ${CLIPBOARD_STATE:-} == "sensitive" ]] || grep -qx 'x-kde-passwordManagerHint' <<<"$types"; then
  exit 0
fi

emit_text_stdin() {
  python3 -c 'import json,sys
raw = sys.stdin.read()
if raw.strip() == "":
    sys.exit(0)
print(json.dumps({"type": "text", "text": raw}))'
}

emit_image_stdin() {
  local mime="$1"
  local tmp hash file
  tmp=$(mktemp --tmpdir="$IMAGE_DIR" clipboard.XXXXXX) || return 0
  if ! timeout 2s cat >"$tmp" || [[ ! -s $tmp ]]; then
    rm -f "$tmp"
    return 0
  fi
  hash=$(sha256sum "$tmp" | awk '{print $1}')
  file="$IMAGE_DIR/$hash.png"
  if [[ -e $file ]]; then
    rm -f "$tmp"
  else
    mv "$tmp" "$file"
  fi
  python3 -c 'import json,sys; print(json.dumps({"type":"image","mime":sys.argv[1],"path":sys.argv[2],"capturedAt":sys.argv[3]}))' \
    "$mime" "$file" "$(date +'%a %H:%M')"
}

case "${1:-}" in
  text) emit_text_stdin; exit 0 ;;
  image/png) emit_image_stdin "image/png"; exit 0 ;;
esac

if grep -qx 'image/png' <<<"$types"; then
  timeout 2s wl-paste --type image/png 2>/dev/null | emit_image_stdin "image/png"
  exit 0
fi

if grep -q '^text/' <<<"$types" || grep -qx 'UTF8_STRING' <<<"$types" || grep -qx 'STRING' <<<"$types"; then
  timeout 2s wl-paste --type text --no-newline 2>/dev/null | emit_text_stdin
fi
