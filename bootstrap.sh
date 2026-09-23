#!/usr/bin/env bash

set -euo pipefail

echo "=========================================="
echo " Qwen Image Edit 2511 - Auto Installer"
echo "=========================================="

# -------------------------------
# Find ComfyUI
# -------------------------------

if [ -d "/workspace/ComfyUI" ]; then
    COMFY="/workspace/ComfyUI"
elif [ -d "/root/ComfyUI" ]; then
    COMFY="/root/ComfyUI"
else
    COMFY=$(find /workspace /root -maxdepth 4 \
        -type d -name "ComfyUI" 2>/dev/null | head -n 1)
fi

if [ -z "${COMFY:-}" ]; then
    echo "ERROR: ComfyUI directory not found."
    exit 1
fi

echo
echo "ComfyUI found:"
echo "$COMFY"
echo

# -------------------------------
# Create directories
# -------------------------------

mkdir -p \
    "$COMFY/models/diffusion_models" \
    "$COMFY/models/text_encoders" \
    "$COMFY/models/vae" \
    "$COMFY/models/loras" \
    "$COMFY/user/default/workflows"

# -------------------------------
# Download helper
# -------------------------------

download() {

    URL="$1"
    DEST="$2"

    if [ -s "$DEST" ]; then
        echo "✓ Already exists:"
        echo "  $(basename "$DEST")"
        return
    fi

    echo
    echo "↓ Downloading:"
    echo "  $(basename "$DEST")"

    wget \
        --continue \
        --show-progress \
        -O "$DEST" \
        "$URL"

    echo "✓ Finished:"
    echo "  $(basename "$DEST")"
}

# -------------------------------
# Qwen Diffusion Model
# -------------------------------

download \
"https://huggingface.co/Comfy-Org/Qwen-Image-Edit_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors" \
"$COMFY/models/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors"

# -------------------------------
# Qwen Text Encoder
# -------------------------------

download \
"https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors" \
"$COMFY/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"

# -------------------------------
# Qwen VAE
# -------------------------------

download \
"https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors" \
"$COMFY/models/vae/qwen_image_vae.safetensors"

# -------------------------------
# Lightning LoRA
# -------------------------------

download \
"https://huggingface.co/lightx2v/Qwen-Image-Edit-2511-Lightning/resolve/main/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors" \
"$COMFY/models/loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors"

echo
echo "=========================================="
echo " MODEL DOWNLOAD COMPLETE"
echo "=========================================="

# -------------------------------
# Workflow
# -------------------------------

WORKFLOW_URL="https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main/qwen2511-workflow.json"

echo
echo "Downloading workflow..."

wget -q \
    -O "$COMFY/user/default/workflows/qwen2511-workflow.json" \
    "$WORKFLOW_URL"

echo "✓ Workflow installed."

# -------------------------------
# Show installed files
# -------------------------------

echo
echo "Installed files:"
echo

ls -lh \
"$COMFY/models/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors" \
"$COMFY/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors" \
"$COMFY/models/vae/qwen_image_vae.safetensors" \
"$COMFY/models/loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors"

echo

# -------------------------------
# Restart ComfyUI if Supervisor
# is available
# -------------------------------

if command -v supervisorctl >/dev/null 2>&1; then

    PROC=$(supervisorctl status 2>/dev/null \
        | awk 'tolower($1) ~ /comfy/ {print $1; exit}')

    if [ -n "${PROC:-}" ]; then
        echo "Restarting ComfyUI..."
        supervisorctl restart "$PROC" || true
    fi

fi

echo
echo "=========================================="
echo " QWEN 2511 IS READY"
echo "=========================================="
echo
echo "Workflow:"
echo "$COMFY/user/default/workflows/qwen2511-workflow.json"
echo
echo "Open ComfyUI and load qwen2511-workflow."