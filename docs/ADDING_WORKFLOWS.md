# Adding a Workflow

## 1. Choose a category

- `workflows/general/`
- `workflows/people/`
- `workflows/editing/`
- `workflows/experimental/`

Do not place new active workflows in the repository root.

## 2. Naming

Use a numeric prefix and descriptive kebab-case name.

Examples:

```text
13-face-expression-transfer.json
23-background-replacement.json
24-configurable-upscale.json
92-layered-composite-experiment.json
```

Suggested number ranges:

- `01–09`: general
- `10–19`: people
- `20–29`: editing
- `90–99`: experimental

## 3. Workflow content

Every active workflow should include:

- a `MarkdownNote` explaining purpose and inputs;
- a `Positive Prompt` with a usable starter prompt;
- a negative prompt where appropriate;
- exact model filenames that exist in `manifests/models.json`;
- clear input-node titles.

## 4. Register it

Add one entry to `manifests/workflows.json`.

Set:

```json
{
  "install_by_default": true,
  "status": "stable"
}
```

Use `starter` instead of `stable` when the workflow is intentionally incomplete or designed to be extended.

## 5. Validate

```bash
python scripts/validate_repo.py
```
