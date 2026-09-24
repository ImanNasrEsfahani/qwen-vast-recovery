# Architecture

## Goal

Keep the user experience extremely simple while making the repository easy to extend.

The public interface is one command:

```bash
curl -fsSL https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main/bootstrap.sh | bash
```

Internally, the repository is manifest-driven.

## Data flow

```text
bootstrap.sh
   ↓
scripts/install.sh
   ├── manifests/models.json       → scripts/install_models.py
   ├── manifests/custom-nodes.json → scripts/install_custom_nodes.py
   ├── manifests/workflows.json    → scripts/install_workflows.py
   └── same manifests              → scripts/verify_install.py
```

This means model and workflow lists are not duplicated across multiple scripts.

## Workflow categories

- `general/` — broad daily editing
- `people/` — identity, pose, clothing
- `editing/` — material, lighting, restoration
- `experimental/` — starter workflows that are expected to evolve
- `legacy/` — previous files kept only for reference

## Stable vs starter

`manifests/workflows.json` records a workflow status.

- `stable`: intended as a normal user workflow.
- `starter`: runs with the current base stack but is designed for further advanced node integration.
- `deprecated`: kept for migration/reference only.

## Extensibility

To add a model:
1. Add one entry to `manifests/models.json`.
2. Reference its exact filename inside any workflow that needs it.
3. Run `python scripts/validate_repo.py`.

To add a workflow:
1. Put the JSON in the correct workflow category.
2. Add one entry to `manifests/workflows.json`.
3. Run repository validation.

The installer automatically picks up entries with `install_by_default: true`.


## Identity Preservation

Identity preservation is handled at three levels:

1. **Workflow design**
   - input roles are explicit;
   - identity anchor is documented in the canvas.

2. **Prompt design**
   - every active workflow includes built-in identity-preserving prompt language.

3. **Optional post-process recovery**
   - ReActor is installed as an optional dependency for cases where a final face restore pass is needed.
