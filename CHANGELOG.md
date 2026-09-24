# Changelog


## 8.2.0

### Fixed
- Fixed Vast.ai Open/Jupyter/ComfyUI being unavailable while QVR installed.
- `vast-start.sh` now launches the original Vast `entrypoint.sh` immediately.
- QVR installation now runs in the background.
- Added `/workspace/.qvr-install-background.log`.
- Added `/workspace/.qvr-restart-required`.
- On the next restart, installation is skipped and the restart marker is cleared.
- Documented emergency recovery by temporarily restoring `entrypoint.sh`.


## Production v8.1 (8.1.0)

### Added
- Added `vast-start.sh` for Vast.ai On-start Script automation.
- Added persistent version marker `/workspace/.qvr-version`.
- Added failed-install marker `/workspace/.qvr-install-failed`.
- Added `VERSION`, `vast-on-start.txt`, and `docs/VAST_AI.md`.

### Reliability
- Vast startup only writes the success marker after the installer returns success.
- Failed installation still starts the original template entrypoint so the instance remains accessible for diagnostics.
- Fixed remote `bootstrap.sh` temporary clone cleanup by returning before the EXIT trap.
- GitHub Actions now checks `vast-start.sh` shell syntax.

## Production v8

### Fixed
- Removed all Impact FaceDetailer node references (`ToBasicPipe`, `BasicPipeToDetailerPipe`, `FaceDetailerPipe`, `UltralyticsDetectorProvider`) from production workflows.
- Pinned ReActor to `a12c5b19dcac9ae8b47e592da39c9711c8f8c756` to prevent future node-schema drift.
- Runs official ReActor `install.py` and verifies the required swap model.
- Added fallback download + SHA256 verification for `inswapper_128.onnx`.
- Added runtime import/registration verification for `ReActorFaceSwap`; a broken custom-node import can no longer be reported as a healthy install.
- Removed forced `tf-keras` installation because it is not part of ReActor's official requirements and unnecessarily injects TensorFlow into the ComfyUI environment.

## Production v7

- Rebuilt Face Guard around current ReActor schema and official installer.
- Removed generic FaceDetailer from the default Qwen edit output chain.
- Fixed Prompt Guard serialization/order for current ComfyUI core nodes.
- Added ComfyUI compatibility preflight and required-asset verification.
- Marked active default LoRA dependencies correctly.
- Made unused custom-node packs opt-in.

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
