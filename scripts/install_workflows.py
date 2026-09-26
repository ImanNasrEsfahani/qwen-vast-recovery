#!/usr/bin/env python3
import argparse, json
from pathlib import Path

BASE_MODEL_NAMES = {
    "qwen_image_edit_2511_fp8mixed.safetensors",
    "qwen_image_edit_2511_bf16.safetensors",
    "qwen_image_edit_2511_int8_convrot.safetensors",
}

def load_selection(path):
    if not path:
        return {}
    p = Path(path)
    if not p.exists():
        return {}
    return json.loads(p.read_text(encoding="utf-8"))

def replace_base_model(value, selected_filename):
    if isinstance(value, dict):
        return {k: replace_base_model(v, selected_filename) for k, v in value.items()}
    if isinstance(value, list):
        return [replace_base_model(v, selected_filename) for v in value]
    if isinstance(value, str) and value in BASE_MODEL_NAMES:
        return selected_filename
    return value

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--repo-root", required=True)
    ap.add_argument("--comfy", required=True)
    ap.add_argument("--selection")
    args = ap.parse_args()

    repo = Path(args.repo_root)
    comfy = Path(args.comfy)
    data = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    selection = load_selection(args.selection)
    selected_filename = selection.get("qwen", {}).get("filename")
    target_dir = comfy / data.get("install_directory", "user/default/workflows/qwen2511")
    target_dir.mkdir(parents=True, exist_ok=True)

    if selected_filename:
        print(f"Workflow base model: {selected_filename}")

    required_failures = []
    optional_failures = []

    for item in data["items"]:
        if not item.get("install_by_default", False):
            continue
        try:
            src = repo / item["path"]
            if not src.exists():
                raise FileNotFoundError(f"workflow source missing: {src}")
            payload = json.loads(src.read_text(encoding="utf-8"))
            if selected_filename:
                payload = replace_base_model(payload, selected_filename)
            dst = target_dir / src.name
            dst.write_text(
                json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            print(f"✓ {item['id']}: {dst.name}")
        except Exception as exc:
            if item.get("required", False):
                required_failures.append((item["id"], str(exc)))
                print(f"✗ REQUIRED WORKFLOW FAILED: {item['id']} — continuing")
            else:
                optional_failures.append((item["id"], str(exc)))
                print(f"⚠ OPTIONAL WORKFLOW FAILED: {item['id']} — continuing")

    if optional_failures:
        print("\nOptional workflow warnings:")
        for item_id, msg in optional_failures:
            print(f"  - {item_id}: {msg}")
    if required_failures:
        print("\nRequired workflow failures:")
        for item_id, msg in required_failures:
            print(f"  - {item_id}: {msg}")

    raise SystemExit(1 if required_failures else 0)

if __name__ == "__main__":
    main()
