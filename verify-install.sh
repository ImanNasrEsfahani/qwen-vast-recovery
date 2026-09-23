#!/usr/bin/env bash
set -e
COMFY="${COMFY:-/workspace/ComfyUI}"
files=(
"models/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors"
"models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"
"models/vae/qwen_image_vae.safetensors"
"models/loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors"
"models/loras/URP_20.safetensors"
"models/loras/HRP_20.safetensors"
"models/loras/anything2real_2601_A_final_patched.safetensors"
"models/loras/SEXGOD_FemaleNudity_QwenEdit_2511_v2.safetensors"
"models/loras/qwen-image-edit-plus-nsfw-lora.safetensors"
"models/loras/Qwen-Image-Edit-Unblur-Upscale_20.safetensors"
)
bad=0
for f in "${files[@]}"; do
 if [[ -s "$COMFY/$f" ]] && [[ $(stat -c%s "$COMFY/$f") -gt 1000000 ]]; then echo "✓ $f"; else echo "✗ $f"; bad=1; fi
done
exit "$bad"
