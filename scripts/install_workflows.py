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

    for item in data["items"]:
        if not item.get("install_by_default", False):
            continue
        src = repo / item["path"]
        if not src.exists():
            raise SystemExit(f"ERROR: workflow source missing: {src}")
        dst = target_dir / src.name
        shutil.copy2(src, dst)
        print(f"✓ {item['id']}: {dst.name}")

if __name__ == "__main__":
    main()
