#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./install-lora.sh URL [FILENAME]

Examples:
  ./install-lora.sh 'https://huggingface.co/user/repo/resolve/main/my_lora.safetensors'
  ./install-lora.sh 'https://huggingface.co/user/repo/resolve/main/my_lora.safetensors' portrait-style.safetensors

The file is downloaded to:
  ComfyUI/models/loras/

After download, refresh/restart ComfyUI and select the LoRA in the Custom LoRA node.
EOF
}

[[ $# -ge 1 ]] || { usage; exit 1; }

URL="$1"
NAME="${2:-${URL%%\?*}}"
NAME="${NAME##*/}"

[[ "$NAME" == *.safetensors ]] || {
  echo "ERROR: Expected a .safetensors filename. Pass an explicit filename as the second argument."
  exit 1
}

COMFY="${COMFY:-}"
if [[ -z "$COMFY" ]]; then
  for candidate in /workspace/ComfyUI /root/ComfyUI /opt/ComfyUI; do
    [[ -d "$candidate" ]] && COMFY="$candidate" && break
  done
fi
if [[ -z "$COMFY" ]]; then
  COMFY="$(find /workspace /root /opt -maxdepth 4 -type d -name ComfyUI 2>/dev/null | head -n1 || true)"
fi
[[ -n "$COMFY" ]] || { echo "ERROR: ComfyUI not found."; exit 1; }

DEST="$COMFY/models/loras/$NAME"
mkdir -p "$(dirname "$DEST")"

echo "Downloading:"
echo "  $URL"
echo "To:"
echo "  $DEST"

if command -v curl >/dev/null 2>&1; then
  curl -fL --retry 3 --retry-delay 2 -C - -o "$DEST" "$URL"
elif command -v wget >/dev/null 2>&1; then
  wget -c -O "$DEST" "$URL"
else
  echo "ERROR: curl/wget not found."
  exit 1
fi

echo
ls -lh "$DEST"
echo
echo "Done. Refresh/restart ComfyUI, then select '$NAME' in the Custom LoRA node."
