QWEN IMAGE EDIT 2511 - VAST.AI RECOVERY PACK
=============================================

PURPOSE
-------
This package restores the Qwen Image Edit 2511 setup used with ComfyUI
on a Vast.ai GPU instance.

RECOMMENDED GPU
---------------
NVIDIA RTX 5090
32 GB VRAM

VAST.AI
-------
Create a new Vast.ai instance using a ComfyUI template.

Recommended storage:
100 GB minimum
150-200 GB preferred if also installing video models.

RESTORE PROCEDURE
-----------------

1. Start a Vast.ai ComfyUI instance.

2. Upload this recovery folder to the instance.

3. Open Jupyter Terminal.

4. Run:

chmod +x qwen2511-setup.sh
./qwen2511-setup.sh

5. Wait for approximately 29 GB of model files to download.

6. Restart ComfyUI if necessary.

7. Open ComfyUI.

8. Load:
qwen2511-workflow.json

9. Select/upload the required input images.

10. Enter the edit prompt.

11. Press Run.

MODELS
------
Diffusion:
qwen_image_edit_2511_fp8mixed.safetensors

Text Encoder:
qwen_2.5_vl_7b_fp8_scaled.safetensors

VAE:
qwen_image_vae.safetensors

Acceleration LoRA:
Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors

IMPORTANT
---------
Do not keep a Vast.ai instance running only to preserve public model files.

After saving outputs and this recovery package, Destroy the instance if
you no longer need it in order to stop ongoing storage charges.
