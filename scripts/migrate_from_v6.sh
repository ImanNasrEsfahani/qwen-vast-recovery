#!/usr/bin/env bash
set -Euo pipefail
COMFY="${COMFY:-/workspace/ComfyUI}"
if [[ ! -d "$COMFY" ]]; then echo "Set COMFY=/path/to/ComfyUI" >&2; exit 1; fi
PY=""
[[ -x "$COMFY/venv/bin/python" ]] && PY="$COMFY/venv/bin/python"
[[ -z "$PY" && -x "$COMFY/.venv/bin/python" ]] && PY="$COMFY/.venv/bin/python"
[[ -z "$PY" && -x /venv/main/bin/python3 ]] && PY=/venv/main/bin/python3
[[ -n "$PY" ]] || PY="$(command -v python3)"
echo "ComfyUI: $COMFY"
echo "Python: $PY"
echo
cat <<'EOF'
This v8 pack no longer references these v6 FaceDetailer node types:
- ToBasicPipe
- BasicPipeToDetailerPipe
- FaceDetailerPipe
- UltralyticsDetectorProvider
Therefore Impact Pack/Subpack are NOT required by the production workflows.
Existing Impact folders are left untouched to avoid deleting other workflows' dependencies.
EOF
