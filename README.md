# Qwen Image Edit 2511 — Vast.ai Recovery Pack

This repository turns a fresh **Vast.ai ComfyUI instance** into the Qwen Image Edit 2511 setup with one command.

## One-command install

Open **Jupyter Terminal** on the new Vast.ai instance and run:

```bash
curl -fsSL https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main/bootstrap.sh | bash
```

The script automatically:

1. finds the ComfyUI installation;
2. creates the required model folders;
3. installs/updates `huggingface_hub` and `hf_xet`;
4. downloads the Qwen Image Edit 2511 FP8 mixed model;
5. downloads the Qwen 2.5 VL text encoder;
6. downloads the Qwen Image VAE;
7. downloads the 4-step Lightning LoRA;
8. downloads and validates `qwen2511-workflow.json`;
9. places the workflow in `ComfyUI/user/default/workflows/`;
10. verifies the installation;
11. attempts to restart ComfyUI.

Large `.safetensors` files are **not stored in this repository**. They are downloaded directly from Hugging Face on the Vast.ai server.

## Recommended Vast.ai configuration

- Template: ComfyUI
- GPU: RTX 5090 32 GB is a good choice for this workflow
- Rental: On-demand
- Disk: at least 100 GB for this image workflow; 150–250 GB if you also plan to install video models
- Reliability: preferably 99%+
- Fast download networking is useful because the first setup downloads tens of GB

## Files in this repository

- `bootstrap.sh` — one-command installer
- `qwen2511-workflow.json` — ready-to-load single-image editing workflow
- `verify-install.sh` — checks that all expected files exist
- `models.txt` — model names, repositories and destination folders
- `install-command.txt` — the one command to copy/paste

## After installation

Open ComfyUI and load:

```text
qwen2511-workflow.json
```

Then:

1. choose/upload the image in **Load Image**;
2. edit **Positive Prompt**;
3. click **Queue / Run**.

The included workflow is intentionally simple and uses only native/core ComfyUI nodes used by the official Qwen Image Edit 2511 workflow family.

It is configured for the Lightning 4-step LoRA:

- Steps: `4`
- CFG: `1.0`
- Sampler: `euler`
- Scheduler: `simple`

## Verify manually

```bash
curl -fsSL https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main/verify-install.sh | bash
```

## If models do not appear

Refresh ComfyUI. If necessary, restart ComfyUI from the Vast.ai Instance Portal.

## Re-running the installer

It is safe to run the bootstrap command again. Existing complete model files are skipped. Hugging Face's downloader also supports resuming interrupted downloads.

## Important Vast.ai cost note

When you are completely finished with an instance, save/download your outputs and **Destroy/Delete** the instance rather than merely stopping it if you do not want to continue paying for its storage.
