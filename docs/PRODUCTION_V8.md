# Production v8 — Missing Node Fix Summary

This version is specifically designed to remove the v6 Missing Node Pack problems.

## Production graph

For people workflows:

`Qwen Image Edit 2511 -> ReActorFaceSwap -> SaveImage`

No production workflow contains:
- `ToBasicPipe`
- `BasicPipeToDetailerPipe`
- `FaceDetailerPipe`
- `UltralyticsDetectorProvider`

Therefore ComfyUI Impact Pack and Impact Subpack are not required to open/run production v8 workflows.

## ReActor reliability changes

- ReActor is pinned to upstream commit `a12c5b19dcac9ae8b47e592da39c9711c8f8c756` (0.7.1-b3 era) to prevent silent schema drift.
- Official ReActor `install.py` is executed.
- `inswapper_128.onnx` is required at `models/insightface/inswapper_128.onnx`.
- The asset has a fallback download URL and SHA256 verification:
  `e4a3f08c753cb72d04e10aa0f7dbe3deebbf39567d4ead6dce08e98aa49e16af`
- After installation the actual ComfyUI Python environment imports ReActor and confirms `ReActorFaceSwap` is registered with the expected current input schema.
- If that runtime probe fails, the overall installation is marked incomplete instead of reporting a false success.

## Existing v6 servers

Running v8 overwrites the installed workflow JSONs with versions that do not reference Impact FaceDetailer nodes. Existing Impact Pack/Subpack folders are not deleted because they may be used by unrelated workflows.

After installation restart ComfyUI so the pinned ReActor node is registered.
