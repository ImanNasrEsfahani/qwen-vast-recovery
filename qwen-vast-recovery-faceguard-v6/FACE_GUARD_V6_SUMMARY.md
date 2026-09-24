# Face Guard v6 Summary

This package updates the workflow library with a stronger face-preservation stack.

## What changed

### 1) All workflow JSON files updated
Each workflow now includes an active post-process branch:

Qwen output -> ReActor face restore -> FaceDetailer cleanup -> SaveImage

New nodes added to each workflow:
- MarkdownNote (Face Guard v6 note)
- ToBasicPipe
- UltralyticsDetectorProvider
- BasicPipeToDetailerPipe
- ReActorFaceSwap
- FaceDetailerPipe
- PreviewImage

### 2) SaveImage rewired
`SaveImage` now saves the Face Guard final output by default.

### 3) Installer updated
`scripts/install_custom_nodes.py` now supports `extra_pip_packages` from the manifest.

### 4) Manifest updated
`manifests/custom-nodes.json` now:
- expands `impact-pack`, `impact-subpack`, and `reactor` coverage across the workflow library
- adds `tf-keras` as an extra pip dependency for ReActor compatibility

### 5) Docs updated
Updated files:
- `README.md`
- `CHANGELOG.md`
- `docs/IDENTITY_PRESERVATION.md`
- `docs/WORKFLOWS.md`

## Identity anchor rule
- Default: Image 1 is the identity anchor.
- Exception: `12-identity-lock.json` uses Image 2 as the identity anchor.

## Runtime note
If a workflow is used for a non-human image or no face exists, bypass the Face Guard nodes in ComfyUI.
