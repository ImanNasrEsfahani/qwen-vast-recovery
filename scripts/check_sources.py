#!/usr/bin/env python3
import argparse, json, subprocess
from pathlib import Path
from huggingface_hub import HfApi

def load_selection(path):
    if not path:
        return {}
    p = Path(path)
    if not p.exists():
        return {}
    return json.loads(p.read_text(encoding="utf-8"))

def should_check(item, selection):
    if item.get("role") == "base_model":
        wanted = selection.get("qwen", {}).get("model_id")
        if wanted:
            return item["id"] == wanted
    return item.get("install_by_default", False)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--models", required=True)
    ap.add_argument("--custom-nodes", required=True)
    ap.add_argument("--selection")
    args = ap.parse_args()

    warnings = []
    api = HfApi()
    selection = load_selection(args.selection)

    models = json.loads(Path(args.models).read_text(encoding="utf-8"))
    print("Checking model sources...")
    for item in models["items"]:
        if not should_check(item, selection):
            continue
        if item["provider"] == "huggingface":
            try:
                exists = api.file_exists(item["repo_id"], item["filename"], repo_type="model")
                print(("✓" if exists else "✗"), item["id"], item["repo_id"], item["filename"])
                if not exists:
                    warnings.append(f"model:{item['id']}")
            except Exception as exc:
                print(f"⚠ {item['id']}: source check unavailable: {exc}")
                warnings.append(f"check:{item['id']}")
        elif item["provider"] == "civitai":
            print(f"• {item['id']}: Civitai source will be checked during download")

    nodes = json.loads(Path(args.custom_nodes).read_text(encoding="utf-8"))
    print("\nChecking custom-node repositories...")
    for item in nodes["items"]:
        if not item.get("install_by_default", False):
            continue
        rc = subprocess.run(
            ["git","ls-remote","--heads",item["repo"]],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        ).returncode
        print(("✓" if rc == 0 else "⚠"), item["id"], item["repo"])
        if rc != 0:
            warnings.append(f"node:{item['id']}")

    if warnings:
        print("\nSource preflight has warnings. Installation will still continue.")
        for w in warnings:
            print("  -", w)
    else:
        print("\nAll checked primary sources are reachable.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
