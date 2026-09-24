# Vast.ai automatic startup

Version: **8.1.0**

## Template On-start Script

After this repository version is pushed to GitHub `main`, put exactly this line in Vast.ai **On-start Script**:

```bash
curl -fsSL https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main/vast-start.sh | bash
```

Do not append `entrypoint.sh` manually. `vast-start.sh` calls the template's existing `entrypoint.sh` after installation/version checking.

## Startup flow

1. Read `/workspace/.qvr-version`.
2. If the marker equals `8.1.0`, skip installation.
3. Otherwise run `bootstrap.sh`.
4. The normal installer verifies ComfyUI compatibility, models/LoRAs, pinned ReActor, required ReActor asset, workflows, and runtime registration.
5. Write the version marker only after a successful install.
6. Start the original Vast template `entrypoint.sh`.

If installation fails, no success marker is written. A failure marker is written to `/workspace/.qvr-install-failed`, ComfyUI is still started for diagnostics, and installation is retried on the next restart.

## Useful overrides

Force a reinstall on the next start:

```bash
export QVR_FORCE_INSTALL=1
curl -fsSL https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main/vast-start.sh | bash
```

Use a branch other than `main`:

```bash
export QVR_BRANCH=my-branch
curl -fsSL https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/my-branch/vast-start.sh | bash
```

Skip QVR installation and start the template normally:

```bash
export QVR_SKIP_INSTALL=1
curl -fsSL https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main/vast-start.sh | bash
```
