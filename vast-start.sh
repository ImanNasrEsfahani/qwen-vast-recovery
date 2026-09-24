#!/usr/bin/env bash
set -Euo pipefail

REPO="ImanNasrEsfahani/qwen-vast-recovery"
BRANCH="${QVR_BRANCH:-main}"
QVR_VERSION="8.2.0"

log(){ printf '\n\033[1;36m[QVR Vast Start]\033[0m %s\n' "$*"; }
ok(){ printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m⚠\033[0m %s\n' "$*"; }
err(){ printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; }

if [[ -d /workspace && -w /workspace ]]; then
  STATE_DIR="${QVR_STATE_DIR:-/workspace}"
else
  STATE_DIR="${QVR_STATE_DIR:-$HOME}"
fi

MARKER="$STATE_DIR/.qvr-version"
FAILED_MARKER="$STATE_DIR/.qvr-install-failed"
RESTART_MARKER="$STATE_DIR/.qvr-restart-required"
BACKGROUND_LOG="$STATE_DIR/.qvr-install-background.log"

find_entrypoint(){
  if [[ -n "${QVR_ENTRYPOINT:-}" && -x "${QVR_ENTRYPOINT}" ]]; then
    printf '%s\n' "$QVR_ENTRYPOINT"
    return 0
  fi
  if command -v entrypoint.sh >/dev/null 2>&1; then
    command -v entrypoint.sh
    return 0
  fi
  local candidate
  for candidate in /entrypoint.sh /usr/local/bin/entrypoint.sh /workspace/entrypoint.sh; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

mkdir -p "$STATE_DIR"

ENTRYPOINT="$(find_entrypoint || true)"
if [[ -z "$ENTRYPOINT" ]]; then
  err "Could not find an executable Vast template entrypoint.sh."
  err "Set QVR_ENTRYPOINT=/full/path/to/entrypoint.sh if required."
  exit 127
fi

# Start the original Vast template immediately so Open/Jupyter/ComfyUI
# are available while QVR installs in the background.
log "Starting original Vast template entrypoint immediately: $ENTRYPOINT"
"$ENTRYPOINT" &
ENTRYPOINT_PID=$!
ok "Vast template entrypoint started (PID $ENTRYPOINT_PID)."

installed=""
[[ -f "$MARKER" ]] && installed="$(tr -d '[:space:]' < "$MARKER" || true)"

if [[ "${QVR_SKIP_INSTALL:-0}" == "1" ]]; then
  warn "QVR_SKIP_INSTALL=1 — QVR installer skipped."
elif [[ "${QVR_FORCE_INSTALL:-0}" == "1" || "$installed" != "$QVR_VERSION" ]]; then
  log "Starting Qwen Vast Recovery $QVR_VERSION installer in BACKGROUND."
  log "Installer log: $BACKGROUND_LOG"

  (
    set +e
    export QVR_BRANCH="$BRANCH"

    {
      echo "============================================================"
      echo "Qwen Vast Recovery background install"
      echo "version=$QVR_VERSION"
      echo "started=$(date -Iseconds)"
      echo "============================================================"
    } > "$BACKGROUND_LOG"

    if curl -fsSL "https://raw.githubusercontent.com/$REPO/$BRANCH/bootstrap.sh" \
        | bash >> "$BACKGROUND_LOG" 2>&1; then
      printf '%s\n' "$QVR_VERSION" > "$MARKER"
      rm -f "$FAILED_MARKER"
      printf 'version=%s\ncompleted=%s\n' "$QVR_VERSION" "$(date -Iseconds)" > "$RESTART_MARKER"
      {
        echo
        echo "QVR INSTALL SUCCESS"
        echo "Restart the Vast instance once so ComfyUI loads newly installed custom nodes."
      } >> "$BACKGROUND_LOG"
    else
      rc=$?
      printf 'version=%s\ntime=%s\nexit_code=%s\n' \
        "$QVR_VERSION" "$(date -Iseconds)" "$rc" > "$FAILED_MARKER"
      {
        echo
        echo "QVR INSTALL FAILED exit_code=$rc"
        echo "The installer will retry on the next instance restart."
      } >> "$BACKGROUND_LOG"
    fi
  ) &

  INSTALL_PID=$!
  ok "Background installer started (PID $INSTALL_PID)."
  warn "Vast Open/Jupyter/ComfyUI can be used while installation continues."
  warn "After install succeeds, restart the instance ONCE to load ReActor/custom nodes."
else
  ok "Qwen Vast Recovery $QVR_VERSION already installed — installer skipped."
  if [[ -f "$RESTART_MARKER" ]]; then
    rm -f "$RESTART_MARKER"
    ok "Post-install restart detected; custom nodes can now load normally."
  fi
fi

wait "$ENTRYPOINT_PID"
rc=$?
warn "Original Vast entrypoint exited with code $rc."
exit "$rc"
