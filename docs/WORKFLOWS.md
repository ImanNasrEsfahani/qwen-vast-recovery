# Workflow Catalog

The workflow filenames are intentionally numbered so related workflows remain grouped in ComfyUI.

| ID | Workflow | Category | Status | Purpose |
|---|---|---|---|---|
| 01 | General Editor | General | Stable | Everyday image editing |
| 02 | Multi-Reference Editor | General | Stable | Target + multiple references |
| 10 | Pose Transfer | People | Starter | Transfer stance/body pose |
| 11 | Clothes + Pose Transfer | People | Starter | Outfit + pose onto target person |
| 12 | Identity Lock | People | Stable | Preserve a person's identity |
| 20 | Material Replacement | Editing | Stable | Material/object replacement |
| 21 | Relighting | Editing | Stable | Lighting-first edits |
| 22 | Restoration / Unblur | Editing | Stable | Blur/artifact cleanup |
| 23 | Configurable Upscale 2K / 4K / 8K | Editing | Stable | Adjustable enlargement to target resolution |
| 90 | Inpainting Starter | Experimental | Starter | Localized edit scaffold |
| 91 | Layered Editor Starter | Experimental | Starter | Future layer-aware editing |

Each workflow includes:
- a positive starter prompt;
- a negative prompt;
- a Markdown guide inside the canvas;
- the shared LoRA stack.

Legacy workflows are stored separately and are not installed by default.
