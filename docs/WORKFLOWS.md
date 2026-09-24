## Face Guard v6

All active workflows now include a stronger face-preservation branch for human subjects:
`Qwen output → ReActor face restore → FaceDetailer cleanup → SaveImage`.
If no human face is present, bypass the Face Guard nodes.

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


## Identity behavior across workflows

All active workflows now include:
- explicit identity-preserving positive prompt language;
- stronger negative prompts against face mismatch / identity drift;
- Markdown instructions inside the workflow canvas that clarify which input image is the identity anchor.

Default rule:
- `Image 1 = identity anchor`

Exception:
- `12-identity-lock.json` uses `Image 2 = identity anchor`.


The workflows now use a split-prompt design with SYSTEM PROMPT / USER PROMPT and SYSTEM NEGATIVE / USER NEGATIVE.
