#!/usr/bin/env bash
set -Eeuo pipefail

REPO_RAW="https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main"
WORKFLOW_NAME="qwen2511-workflow.json"

log()  { printf '\n\033[1;36m[%s]\033[0m %s\n' "$(date +'%H:%M:%S')" "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

trap 'echo; echo "Installer stopped at line $LINENO. Re-run the same command; completed files will be skipped/resumed."' ERR

log "Qwen Image Edit 2511 — Vast.ai bootstrap"

# Find ComfyUI.
COMFY="${COMFY:-}"
if [[ -z "$COMFY" ]]; then
  for candidate in /workspace/ComfyUI /root/ComfyUI /opt/ComfyUI; do
    if [[ -d "$candidate" ]]; then
      COMFY="$candidate"
      break
    fi
  done
fi

if [[ -z "$COMFY" ]]; then
  COMFY="$(find /workspace /root /opt -maxdepth 4 -type d -name ComfyUI 2>/dev/null | head -n1 || true)"
fi

[[ -n "$COMFY" && -d "$COMFY" ]] || die "ComfyUI directory was not found. Start from a Vast.ai ComfyUI template, or set COMFY=/path/to/ComfyUI."

ok "ComfyUI: $COMFY"

mkdir -p \
  "$COMFY/models/diffusion_models" \
  "$COMFY/models/text_encoders" \
  "$COMFY/models/vae" \
  "$COMFY/models/loras" \
  "$COMFY/user/default/workflows" \
  "$COMFY/.qwen2511-downloads"

# Show disk space before downloading.
log "Disk space"
df -h "$COMFY" | tail -n 1

# Python/pip detection.
PYTHON="$(command -v python3 || command -v python || true)"
[[ -n "$PYTHON" ]] || die "Python was not found."

log "Installing/updating Hugging Face downloader"
"$PYTHON" -m pip install -q -U huggingface_hub hf_xet

export HF_HUB_DISABLE_TELEMETRY=1
export HF_XET_HIGH_PERFORMANCE=1

log "Downloading required models directly on the Vast.ai server"

COMFY="$COMFY" "$PYTHON" - <<'PY'
from pathlib import Path
import os
import shutil
from huggingface_hub import hf_hub_download

root = Path(os.environ["COMFY"])
stage = root / ".qwen2511-downloads"

items = [
    (
        "Comfy-Org/Qwen-Image-Edit_ComfyUI",
        "split_files/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors",
        root / "models/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors",
    ),
    (
        "Comfy-Org/HunyuanVideo_1.5_repackaged",
        "split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors",
        root / "models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors",
    ),
    (
        "Comfy-Org/Qwen-Image_ComfyUI",
        "split_files/vae/qwen_image_vae.safetensors",
        root / "models/vae/qwen_image_vae.safetensors",
    ),
    (
        "lightx2v/Qwen-Image-Edit-2511-Lightning",
        "Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors",
        root / "models/loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors",
    ),
]

for repo, filename, dest in items:
    dest.parent.mkdir(parents=True, exist_ok=True)

    # The smallest required model is far larger than 10 MB; this avoids
    # treating a tiny failed/HTML download as a valid model.
    if dest.exists() and dest.stat().st_size > 10_000_000:
        print(f"✓ Already present: {dest.name} ({dest.stat().st_size / 1024**3:.2f} GiB)")
        continue

    if dest.exists():
        print(f"! Removing incomplete file: {dest.name}")
        dest.unlink()

    print(f"\n↓ {dest.name}")
    downloaded = Path(
        hf_hub_download(
            repo_id=repo,
            filename=filename,
            local_dir=stage,
        )
    )

    # Move instead of copy so the staging tree does not keep a second huge copy.
    shutil.move(str(downloaded), str(dest))
    print(f"✓ Installed: {dest}")

print("\nAll model downloads completed.")
PY

log "Installing ComfyUI workflow"
WORKFLOW_DEST="$COMFY/user/default/workflows/$WORKFLOW_NAME"

TMP_WORKFLOW="$(mktemp)"
if command -v curl >/dev/null 2>&1; then
  curl -fL --retry 3 --retry-delay 2 \
    "$REPO_RAW/$WORKFLOW_NAME" \
    -o "$TMP_WORKFLOW"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$TMP_WORKFLOW" "$REPO_RAW/$WORKFLOW_NAME"
else
  die "Neither curl nor wget is installed."
fi

# Validate JSON before replacing the workflow file.
"$PYTHON" -m json.tool "$TMP_WORKFLOW" >/dev/null
mv "$TMP_WORKFLOW" "$WORKFLOW_DEST"
ok "Workflow installed: $WORKFLOW_DEST"

log "Verifying installation"
COMFY="$COMFY" "$PYTHON" - <<'PY'
from pathlib import Path
import os

root = Path(os.environ["COMFY"])
paths = [
    root / "models/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors",
    root / "models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors",
    root / "models/vae/qwen_image_vae.safetensors",
    root / "models/loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors",
    root / "user/default/workflows/qwen2511-workflow.json",
]

failed = False
for p in paths:
    if not p.exists():
        print("✗ MISSING:", p)
        failed = True
    else:
        size = p.stat().st_size
        if p.suffix == ".safetensors":
            print(f"✓ {p.name}: {size/1024**3:.2f} GiB")
        else:
            print(f"✓ {p.name}: {size/1024:.1f} KiB")

if failed:
    raise SystemExit(1)
PY

# Try to restart ComfyUI. Failure here is not fatal because service names vary by template.
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
  warn "Automatic restart was not available. Refresh ComfyUI; if models do not appear, restart ComfyUI from the Vast.ai Instance Portal."
fi

echo
echo "=============================================================="
echo " QWEN IMAGE EDIT 2511 IS READY"
echo "=============================================================="
echo "ComfyUI:   $COMFY"
echo "Workflow:  $WORKFLOW_DEST"
echo
echo "Open ComfyUI -> Workflows and load: $WORKFLOW_NAME"
echo "Upload/select an image, edit the Positive Prompt, then Queue/Run."
echo
