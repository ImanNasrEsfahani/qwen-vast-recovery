#!/usr/bin/env bash
set -Euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log(){ printf '\n\033[1;36m[%s]\033[0m %s\n' "$(date +'%H:%M:%S')" "$*"; }
ok(){ printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m⚠\033[0m %s\n' "$*"; }
err(){ printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; }

COMFY="${COMFY:-}"
if [[ -z "$COMFY" ]]; then
  for c in /workspace/ComfyUI /root/ComfyUI /opt/ComfyUI; do
    [[ -d "$c" ]] && COMFY="$c" && break
  done
fi
[[ -n "$COMFY" ]] || COMFY="$(find /workspace /root /opt -maxdepth 4 -type d -name ComfyUI 2>/dev/null | head -n1 || true)"
if [[ -z "$COMFY" || ! -d "$COMFY" ]]; then
  err "ComfyUI directory not found. Set COMFY=/path/to/ComfyUI."
  exit 1
fi

if [[ -x "$COMFY/venv/bin/python" ]]; then
  PYTHON="$COMFY/venv/bin/python"
elif [[ -x "$COMFY/.venv/bin/python" ]]; then
  PYTHON="$COMFY/.venv/bin/python"
else
  PYTHON="$(command -v python3 || command -v python || true)"
fi
if [[ -z "$PYTHON" ]]; then
  err "Python not found."
  exit 1
fi

mkdir -p "$COMFY/.qwen2511-install"
LOG_FILE="$COMFY/.qwen2511-install/install-$(date +%Y%m%d-%H%M%S).log"
SELECTION_FILE="$COMFY/.qwen2511-install/hardware-selection.json"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "ComfyUI: $COMFY"
echo "Python:  $PYTHON"
echo "Log:     $LOG_FILE"

log "Checking ComfyUI compatibility"
if ! "$PYTHON" "$ROOT/scripts/check_comfy_compat.py" --comfy "$COMFY"; then
  err "ComfyUI must be updated before installing this pack."
  exit 1
fi

fatal=0

log "Preparing installer dependencies"
if ! "$PYTHON" -m pip install -q -U \
    "huggingface_hub>=1.5,<2.0" \
    hf_xet \
    "setuptools==81.0.0"; then
  err "Could not prepare installer dependencies."
  fatal=1
fi

export HF_HUB_DISABLE_TELEMETRY=1
export HF_XET_HIGH_PERFORMANCE=1

if [[ "$fatal" -eq 0 ]]; then
  log "Detecting GPU, VRAM, CUDA and selecting runtime profile"
  rm -f "$SELECTION_FILE"
  if ! "$PYTHON" "$ROOT/scripts/detect_hardware.py" --output "$SELECTION_FILE"; then
    err "Hardware detection failed. Installation cannot safely continue."
    fatal=1
  fi
fi

if [[ "$fatal" -eq 0 ]]; then
  log "Preflight source check (warnings do not stop installation)"
  "$PYTHON" "$ROOT/scripts/check_sources.py" \
    --models "$ROOT/manifests/models.json" \
    --custom-nodes "$ROOT/manifests/custom-nodes.json" \
    --selection "$SELECTION_FILE" || true

  log "Installing hardware-selected core model and LoRAs"
  if ! "$PYTHON" "$ROOT/scripts/install_models.py" \
      --manifest "$ROOT/manifests/models.json" \
      --comfy "$COMFY" \
      --selection "$SELECTION_FILE"; then
    err "One or more REQUIRED core models failed. Continuing other installation stages."
    fatal=1
  fi
fi

if [[ -f "$SELECTION_FILE" ]]; then
  log "Installing required/optional custom nodes"
  if ! "$PYTHON" "$ROOT/scripts/install_custom_nodes.py" \
      --manifest "$ROOT/manifests/custom-nodes.json" \
      --comfy "$COMFY" \
      --selection "$SELECTION_FILE"; then
    warn "Some required custom-node component failed. Continuing."
    fatal=1
  fi

  log "Verifying required custom nodes can really import/register"
  if ! "$PYTHON" "$ROOT/scripts/verify_custom_nodes_runtime.py" \
      --manifest "$ROOT/manifests/custom-nodes.json" \
      --comfy "$COMFY" \
      --selection "$SELECTION_FILE"; then
    err "Required custom-node runtime verification failed. Workflow installation will continue, but install is incomplete."
    fatal=1
  fi
else
  warn "Skipping hardware-sensitive custom-node setup because hardware detection did not complete."
fi

log "Installing workflow library"
if ! "$PYTHON" "$ROOT/scripts/install_workflows.py" \
    --manifest "$ROOT/manifests/workflows.json" \
    --repo-root "$ROOT" \
    --comfy "$COMFY" \
    --selection "$SELECTION_FILE"; then
  err "One or more required workflows failed. Continuing to verification."
  fatal=1
fi

log "Final verification"
if ! "$PYTHON" "$ROOT/scripts/verify_install.py" \
    --models "$ROOT/manifests/models.json" \
    --workflows "$ROOT/manifests/workflows.json" \
    --custom-nodes "$ROOT/manifests/custom-nodes.json" \
    --comfy "$COMFY" \
    --selection "$SELECTION_FILE"; then
  fatal=1
fi

echo
if [[ "$fatal" -eq 0 ]]; then
  ok "Qwen Vast Recovery installation complete."
  echo "Hardware selection: $SELECTION_FILE"
  echo "Workflows: $COMFY/user/default/workflows/qwen2511"
  echo "Restart ComfyUI if it is currently running."
  exit 0
else
  err "Installation finished, but one or more REQUIRED core components are missing."
  echo "The installer still attempted all other stages. Review: $LOG_FILE"
  exit 1
fi
