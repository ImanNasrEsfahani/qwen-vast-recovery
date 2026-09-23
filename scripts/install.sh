#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log(){ printf '\n\033[1;36m[%s]\033[0m %s\n' "$(date +'%H:%M:%S')" "$*"; }
ok(){ printf '\033[1;32m✓\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

COMFY="${COMFY:-}"
if [[ -z "$COMFY" ]]; then
  for c in /workspace/ComfyUI /root/ComfyUI /opt/ComfyUI; do
    [[ -d "$c" ]] && COMFY="$c" && break
  done
fi
[[ -n "$COMFY" ]] || COMFY="$(find /workspace /root /opt -maxdepth 4 -type d -name ComfyUI 2>/dev/null | head -n1 || true)"
[[ -n "$COMFY" && -d "$COMFY" ]] || die "ComfyUI directory not found. Set COMFY=/path/to/ComfyUI."

PYTHON="$(command -v python3 || command -v python || true)"
[[ -n "$PYTHON" ]] || die "Python not found."

log "Preparing Python dependencies"
"$PYTHON" -m pip install -q -U huggingface_hub hf_xet

export HF_HUB_DISABLE_TELEMETRY=1
export HF_XET_HIGH_PERFORMANCE=1

log "Installing models and LoRAs"
"$PYTHON" "$ROOT/scripts/install_models.py" \
  --manifest "$ROOT/manifests/models.json" \
  --comfy "$COMFY"

log "Installing advanced custom nodes"
"$PYTHON" "$ROOT/scripts/install_custom_nodes.py" \
  --manifest "$ROOT/manifests/custom-nodes.json" \
  --comfy "$COMFY"

log "Installing workflow library"
"$PYTHON" "$ROOT/scripts/install_workflows.py" \
  --manifest "$ROOT/manifests/workflows.json" \
  --repo-root "$ROOT" \
  --comfy "$COMFY"

log "Verifying installation"
"$PYTHON" "$ROOT/scripts/verify_install.py" \
  --models "$ROOT/manifests/models.json" \
  --workflows "$ROOT/manifests/workflows.json" \
  --custom-nodes "$ROOT/manifests/custom-nodes.json" \
  --comfy "$COMFY"

ok "Qwen Vast Recovery installation complete."
echo "Workflows: $COMFY/user/default/workflows/qwen2511"
echo "Restart ComfyUI if it is currently running."
