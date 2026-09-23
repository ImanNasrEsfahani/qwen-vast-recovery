# Installation

## Automatic installation

```bash
curl -fsSL https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main/bootstrap.sh | bash
```

The installer:

1. Finds ComfyUI.
2. Installs the small Python downloader dependencies.
3. Downloads core Qwen models.
4. Downloads the configured LoRAs.
5. Installs advanced custom-node repositories and their Python requirements.
6. Copies the workflow library into:
   `ComfyUI/user/default/workflows/qwen2511/`
7. Verifies the installation.

## Custom ComfyUI path

```bash
COMFY=/custom/path/ComfyUI ./bootstrap.sh
```

## Civitai token

If Civitai requires authentication:

```bash
export CIVITAI_TOKEN='YOUR_TOKEN'
./bootstrap.sh
```

## Update

Run the bootstrap command again. Existing large model files are skipped if already present.

## Verify manually

From a cloned repository:

```bash
python scripts/verify_install.py   --models manifests/models.json   --workflows manifests/workflows.json   --custom-nodes manifests/custom-nodes.json   --comfy /workspace/ComfyUI
```
