#!/usr/bin/env bash
set -euo pipefail

COMFY="${COMFY:-}"
if [[ -z "$COMFY" ]]; then
  for candidate in /workspace/ComfyUI /root/ComfyUI /opt/ComfyUI; do
    [[ -d "$candidate" ]] && COMFY="$candidate" && break
  done
fi
[[ -n "$COMFY" ]] || { echo "ComfyUI not found."; exit 1; }

files=(
  "$COMFY/models/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors"
  "$COMFY/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"
  "$COMFY/models/vae/qwen_image_vae.safetensors"
  "$COMFY/models/loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors"
  "$COMFY/user/default/workflows/qwen2511-workflow.json"
)

bad=0
for f in "${files[@]}"; do
  if [[ -s "$f" ]]; then
    ls -lh "$f"
  else
    echo "MISSING: $f"
    bad=1
  fi
done

exit "$bad"
