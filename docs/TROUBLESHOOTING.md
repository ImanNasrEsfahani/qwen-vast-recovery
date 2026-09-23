# Troubleshooting

## ComfyUI directory not found

Set it explicitly:

```bash
COMFY=/path/to/ComfyUI ./bootstrap.sh
```

## Civitai download fails

Set a Civitai token:

```bash
export CIVITAI_TOKEN='YOUR_TOKEN'
./bootstrap.sh
```

## Custom node import error

Restart ComfyUI after bootstrap.

If the error persists, inspect the affected directory under:

```text
ComfyUI/custom_nodes/
```

Then rerun bootstrap. It updates Git repositories and reinstalls available `requirements.txt` files.

## A workflow shows a missing model

Check:

```bash
python scripts/verify_install.py   --models manifests/models.json   --workflows manifests/workflows.json   --custom-nodes manifests/custom-nodes.json   --comfy /workspace/ComfyUI
```

## Repository workflow JSON is broken

Run:

```bash
python scripts/validate_repo.py
```

This checks node/link integrity and required guide/prompt nodes.
