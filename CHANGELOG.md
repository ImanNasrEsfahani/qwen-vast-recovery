# Changelog

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
