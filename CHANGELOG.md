# Changelog

## Face Guard v6

### Added
- Added a real post-process identity-preservation branch to all workflow JSON files.
- Added `ReActorFaceSwap` after the main Qwen decode stage.
- Added `UltralyticsDetectorProvider`, `ToBasicPipe`, `BasicPipeToDetailerPipe`, and `FaceDetailerPipe` nodes to build an active face cleanup stack.
- Added final preview nodes for the Face Guard output.

### Changed
- Rewired workflow outputs so `SaveImage` now saves the Face Guard final image by default.
- Expanded `impact-pack`, `impact-subpack`, and `reactor` usage across the full workflow library.
- Added `tf-keras` as an extra pip dependency for ReActor compatibility.
- Updated identity-preservation documentation and README notes to reflect the active stack.

### Notes
- If a workflow is used for non-human images, the Face Guard nodes can be bypassed inside ComfyUI.

## Unreleased

### Changed
- Reorganized repository into workflows, manifests, scripts, and docs.
- Made manifests the single source of truth for installation.
- Added automatic installation of the complete active workflow library.
- Added custom-node dependency installation.
- Added repository and install verification.
- Added GitHub Actions validation.
- Moved previous workflow files into `workflows/legacy/`.

### Reliability
- Verified current primary model/LoRA repositories.
- Moved SexGod v2 primary download from Civitai to a verified Hugging Face mirror, with fallbacks.
- Made optional LoRA/custom-node failures non-fatal.
- Required model failures no longer prevent later installation stages from being attempted.
- Added source preflight checks.
- Added per-install log files.
- Installer now prefers ComfyUI's own Python virtual environment when available.
