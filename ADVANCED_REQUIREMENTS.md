# Advanced Workflow Requirements

## Main model stack already covered by bootstrap.sh
- Qwen Image Edit 2511 base UNet
- Qwen 2.5 VL text encoder
- Qwen VAE
- Lightning 4-step
- Ultra Portrait
- Hyper Portrait
- Anything2Real
- SexGod v2
- MCNL NSFW
- Unblur / Upscale

## Extra custom nodes worth installing

### 1) ComfyUI-ControlNetAux
Useful for:
- 03_pose_transfer_pro.json
- 04_clothes_pose_transfer_pro.json

Why:
- DWPose / OpenPose preprocessing

Repo:
https://github.com/Fannovel16/comfyui_controlnet_aux

### 2) ComfyUI-Impact-Pack
Useful for:
- 03_pose_transfer_pro.json
- 04_clothes_pose_transfer_pro.json
- 05_identity_lock_editor.json
- 09_restoration_unblur_upscale.json

Why:
- FaceDetailer and post-refinement

Repo:
https://github.com/ltdrdata/ComfyUI-Impact-Pack

### 3) LanPaint
Useful for:
- 06_smart_inpainting_starter.json

Why:
- stronger training-free inpainting / outpainting

Repo:
https://github.com/scraed/LanPaint

## Layered workflow note
For 10_layered_editor_starter.json, you will eventually need the official Qwen-Image-Layered model weights from Qwen's release.
