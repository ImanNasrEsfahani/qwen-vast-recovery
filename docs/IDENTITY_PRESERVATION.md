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

### 5) ReActor face-restore pass
The active workflows now include a **real ReActor post-process pass** after the main Qwen generation.

Default chain:

1. Qwen performs the main edit
2. ReActor restores the identity anchor face back onto the edited result
3. the restored output continues to the final cleanup stage

### 6) FaceDetailer cleanup pass
The active workflows also include an **active FaceDetailer cleanup stage** after ReActor.

Use case:
- recover facial detail after the restore pass
- refine local face quality
- keep the result cleaner with limited denoise instead of re-inventing identity

### 7) Face detector branch
To support FaceDetailer, the workflows now build a detector/detailer stack using:
- `UltralyticsDetectorProvider`
- `ToBasicPipe`
- `BasicPipeToDetailerPipe`
- `FaceDetailerPipe`

### 8) Prompt Guard
The workflows use split prompts:
- SYSTEM PROMPT
- USER PROMPT
- SYSTEM NEGATIVE
- USER NEGATIVE

This keeps the identity-preservation rules protected during normal prompt editing.

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
Best practice stack now implemented in the active workflows:

1. identity anchor image
2. explicit identity-preserving prompt
3. local/cropped editing where possible
4. ReActor post-process face restore
5. FaceDetailer cleanup

## Runtime notes

- If a workflow is used on a non-human image or when no face exists, bypass the Face Guard nodes in ComfyUI.
- The ReActor branch works best when the identity anchor image has a clear visible face.
- `12-identity-lock` uses Image 2 as the identity source for the restore pass.
- ReActor compatibility is improved by installing `tf-keras`.
