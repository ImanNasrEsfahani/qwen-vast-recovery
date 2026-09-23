# Migration from the Old Layout

The old repository kept workflows and install metadata directly in the root.

The new layout separates concerns.

| Old file/location | New location / replacement |
|---|---|
| `models.txt` | `manifests/models.json` + `docs/MODELS.md` |
| `WORKFLOW_INDEX.md` | `manifests/workflows.json` + `docs/WORKFLOWS.md` |
| `ADVANCED_REQUIREMENTS.md` | `manifests/custom-nodes.json` |
| `install-advanced-nodes.sh` | `scripts/install_custom_nodes.py` |
| `verify-install.sh` | `scripts/verify_install.py` |
| `install-lora.sh` | `scripts/install_lora.sh` |
| `workflow_pack/` | category folders under `workflows/` |
| root legacy workflow JSONs | `workflows/legacy/` |

`bootstrap.sh` intentionally remains in the repository root because it is the stable public install entry point.
