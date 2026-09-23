#!/usr/bin/env python3
import argparse, json, sys
from pathlib import Path

def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--models", required=True)
    ap.add_argument("--workflows", required=True)
    ap.add_argument("--custom-nodes", required=True)
    ap.add_argument("--comfy", required=True)
    args = ap.parse_args()

    comfy = Path(args.comfy)
    failures = []

    models = load(args.models)
    for item in models["items"]:
        if not item.get("install_by_default", False):
            continue
        p = comfy / item["target"]
        good = p.exists() and p.stat().st_size > 1_000_000
        print(("✓" if good else "✗"), item["id"], p)
        if not good:
            failures.append(f"model:{item['id']}")

    workflows = load(args.workflows)
    wf_dir = comfy / workflows.get("install_directory", "user/default/workflows/qwen2511")
    for item in workflows["items"]:
        if not item.get("install_by_default", False):
            continue
        p = wf_dir / Path(item["path"]).name
        good = p.exists() and p.stat().st_size > 100
        print(("✓" if good else "✗"), item["id"], p)
        if not good:
            failures.append(f"workflow:{item['id']}")

    nodes = load(args.custom_nodes)
    for item in nodes["items"]:
        if not item.get("install_by_default", False):
            continue
        p = comfy / "custom_nodes" / item["directory"]
        good = p.exists()
        print(("✓" if good else "✗"), item["id"], p)
        if not good:
            failures.append(f"node:{item['id']}")

    if failures:
        print("\nFAILED:", ", ".join(failures))
        raise SystemExit(1)
    print("\nAll required/default components are present.")

if __name__ == "__main__":
    main()
