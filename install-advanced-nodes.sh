#!/usr/bin/env bash
set -Eeuo pipefail

COMFY="${COMFY:-}"
if [[ -z "$COMFY" ]]; then
  for c in /workspace/ComfyUI /root/ComfyUI /opt/ComfyUI; do
    [[ -d "$c" ]] && COMFY="$c" && break
  done
fi
[[ -n "$COMFY" && -d "$COMFY" ]] || { echo "ERROR: ComfyUI directory not found"; exit 1; }

cd "$COMFY"
mkdir -p custom_nodes

clone_or_pull() {
  local url="$1"
  local dir="$2"
  if [[ -d "$dir/.git" ]]; then
    echo "Updating $dir"
    git -C "$dir" pull --ff-only || true
  else
    echo "Cloning $dir"
    git clone "$url" "$dir"
  fi
}

clone_or_pull "https://github.com/Fannovel16/comfyui_controlnet_aux.git" "custom_nodes/comfyui_controlnet_aux"
clone_or_pull "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git" "custom_nodes/ComfyUI-Impact-Pack"
clone_or_pull "https://github.com/scraed/LanPaint.git" "custom_nodes/LanPaint"

echo
echo "Advanced custom nodes installed/updated. Restart ComfyUI."
