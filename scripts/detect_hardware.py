#!/usr/bin/env python3
import argparse, json, os, re, subprocess
from pathlib import Path

MODEL_MAP = {
    "fp8mixed": {
        "id": "qwen-edit-2511-fp8",
        "filename": "qwen_image_edit_2511_fp8mixed.safetensors",
    },
    "bf16": {
        "id": "qwen-edit-2511-bf16",
        "filename": "qwen_image_edit_2511_bf16.safetensors",
    },
    "int8_convrot": {
        "id": "qwen-edit-2511-int8",
        "filename": "qwen_image_edit_2511_int8_convrot.safetensors",
    },
}

def run_text(cmd):
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return ""

def version_major(value):
    if not value:
        return None
    m = re.match(r"^\s*(\d+)", str(value))
    return int(m.group(1)) if m else None

def system_ram_gb():
    try:
        text = Path("/proc/meminfo").read_text()
        m = re.search(r"^MemTotal:\s+(\d+)\s+kB", text, re.M)
        if m:
            return round(int(m.group(1)) / 1024 / 1024, 1)
    except Exception:
        pass
    return None

def driver_info():
    out = run_text(["nvidia-smi"])
    driver = None
    cuda_max = None
    m = re.search(r"Driver Version:\s*([0-9.]+)", out)
    if m:
        driver = m.group(1)
    m = re.search(r"CUDA Version:\s*([0-9.]+)", out)
    if m:
        cuda_max = m.group(1)
    return driver, cuda_max

def torch_gpu_info():
    info = {
        "cuda_available": False,
        "gpu_name": None,
        "vram_gb": None,
        "compute_capability": None,
        "torch_version": None,
        "torch_cuda": None,
    }
    try:
        import torch
        info["torch_version"] = str(torch.__version__)
        info["torch_cuda"] = str(torch.version.cuda) if torch.version.cuda else None
        info["cuda_available"] = bool(torch.cuda.is_available())
        if info["cuda_available"]:
            props = torch.cuda.get_device_properties(0)
            info["gpu_name"] = props.name
            info["vram_gb"] = round(props.total_memory / (1024 ** 3), 1)
            major, minor = torch.cuda.get_device_capability(0)
            info["compute_capability"] = f"{major}.{minor}"
    except Exception as exc:
        info["torch_error"] = str(exc)
    return info

def nvidia_query_fallback(info):
    if info.get("gpu_name") and info.get("vram_gb"):
        return info
    out = run_text([
        "nvidia-smi",
        "--query-gpu=name,memory.total",
        "--format=csv,noheader,nounits",
    ])
    if out:
        first = out.splitlines()[0]
        parts = [x.strip() for x in first.split(",", 1)]
        if len(parts) == 2:
            info["gpu_name"] = info.get("gpu_name") or parts[0]
            try:
                info["vram_gb"] = info.get("vram_gb") or round(float(parts[1]) / 1024, 1)
            except ValueError:
                pass
    return info

def choose_model(info):
    override = os.getenv("QVR_MODEL_VARIANT", "auto").strip().lower()
    aliases = {
        "fp8": "fp8mixed",
        "fp8mixed": "fp8mixed",
        "bf16": "bf16",
        "int8": "int8_convrot",
        "int8_convrot": "int8_convrot",
    }
    if override != "auto":
        if override not in aliases:
            raise SystemExit(
                "QVR_MODEL_VARIANT must be auto, fp8mixed, bf16, or int8_convrot"
            )
        variant = aliases[override]
        reason = f"forced by QVR_MODEL_VARIANT={override}"
        return variant, reason

    vram = float(info.get("vram_gb") or 0)
    cc = info.get("compute_capability")
    cc_tuple = (0, 0)
    if cc:
        try:
            a, b = cc.split(".", 1)
            cc_tuple = (int(a), int(b))
        except Exception:
            pass

    bf16_min = float(os.getenv("QVR_BF16_MIN_VRAM_GB", "64"))
    if vram >= bf16_min:
        return "bf16", f"VRAM {vram:.1f} GB >= {bf16_min:.0f} GB quality threshold"

    # Ada (8.9), Hopper (9.x) and Blackwell (10.x+) have strong FP8 support.
    if cc_tuple >= (8, 9):
        return "fp8mixed", f"compute capability {cc or 'unknown'} favors FP8"

    # Older NVIDIA GPUs use the ConvRot INT8 build as a compatibility-first fallback.
    return "int8_convrot", f"compute capability {cc or 'unknown'} uses INT8 compatibility profile"

def choose_ort(info):
    major = version_major(info.get("torch_cuda"))
    if major is None:
        major = version_major(info.get("driver_cuda_max"))
    if major is None:
        return "onnxruntime", "cpu/no CUDA runtime detected"
    if major >= 13:
        return "onnxruntime-gpu>=1.27,<2", f"CUDA {major}.x"
    if major == 12:
        return "onnxruntime-gpu>=1.20.1,<1.27", "CUDA 12.x"
    if major == 11:
        return "onnxruntime-gpu==1.18.1", "CUDA 11.x"
    return "onnxruntime", f"unsupported CUDA major {major}; CPU fallback"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    info = torch_gpu_info()
    info = nvidia_query_fallback(info)
    driver, cuda_max = driver_info()
    info["driver_version"] = driver
    info["driver_cuda_max"] = cuda_max
    info["system_ram_gb"] = system_ram_gb()

    if not info.get("gpu_name"):
        raise SystemExit("No NVIDIA GPU detected. Qwen Vast Recovery requires an NVIDIA CUDA GPU.")
    if not info.get("cuda_available"):
        raise SystemExit(
            "NVIDIA GPU found, but PyTorch CUDA is unavailable in the ComfyUI Python environment."
        )

    variant, reason = choose_model(info)
    model = MODEL_MAP[variant]
    ort_requirement, ort_reason = choose_ort(info)

    result = {
        "schema_version": 1,
        "hardware": info,
        "qwen": {
            "variant": variant,
            "model_id": model["id"],
            "filename": model["filename"],
            "reason": reason,
        },
        "reactor": {
            "onnxruntime_requirement": ort_requirement,
            "reason": ort_reason,
        },
    }

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")

    print("=== HARDWARE DETECTION ===")
    print("GPU:", info.get("gpu_name"))
    print("VRAM:", f"{info.get('vram_gb')} GB")
    print("Compute capability:", info.get("compute_capability"))
    print("Torch:", info.get("torch_version"))
    print("Torch CUDA:", info.get("torch_cuda"))
    print("Driver:", info.get("driver_version"))
    print("Driver CUDA max:", info.get("driver_cuda_max"))
    print("System RAM:", f"{info.get('system_ram_gb')} GB")
    print("Selected Qwen variant:", variant)
    print("Selected model:", model["filename"])
    print("Selection reason:", reason)
    print("ReActor ONNX Runtime:", ort_requirement)
    print("ONNX reason:", ort_reason)
    print("Selection file:", output)

if __name__ == "__main__":
    main()
