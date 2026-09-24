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

# Prefer ComfyUI's own venv when available, so custom node requirements land in the right Python.
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
exec > >(tee -a "$LOG_FILE") 2>&1

echo "ComfyUI: $COMFY"
echo "Python:  $PYTHON"
echo "Log:     $LOG_FILE"

fatal=0

log "Preparing downloader dependencies"
if ! "$PYTHON" -m pip install -q -U huggingface_hub hf_xet; then
  err "Could not install huggingface_hub/hf_xet. This is required."
  fatal=1
fi

export HF_HUB_DISABLE_TELEMETRY=1
export HF_XET_HIGH_PERFORMANCE=1

if [[ "$fatal" -eq 0 ]]; then
  log "Preflight source check (warnings do not stop installation)"
  "$PYTHON" "$ROOT/scripts/check_sources.py" \
    --models "$ROOT/manifests/models.json" \
    --custom-nodes "$ROOT/manifests/custom-nodes.json" || true

  log "Installing core models and LoRAs"
  if ! "$PYTHON" "$ROOT/scripts/install_models.py" \
      --manifest "$ROOT/manifests/models.json" \
      --comfy "$COMFY"; then
    err "One or more REQUIRED core models failed. Continuing other installation stages."
    fatal=1
  fi
fi

log "Installing optional advanced custom nodes"
if ! "$PYTHON" "$ROOT/scripts/install_custom_nodes.py" \
    --manifest "$ROOT/manifests/custom-nodes.json" \
    --comfy "$COMFY"; then
  warn "Some required custom-node component failed. Continuing."
  fatal=1
fi

log "Installing workflow library"
if ! "$PYTHON" "$ROOT/scripts/install_workflows.py" \
    --manifest "$ROOT/manifests/workflows.json" \
    --repo-root "$ROOT" \
    --comfy "$COMFY"; then
  err "One or more required workflows failed. Continuing to verification."
  fatal=1
fi

log "Final verification"
if ! "$PYTHON" "$ROOT/scripts/verify_install.py" \
    --models "$ROOT/manifests/models.json" \
    --workflows "$ROOT/manifests/workflows.json" \
    --custom-nodes "$ROOT/manifests/custom-nodes.json" \
    --comfy "$COMFY"; then
  fatal=1
fi

echo
if [[ "$fatal" -eq 0 ]]; then
  ok "Qwen Vast Recovery installation complete."
  echo "Optional warnings may be present above; they do not invalidate the core install."
  echo "Workflows: $COMFY/user/default/workflows/qwen2511"
  echo "Restart ComfyUI if it is currently running."
  exit 0
else
  err "Installation finished, but one or more REQUIRED core components are missing."
  echo "The installer still attempted all other stages. Review: $LOG_FILE"
  exit 1
fi
