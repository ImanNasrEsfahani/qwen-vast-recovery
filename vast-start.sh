#!/usr/bin/env bash
set -Eeuo pipefail

REPO="ImanNasrEsfahani/qwen-vast-recovery"
BRANCH="${QVR_BRANCH:-main}"
QVR_VERSION="8.1.0"

log(){ printf '\n\033[1;36m[QVR Vast Start]\033[0m %s\n' "$*"; }
ok(){ printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m⚠\033[0m %s\n' "$*"; }
err(){ printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; }

# /workspace normally persists across restarts on a Vast instance.
if [[ -d /workspace && -w /workspace ]]; then
  STATE_DIR="${QVR_STATE_DIR:-/workspace}"
else
  STATE_DIR="${QVR_STATE_DIR:-$HOME}"
fi
MARKER="$STATE_DIR/.qvr-version"
FAILED_MARKER="$STATE_DIR/.qvr-install-failed"

start_entrypoint(){
  local ep=""

  if [[ -n "${QVR_ENTRYPOINT:-}" ]]; then
    ep="$QVR_ENTRYPOINT"
  elif command -v entrypoint.sh >/dev/null 2>&1; then
    ep="$(command -v entrypoint.sh)"
  else
    for candidate in /entrypoint.sh /usr/local/bin/entrypoint.sh /workspace/entrypoint.sh; do
      if [[ -x "$candidate" ]]; then ep="$candidate"; break; fi
    done
  fi

  if [[ -z "$ep" || ! -x "$ep" ]]; then
    err "Could not find an executable Vast template entrypoint.sh."
    err "Set QVR_ENTRYPOINT=/full/path/to/entrypoint.sh if your template uses a custom path."
    exit 127
  fi

  log "Starting template entrypoint: $ep"
  exec "$ep"
}

mkdir -p "$STATE_DIR"

if [[ "${QVR_SKIP_INSTALL:-0}" == "1" ]]; then
  warn "QVR_SKIP_INSTALL=1 — skipping Qwen Vast Recovery installation."
  start_entrypoint
fi

installed=""
[[ -f "$MARKER" ]] && installed="$(tr -d '[:space:]' < "$MARKER" || true)"

if [[ "${QVR_FORCE_INSTALL:-0}" == "1" || "$installed" != "$QVR_VERSION" ]]; then
  log "Installing/updating Qwen Vast Recovery $QVR_VERSION (installed: ${installed:-none})"
  export QVR_BRANCH="$BRANCH"

  if curl -fsSL "https://raw.githubusercontent.com/$REPO/$BRANCH/bootstrap.sh" | bash; then
    printf '%s\n' "$QVR_VERSION" > "$MARKER"
    rm -f "$FAILED_MARKER"
    ok "Qwen Vast Recovery $QVR_VERSION installed and verified."
  else
    rc=$?
    printf 'version=%s\ntime=%s\nexit_code=%s\n' "$QVR_VERSION" "$(date -Iseconds)" "$rc" > "$FAILED_MARKER"
    err "Qwen Vast Recovery installation failed with exit code $rc."
    err "Success marker was NOT written; the installer will retry on the next restart."
    warn "Starting ComfyUI anyway so the instance remains accessible for diagnostics."
  fi
else
  ok "Qwen Vast Recovery $QVR_VERSION already installed — skipping installer."
fi

start_entrypoint
