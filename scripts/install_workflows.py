#!/usr/bin/env python3
import argparse, json, shutil
from pathlib import Path

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--repo-root", required=True)
    ap.add_argument("--comfy", required=True)
    args = ap.parse_args()

    repo = Path(args.repo_root)
    comfy = Path(args.comfy)
    data = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    target_dir = comfy / data.get("install_directory", "user/default/workflows/qwen2511")
    target_dir.mkdir(parents=True, exist_ok=True)

    required_failures = []
    optional_failures = []

    for item in data["items"]:
        if not item.get("install_by_default", False):
            continue
        try:
            src = repo / item["path"]
            if not src.exists():
                raise FileNotFoundError(f"workflow source missing: {src}")
            # Parse first so corrupt JSON does not get installed.
            json.loads(src.read_text(encoding="utf-8"))
            dst = target_dir / src.name
            shutil.copy2(src, dst)
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
