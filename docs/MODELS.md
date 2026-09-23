# Models and LoRAs

The authoritative list is `manifests/models.json`.

Do not maintain a second handwritten model list in installer scripts.

## Rules

- `required: true` means the normal workflow stack depends on the model.
- `install_by_default: true` means bootstrap downloads it.
- `workflow_default: enabled` means it should normally be active in a workflow.
- `workflow_default: bypassed` means the file is installed but its LoRA node should start disabled.

## Adding a model

Add a manifest item with:
- unique `id`
- display `name`
- `provider`
- exact remote file information
- exact ComfyUI `target`
- install/default flags

Supported download providers in the current installer:
- Hugging Face
- Civitai model-version download
