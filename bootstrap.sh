#!/usr/bin/env bash
set -Eeuo pipefail

REPO_RAW="https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main"

WORKFLOWS=(
  "qwen2511-simple.json"
  "qwen2511-custom-lora.json"
  "qwen2511-multi-image-lora.json"
)

log()  { printf '\n\033[1;36m[%s]\033[0m %s\n' "$(date +'%H:%M:%S')" "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

trap 'echo; echo "Installer stopped at line $LINENO. Re-run the same command; completed model downloads will be skipped."' ERR

log "Qwen Image Edit 2511 — Vast.ai bootstrap v2"

COMFY="${COMFY:-}"
if [[ -z "$COMFY" ]]; then
  for candidate in /workspace/ComfyUI /root/ComfyUI /opt/ComfyUI; do
    if [[ -d "$candidate" ]]; then COMFY="$candidate"; break; fi
  done
fi
if [[ -z "$COMFY" ]]; then
  COMFY="$(find /workspace /root /opt -maxdepth 4 -type d -name ComfyUI 2>/dev/null | head -n1 || true)"
fi
[[ -n "$COMFY" && -d "$COMFY" ]] || die "ComfyUI directory not found."

ok "ComfyUI: $COMFY"

mkdir -p \
  "$COMFY/models/diffusion_models" \
  "$COMFY/models/text_encoders" \
  "$COMFY/models/vae" \
  "$COMFY/models/loras" \
  "$COMFY/user/default/workflows" \
  "$COMFY/.qwen2511-downloads"

log "Disk space"
df -h "$COMFY" | tail -n 1

PYTHON="$(command -v python3 || command -v python || true)"
[[ -n "$PYTHON" ]] || die "Python not found."

log "Installing/updating Hugging Face downloader"
"$PYTHON" -m pip install -q -U huggingface_hub hf_xet
export HF_HUB_DISABLE_TELEMETRY=1
export HF_XET_HIGH_PERFORMANCE=1

log "Downloading core Qwen 2511 model files"

COMFY="$COMFY" "$PYTHON" - <<'PY'
from pathlib import Path
import os, shutil
from huggingface_hub import hf_hub_download

root = Path(os.environ["COMFY"])
stage = root / ".qwen2511-downloads"

items = [
    ("Comfy-Org/Qwen-Image-Edit_ComfyUI",
     "split_files/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors",
     root / "models/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors"),
    ("Comfy-Org/HunyuanVideo_1.5_repackaged",
     "split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors",
     root / "models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"),
    ("Comfy-Org/Qwen-Image_ComfyUI",
     "split_files/vae/qwen_image_vae.safetensors",
     root / "models/vae/qwen_image_vae.safetensors"),
    ("lightx2v/Qwen-Image-Edit-2511-Lightning",
     "Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors",
     root / "models/loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors"),
]

for repo, filename, dest in items:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists() and dest.stat().st_size > 10_000_000:
        print(f"✓ Already present: {dest.name} ({dest.stat().st_size/1024**3:.2f} GiB)")
        continue
    if dest.exists():
        dest.unlink()

    print(f"\n↓ {dest.name}")
    downloaded = Path(hf_hub_download(repo_id=repo, filename=filename, local_dir=stage))
    shutil.move(str(downloaded), str(dest))
    print(f"✓ Installed: {dest}")

print("\nCore model installation complete.")
PY

download_file() {
  local url="$1" dest="$2"
  local tmp
  tmp="$(mktemp)"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 --retry-delay 2 "$url" -o "$tmp"
  else
    wget -O "$tmp" "$url"
  fi
  mv "$tmp" "$dest"
}

log "Installing multiple workflows"
for wf in "${WORKFLOWS[@]}"; do
  tmp="$(mktemp)"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 3 --retry-delay 2 "$REPO_RAW/$wf" -o "$tmp"
  else
    wget -q -O "$tmp" "$REPO_RAW/$wf"
  fi
  "$PYTHON" -m json.tool "$tmp" >/dev/null
  mv "$tmp" "$COMFY/user/default/workflows/$wf"
  ok "Installed workflow: $wf"
done

# Backward-compatible alias.
cp -f "$COMFY/user/default/workflows/qwen2511-simple.json" \
      "$COMFY/user/default/workflows/qwen2511-workflow.json"

log "Installing custom LoRA helper"
download_file "$REPO_RAW/install-lora.sh" "$COMFY/install-lora.sh"
chmod +x "$COMFY/install-lora.sh"
ok "Helper installed: $COMFY/install-lora.sh"

log "Trying to restart ComfyUI"
RESTARTED=0
if command -v supervisorctl >/dev/null 2>&1; then
  PROC="$(supervisorctl status 2>/dev/null | awk 'tolower($1) ~ /comfy/ {print $1; exit}' || true)"
  if [[ -n "$PROC" ]]; then
    supervisorctl restart "$PROC" && RESTARTED=1 || true
  fi
fi

if [[ "$RESTARTED" -eq 1 ]]; then
  ok "ComfyUI restarted."
else
  warn "Automatic restart unavailable. Refresh ComfyUI or restart it from the Vast.ai Instance Portal."
fi

echo
echo "=============================================================="
echo " QWEN IMAGE EDIT 2511 — READY"
echo "=============================================================="
echo
echo "Installed workflows:"
printf '  - %s\n' "${WORKFLOWS[@]}"
echo
echo "Custom LoRA downloader:"
echo "  $COMFY/install-lora.sh URL [FILENAME]"
echo
echo "Custom LoRAs belong in:"
echo "  $COMFY/models/loras/"
echo
