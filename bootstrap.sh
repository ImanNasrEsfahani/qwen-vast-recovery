#!/usr/bin/env bash
set -Eeuo pipefail

REPO_RAW="https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main"
WORKFLOWS=("qwen2511-simple.json" "qwen2511-custom-lora.json" "qwen2511-multi-image-lora.json")

log(){ printf '\n\033[1;36m[%s]\033[0m %s\n' "$(date +'%H:%M:%S')" "$*"; }
ok(){ printf '\033[1;32m✓\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

COMFY="${COMFY:-}"
if [[ -z "$COMFY" ]]; then
  for c in /workspace/ComfyUI /root/ComfyUI /opt/ComfyUI; do [[ -d "$c" ]] && COMFY="$c" && break; done
fi
[[ -n "$COMFY" ]] || COMFY="$(find /workspace /root /opt -maxdepth 4 -type d -name ComfyUI 2>/dev/null | head -n1 || true)"
[[ -n "$COMFY" && -d "$COMFY" ]] || die "ComfyUI directory not found."

mkdir -p "$COMFY/models/diffusion_models" "$COMFY/models/text_encoders" "$COMFY/models/vae" \
 "$COMFY/models/loras" "$COMFY/user/default/workflows" "$COMFY/.qwen2511-downloads"

PYTHON="$(command -v python3 || command -v python || true)"
[[ -n "$PYTHON" ]] || die "Python not found."
"$PYTHON" -m pip install -q -U huggingface_hub hf_xet
export HF_HUB_DISABLE_TELEMETRY=1 HF_XET_HIGH_PERFORMANCE=1

log "Downloading Qwen core models + all Hugging Face LoRAs"
COMFY="$COMFY" "$PYTHON" - <<'PY'
from pathlib import Path
import os, shutil
from huggingface_hub import hf_hub_download

root=Path(os.environ["COMFY"]); stage=root/".qwen2511-downloads"
items=[
("Comfy-Org/Qwen-Image-Edit_ComfyUI","split_files/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors",root/"models/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors"),
("Comfy-Org/HunyuanVideo_1.5_repackaged","split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors",root/"models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"),
("Comfy-Org/Qwen-Image_ComfyUI","split_files/vae/qwen_image_vae.safetensors",root/"models/vae/qwen_image_vae.safetensors"),
("lightx2v/Qwen-Image-Edit-2511-Lightning","Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors",root/"models/loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors"),
("prithivMLmods/Qwen-Image-Edit-2511-Ultra-Realistic-Portrait","URP_20.safetensors",root/"models/loras/URP_20.safetensors"),
("prithivMLmods/Qwen-Image-Edit-2511-Hyper-Realistic-Portrait","HRP_20.safetensors",root/"models/loras/HRP_20.safetensors"),
("lrzjason/Anything2Real","anything2real_2601_A_final_patched.safetensors",root/"models/loras/anything2real_2601_A_final_patched.safetensors"),
("ScottzillaSystems/qwen-image-edit-plus-nsfw-lora","qwen-image-edit-plus-nsfw-lora.safetensors",root/"models/loras/qwen-image-edit-plus-nsfw-lora.safetensors"),
("prithivMLmods/Qwen-Image-Edit-2511-Unblur-Upscale","Qwen-Image-Edit-Unblur-Upscale_20.safetensors",root/"models/loras/Qwen-Image-Edit-Unblur-Upscale_20.safetensors"),
]
for repo,filename,dest in items:
    if dest.exists() and dest.stat().st_size>1_000_000:
        print("✓",dest.name); continue
    print("↓",filename)
    src=Path(hf_hub_download(repo_id=repo,filename=filename,local_dir=stage))
    dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.move(str(src),str(dest))
    print("✓",dest.name)
PY

log "Downloading SexGod v2 automatically"
SEX="$COMFY/models/loras/SEXGOD_FemaleNudity_QwenEdit_2511_v2.safetensors"
if [[ -s "$SEX" ]] && [[ $(stat -c%s "$SEX") -gt 1000000 ]]; then
  ok "SexGod v2 already present"
else
  URL="https://civitai.com/api/download/models/2689224"
  [[ -n "${CIVITAI_TOKEN:-}" ]] && URL="${URL}?token=${CIVITAI_TOKEN}"
  curl -fL --retry 5 --retry-delay 3 --connect-timeout 30 -C - "$URL" -o "$SEX" || {
    rm -f "$SEX"
    die "SexGod v2 download failed. If Civitai requires authentication, rerun with CIVITAI_TOKEN set."
  }
  [[ $(stat -c%s "$SEX") -gt 1000000 ]] || die "SexGod download returned an invalid/small file."
  ok "Installed SexGod v2"
fi

log "Installing workflows"
for wf in "${WORKFLOWS[@]}"; do
  curl -fsSL --retry 3 "$REPO_RAW/$wf" -o "$COMFY/user/default/workflows/$wf"
  "$PYTHON" -m json.tool "$COMFY/user/default/workflows/$wf" >/dev/null
  ok "$wf"
done
cp -f "$COMFY/user/default/workflows/qwen2511-simple.json" "$COMFY/user/default/workflows/qwen2511-workflow.json"
curl -fsSL "$REPO_RAW/install-lora.sh" -o "$COMFY/install-lora.sh"
chmod +x "$COMFY/install-lora.sh"

echo
echo "INSTALL COMPLETE"
echo "Required/ON: Lightning 4-step"
echo "Installed but BYPASSED/OFF by default:"
echo "  Ultra Portrait / Hyper Portrait / Anything2Real / SexGod v2 / MCNL v1 / Unblur-Upscale 20 / Custom"
