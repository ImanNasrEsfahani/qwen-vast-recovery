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


## One LoRA fails to download

This is non-fatal. The installer continues with the remaining models, nodes, and workflows.

The final verification prints the missing LoRA with a warning (`⚠`).

## One optional custom node fails to install

This is also non-fatal. This is especially useful for packages whose Python dependencies can vary by CUDA/Python/platform.

Review the installation log under:

```text
ComfyUI/.qwen2511-install/
```

Then install or repair that node independently later.

## Check source availability without a full install

From the repository:

```bash
python scripts/check_sources.py   --models manifests/models.json   --custom-nodes manifests/custom-nodes.json
```


## The face changes too much

Recommended fixes:

1. Make sure the intended identity anchor image is in the correct input slot.
2. Keep the prompt conservative and explicitly say to preserve the person's identity.
3. If the change is local (for example clothing only), use the inpainting/local-edit approach.
4. If needed, use ReActor as a final face restore / face re-alignment stage.
5. If you later build a FaceDetailer pass, keep denoise low.
