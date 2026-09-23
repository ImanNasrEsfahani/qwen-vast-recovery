#!/usr/bin/env bash
set -Eeuo pipefail
[[ $# -ge 1 ]] || { echo "Usage: scripts/install_lora.sh URL [FILENAME]"; exit 1; }

URL="$1"
NAME="${2:-${URL%%\?*}}"
NAME="${NAME##*/}"
[[ "$NAME" == *.safetensors ]] || { echo "ERROR: filename must end in .safetensors"; exit 1; }

COMFY="${COMFY:-}"
if [[ -z "$COMFY" ]]; then
  for c in /workspace/ComfyUI /root/ComfyUI /opt/ComfyUI; do
    [[ -d "$c" ]] && COMFY="$c" && break
  done
fi
[[ -n "$COMFY" ]] || { echo "ERROR: ComfyUI not found. Set COMFY=/path/to/ComfyUI"; exit 1; }

mkdir -p "$COMFY/models/loras"
curl -fL --retry 3 -C - -o "$COMFY/models/loras/$NAME" "$URL"
echo "Installed: $COMFY/models/loras/$NAME"
