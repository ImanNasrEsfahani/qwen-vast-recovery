#!/usr/bin/env python3
import argparse, hashlib, json
from pathlib import Path

def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))

def load_selection(path):
    if not path:
        return {}
    p=Path(path)
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}

def should_verify_model(item, selection):
    if item.get("role") == "base_model":
        wanted=selection.get("qwen",{}).get("model_id")
        if wanted:
            return item["id"] == wanted
    return item.get("install_by_default", False)

def sha256_file(path, chunk=8*1024*1024):
    h=hashlib.sha256()
    with Path(path).open("rb") as f:
        while True:
            b=f.read(chunk)
            if not b: break
            h.update(b)
    return h.hexdigest()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--models", required=True)
    ap.add_argument("--workflows", required=True)
    ap.add_argument("--custom-nodes", required=True)
    ap.add_argument("--comfy", required=True)
    ap.add_argument("--selection")
    args = ap.parse_args()

    comfy = Path(args.comfy)
    selection = load_selection(args.selection)
    required_failures = []
    warnings = []

    models = load(args.models)
    print("Models / LoRAs:")
    for item in models["items"]:
        if not should_verify_model(item, selection):
            continue
        p = comfy / item["target"]
        good = p.exists() and p.stat().st_size > 1_000_000
        symbol = "✓" if good else ("✗" if item.get("required", False) else "⚠")
        print(symbol, item["id"], p)
        if not good:
            (required_failures if item.get("required", False) else warnings).append(f"model:{item['id']}")

    workflows = load(args.workflows)
    wf_dir = comfy / workflows.get("install_directory", "user/default/workflows/qwen2511")
    expected_model = selection.get("qwen",{}).get("filename")
    print("\nWorkflows:")
    for item in workflows["items"]:
        if not item.get("install_by_default", False):
            continue
        p = wf_dir / Path(item["path"]).name
        good = p.exists() and p.stat().st_size > 100
        if good and expected_model:
            try:
                payload = p.read_text(encoding="utf-8")
                if expected_model not in payload:
                    good = False
            except Exception:
                good = False
        symbol = "✓" if good else ("✗" if item.get("required", False) else "⚠")
        print(symbol, item["id"], p)
        if not good:
            (required_failures if item.get("required", False) else warnings).append(f"workflow:{item['id']}")

    nodes = load(args.custom_nodes)
    print("\nCustom nodes:")
    for item in nodes["items"]:
        if not item.get("install_by_default", False):
            continue
        p = comfy / "custom_nodes" / item["directory"]
        good = p.exists()
        symbol = "✓" if good else ("✗" if item.get("required", False) else "⚠")
        print(symbol, item["id"], p)
        if not good:
            (required_failures if item.get("required", False) else warnings).append(f"node:{item['id']}")
        if good:
            for asset in item.get("required_assets", []):
                apath = comfy / asset["path"]
                amin = int(asset.get("min_size", 1))
                agood = apath.exists() and apath.stat().st_size >= amin
                expected = asset.get("sha256")
                if agood and expected:
                    agood = sha256_file(apath).lower() == expected.lower()
                print(("✓" if agood else "✗"), f"asset:{item['id']}", apath)
                if not agood:
                    (required_failures if item.get("required", False) else warnings).append(
                        f"asset:{item['id']}:{asset['path']}"
                    )

    print("\n=== FINAL VERIFICATION ===")
    if selection:
        print("Hardware profile:")
        print("  GPU:", selection.get("hardware",{}).get("gpu_name"))
        print("  VRAM:", selection.get("hardware",{}).get("vram_gb"), "GB")
        print("  Qwen:", selection.get("qwen",{}).get("variant"))
        print("  ONNX:", selection.get("reactor",{}).get("onnxruntime_requirement"))
    if warnings:
        print("Optional/recommended components missing:")
        for w in warnings:
            print("  ⚠", w)
    if required_failures:
        print("Required components missing:")
        for f in required_failures:
            print("  ✗", f)
        return 1

    print("Core installation is healthy.")
    if warnings:
        print("Installation is usable, with optional warnings shown above.")
    else:
        print("All selected/default components are present.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
