#!/usr/bin/env python3
import argparse, json, subprocess, sys
from pathlib import Path

def run(cmd, cwd=None, check=True):
    print("+", " ".join(str(x) for x in cmd))
    return subprocess.run(cmd, cwd=cwd, check=check)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--comfy", required=True)
    args = ap.parse_args()

    comfy = Path(args.comfy)
    custom_root = comfy / "custom_nodes"
    custom_root.mkdir(parents=True, exist_ok=True)
    data = json.loads(Path(args.manifest).read_text(encoding="utf-8"))

    for item in data["items"]:
        if not item.get("install_by_default", False):
            continue
        dest = custom_root / item["directory"]
        if (dest / ".git").exists():
            run(["git","-C",str(dest),"pull","--ff-only"], check=False)
        else:
            run(["git","clone","--depth","1",item["repo"],str(dest)])
        req = dest / "requirements.txt"
        if item.get("install_requirements") and req.exists():
            run([sys.executable,"-m","pip","install","-q","-r",str(req)])
        install_py = dest / "install.py"
        if item.get("run_install_py") and install_py.exists():
            run([sys.executable,str(install_py)], cwd=dest, check=False)
        print(f"✓ {item['id']}")

if __name__ == "__main__":
    main()
