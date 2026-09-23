#!/usr/bin/env bash
set -euo pipefail

echo "======================================"
echo " Qwen Image Edit 2511 - Vast.ai Setup "
echo "======================================"

COMFY="${COMFY:-$(find /workspace /root -maxdepth 4 -type d -name ComfyUI 2>/dev/null | head -n1)}"

if [ -z "$COMFY" ]; then
    echo "ERROR: ComfyUI directory not found."
    exit 1
fi

echo "ComfyUI found at: $COMFY"
cd "$COMFY"

mkdir -p \
    models/diffusion_models \
    models/text_encoders \
    models/vae \
    models/loras \
    .hf-downloads

python -m pip install -q -U huggingface_hub hf_xet

python - <<'PY'
from huggingface_hub import hf_hub_download
from pathlib import Path
import shutil

root = Path.cwd()
cache = root / ".hf-downloads"

files = [
    (
        "Comfy-Org/Qwen-Image-Edit_ComfyUI",
        "split_files/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors",
        root / "models/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors"
    ),
    (
        "Comfy-Org/HunyuanVideo_1.5_repackaged",
        "split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors",
        root / "models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"
    ),
    (
        "Comfy-Org/Qwen-Image_ComfyUI",
        "split_files/vae/qwen_image_vae.safetensors",
        root / "models/vae/qwen_image_vae.safetensors"
    ),
    (
        "lightx2v/Qwen-Image-Edit-2511-Lightning",
        "Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors",
        root / "models/loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors"
    ),
]

for repo, filename, destination in files:
    destination.parent.mkdir(parents=True, exist_ok=True)

    if destination.exists():
        print(f"✓ Already exists: {destination.name}")
        continue

    print(f"\n↓ Downloading: {destination.name}")

    downloaded = Path(
        hf_hub_download(
            repo_id=repo,
            filename=filename,
            local_dir=cache
        )
    )

    shutil.move(str(downloaded), str(destination))
    print(f"✓ Installed: {destination}")

print("\n======================================")
print(" ALL QWEN MODELS INSTALLED SUCCESSFULLY")
print("======================================")
PY

echo
echo "Installed models:"
ls -lh models/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors
ls -lh models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors
ls -lh models/vae/qwen_image_vae.safetensors
ls -lh models/loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors

echo
echo "Setup finished."
echo "Restart ComfyUI if models do not appear immediately."
