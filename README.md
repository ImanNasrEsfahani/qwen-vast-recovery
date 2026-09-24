# Qwen Vast Recovery

A structured, reproducible ComfyUI recovery pack for **Qwen Image Edit 2511** on Vast.ai and other Linux GPU hosts.

The project keeps installation simple for users while keeping the repository maintainable for future workflows, LoRAs, models, and custom nodes.

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main/bootstrap.sh | bash
```

If Civitai authentication is required:

```bash
export CIVITAI_TOKEN='YOUR_TOKEN'
curl -fsSL https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main/bootstrap.sh | bash
```

## Repository layout

```text
qwen-vast-recovery/
├── bootstrap.sh                 # stable one-command entry point
├── manifests/                   # single source of truth
│   ├── models.json
│   ├── custom-nodes.json
│   └── workflows.json
├── workflows/
│   ├── general/
│   ├── people/
│   ├── editing/
│   ├── experimental/
│   └── legacy/
├── scripts/                     # installation + verification + validation
├── docs/                        # user and maintainer documentation
└── .github/workflows/           # repository validation
```

## Design principles

- **One source of truth:** model, node, and workflow lists live in manifests.
- **One-command install:** `bootstrap.sh` remains the public entry point.
- **No duplicated install lists:** installer and verifier read the same manifests.
- **Clear workflow categories:** general, people, editing, experimental, legacy.
- **Safe growth:** adding a workflow or LoRA does not require rewriting the installer.
- **Validation:** workflow graph integrity and manifest paths are checked automatically.

## Installed workflow library

### General
- `01-general-editor` — daily general-purpose editing
- `02-multi-reference-editor` — target + multiple references

### People
- `10-pose-transfer`
- `11-clothes-pose-transfer`
- `12-identity-lock`

### Editing
- `20-material-replacement`
- `21-relighting`
- `22-restoration-unblur`

### Experimental / starters
- `90-inpainting-starter`
- `91-layered-editor-starter`

Old workflows are kept under `workflows/legacy/` for reference and are not installed by default.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Installation](docs/INSTALLATION.md)
- [Workflow catalog](docs/WORKFLOWS.md)
- [Models and LoRAs](docs/MODELS.md)
- [Adding workflows](docs/ADDING_WORKFLOWS.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Migration from the old layout](docs/MIGRATION.md)


## Fault-tolerant installation

The installer distinguishes between **required core components** and **optional/recommended components**.

Required core:
- Qwen Image Edit 2511 FP8 model
- Qwen 2.5 VL text encoder
- Qwen VAE

Optional/recommended:
- all LoRAs, including Lightning
- ControlNetAux
- Impact Pack / Impact Subpack
- LanPaint
- experimental starter workflows

If an optional LoRA or custom node fails, installation **continues**. The failure is printed as a warning and the final verification lists the missing optional component.

If a required core model fails, the installer still attempts the remaining stages, then exits with an incomplete-install status at the end.

Logs are written to:

```text
ComfyUI/.qwen2511-install/
```

Optional SHA256 verification can be enabled with:

```bash
export QVR_VERIFY_SHA256=1
```


## Identity preservation

The active workflow library has been updated so identity / face stability is explicit across prompts and internal notes.

See:
- [Identity preservation](docs/IDENTITY_PRESERVATION.md)

The installer also includes **ComfyUI-ReActor** as an optional custom-node dependency to support post-process face restoration when identity drift happens.

As of **Face Guard v6**, the active workflows now include a real post-process branch for human subjects:

- **Qwen output → ReActor face restore → FaceDetailer cleanup → SaveImage**
- `Impact Pack` and `Impact Subpack` are now part of the recommended stack across the active library.
- `tf-keras` is installed for better ReActor compatibility.

If a workflow is used on a non-human image, the Face Guard nodes can be bypassed inside ComfyUI.


## Prompt Guard architecture

The active workflows now protect identity-preservation logic by splitting prompts into:

- **SYSTEM PROMPT** — protected workflow-level rules (identity, role separation, stability)
- **USER PROMPT** — the editable part for daily use
- **SYSTEM NEGATIVE** — protected anti-drift rules
- **USER NEGATIVE** — optional user negatives

This prevents accidental deletion of core identity-preservation instructions when a user edits the prompt.
