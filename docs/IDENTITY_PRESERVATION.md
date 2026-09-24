# Identity Preservation Stack

This repository now treats **identity / face stability** as a first-class concern across the active workflow library.

## Core rule

Unless a workflow explicitly says otherwise:

- **Image 1 is the identity anchor**
- other references may affect:
  - clothing
  - pose
  - background
  - material
  - style
  - lighting
- but they should **not** replace facial identity

For `12-identity-lock.json`, **Image 2** is the identity anchor.

## Practical methods used across workflows

### 1) Prompt-level identity lock
Every active workflow now starts with identity-preserving language such as:

- preserve the exact facial identity
- do not change face shape, eyes, nose, mouth, skin characteristics
- keep recognizable appearance stable

### 2) Reference-role separation
The prompts and notes explicitly define which image controls:
- identity
- clothing
- pose
- style/material

This reduces "reference competition".

### 3) Negative prompt support
Negative prompts now explicitly discourage:
- identity drift
- changed facial features
- face mismatch
- wrong identity

### 4) Local editing / inpainting strategy
For non-face edits:
- only edit the region that must change
- avoid letting the face regenerate if it is not necessary

This is especially important for:
- clothes replacement
- object edits
- background edits

### 5) ReActor fallback
`ComfyUI-ReActor` is included as an optional custom node dependency.

Recommended use:
- run the normal Qwen edit first
- if the face drifts, use ReActor as a post-process face restore / face re-alignment step

### 6) FaceDetailer as cleanup, not identity source
If you later build advanced variants with Impact Pack:
- use FaceDetailer with **low denoise**
- use it to clean details, not to invent a new face

## Recommended identity-safe workflow strategy

### General edits
Use:
- `01-general-editor`
- `02-multi-reference-editor`

Keep:
- Image 1 = identity anchor

### Pose transfer
Use:
- `10-pose-transfer`
- `11-clothes-pose-transfer`

Keep:
- Image 1 = identity anchor
- pose reference = pose only
- clothes reference = clothing only

### Strongest identity protection
Best practice stack:

1. identity anchor image
2. explicit identity-preserving prompt
3. local/cropped editing where possible
4. ReActor fallback if needed
5. FaceDetailer low-denoise cleanup if needed

## Future advanced variants

A future advanced version of the repository can add dedicated:
- ReActor post-process workflows
- Crop-and-stitch identity-safe workflows
- Face-only restore branches
- Mask-first inpainting pipelines


The workflows now use a split-prompt design with SYSTEM PROMPT / USER PROMPT and SYSTEM NEGATIVE / USER NEGATIVE.
