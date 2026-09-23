#!/usr/bin/env bash
set -Eeuo pipefail

REPO="ImanNasrEsfahani/qwen-vast-recovery"
BRANCH="${QVR_BRANCH:-main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/scripts/install.sh" ]]; then
  exec bash "$SCRIPT_DIR/scripts/install.sh" "$@"
fi

command -v git >/dev/null 2>&1 || {
  echo "ERROR: git is required for bootstrap installation." >&2
  exit 1
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO.git" "$TMP/repo"
exec bash "$TMP/repo/scripts/install.sh" "$@"
