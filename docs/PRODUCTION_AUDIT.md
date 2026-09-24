# Production v7 Audit

Key reliability changes:

- ReActor is required and its official installer is executed.
- `inswapper_128.onnx` is verified after installation.
- ReActor workflow nodes use the current 11-widget schema.
- Prompt Guard nodes are normalized to current ComfyUI input ordering.
- `StringConcatenate` stores the current three widget values.
- Generic `FaceDetailerPipe` is excluded from the production Qwen Image Edit chain.
- Lightning is required because it is enabled in default fast workflows.
- Unblur/Upscale is required because workflows 22 and 23 enable it by default.
- Unused advanced custom-node packs are opt-in instead of being installed into every fresh environment.
- ComfyUI is checked for required native node support before large downloads begin.

Limitations:
- Pose workflows are still semantic reference workflows; they are not a DWPose/ControlNet implementation.
- Inpainting and layered workflows remain starter scaffolds, not full LanPaint/Qwen-Layered implementations.
- 8K execution depends on available VRAM/system RAM and cannot be guaranteed on every GPU.
