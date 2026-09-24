# Vast.ai Automatic Startup — v8.2

Use this exact line in the Vast.ai **On-start Script** field:

```bash
curl -fsSL https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main/vast-start.sh | bash
```

v8.2 starts the original Vast `entrypoint.sh` immediately, so the Open button,
Jupyter, ComfyUI and other template services are available without waiting for
large model downloads.

QVR installation runs in the background.

Background log:

```text
/workspace/.qvr-install-background.log
```

Installed version:

```text
/workspace/.qvr-version
```

When installation finishes successfully, this marker is created:

```text
/workspace/.qvr-restart-required
```

Restart the Vast instance once. On the next boot, installation is skipped and
the restart marker is cleared. ReActor/custom nodes then load in the fresh
ComfyUI process.

Useful commands:

```bash
tail -f /workspace/.qvr-install-background.log
cat /workspace/.qvr-version
cat /workspace/.qvr-restart-required
cat /workspace/.qvr-install-failed
```

Emergency fallback: temporarily set Vast On-start Script back to:

```bash
entrypoint.sh
```
