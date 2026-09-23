# Qwen Image Edit 2511 — Vast.ai Recovery Pack

Complete edition. All requested LoRAs are automatically downloaded by `bootstrap.sh`.

## Required / always enabled
- Qwen Image Edit 2511 Lightning 4-step

## Auto-installed optional LoRAs
All nodes below are present in every workflow and start in **Bypass/OFF**:
- Ultra-Realistic Portrait — `URP_20.safetensors`
- Hyper-Realistic Portrait — `HRP_20.safetensors`
- Anything2Real — `anything2real_2601_A_final_patched.safetensors`
- SexGod v2 — `SEXGOD_FemaleNudity_QwenEdit_2511_v2.safetensors`
- MCNL-NSFW-v1 — `qwen-image-edit-plus-nsfw-lora.safetensors`
- Unblur/Upscale — `Qwen-Image-Edit-Unblur-Upscale_20.safetensors`
- Custom LoRA slot

## Chain
Base → CFGNorm → Lightning (ON) → Ultra → Hyper → Anything2Real → SexGod → MCNL → Unblur → Custom → KSampler

## Workflows
- qwen2511-simple.json
- qwen2511-custom-lora.json
- qwen2511-multi-image-lora.json
- qwen2511-workflow.json (simple alias)

## Civitai authentication
SexGod v2 uses Civitai model version `2689224`.
If Civitai permits anonymous download, bootstrap needs nothing extra.
If authentication is required:
```bash
export CIVITAI_TOKEN='YOUR_TOKEN'
curl -fsSL https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main/bootstrap.sh | bash
```

## Normal install
```bash
curl -fsSL https://raw.githubusercontent.com/ImanNasrEsfahani/qwen-vast-recovery/main/bootstrap.sh | bash
```


## Added workflow pack
This bundle now includes a `workflow_pack/` folder with 10 clearly named editing workflows.

Extra helper files:
- WORKFLOW_INDEX.md
- ADVANCED_REQUIREMENTS.md
- install-advanced-nodes.sh

To use:
- copy the JSON files from `workflow_pack/` into `ComfyUI/user/default/workflows/`
- or drag and drop each JSON directly into ComfyUI
