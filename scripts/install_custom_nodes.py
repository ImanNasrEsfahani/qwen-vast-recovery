#!/usr/bin/env python3
import argparse, json, subprocess, sys
from pathlib import Path

def run(cmd, cwd=None, check=False):
    print("+", " ".join(str(x) for x in cmd))
    return subprocess.run(cmd, cwd=cwd, check=check)

def install_one(item, custom_root: Path):
    dest = custom_root / item["directory"]

    if dest.exists() and not (dest / ".git").exists():
        raise RuntimeError(f"{dest} exists but is not a git checkout; not deleting user data")

    if (dest / ".git").exists():
        rc = run(["git","-C",str(dest),"pull","--ff-only"]).returncode
        if rc != 0:
            print(f"⚠ {item['id']}: git pull failed; keeping existing checkout")
    else:
        rc = run(["git","clone","--depth","1",item["repo"],str(dest)]).returncode
        if rc != 0:
            raise RuntimeError("git clone failed")

    req = dest / "requirements.txt"
    if item.get("install_requirements") and req.exists():
        rc = run([sys.executable,"-m","pip","install","-r",str(req)]).returncode
        if rc != 0:
            raise RuntimeError("requirements installation failed")

    install_py = dest / "install.py"
    if item.get("run_install_py") and install_py.exists():
        rc = run([sys.executable,str(install_py)], cwd=dest).returncode
        if rc != 0:
            raise RuntimeError("install.py failed")

    extra_pip_packages = item.get("extra_pip_packages", [])
    if extra_pip_packages:
        rc = run([sys.executable,"-m","pip","install",*extra_pip_packages]).returncode
        if rc != 0:
            raise RuntimeError("extra pip package installation failed")

def install_items(data, comfy: Path):
    custom_root = comfy / "custom_nodes"
    custom_root.mkdir(parents=True, exist_ok=True)
    required_failures = []
    optional_failures = []

    for item in data["items"]:
        if not item.get("install_by_default", False):
            continue
        print(f"\n↓ {item['name']} [{item['id']}]")
        try:
            install_one(item, custom_root)
            print(f"✓ {item['id']}")
        except Exception as exc:
            if item.get("required", False):
                required_failures.append((item["id"], str(exc)))
                print(f"✗ REQUIRED NODE FAILED: {item['id']} — continuing")
            else:
                optional_failures.append((item["id"], str(exc)))
                print(f"⚠ OPTIONAL NODE FAILED: {item['id']} — continuing")

    print("\n=== CUSTOM NODE SUMMARY ===")
    if optional_failures:
        for item_id, msg in optional_failures:
            print(f"  ⚠ {item_id}: {msg}")
    if required_failures:
        for item_id, msg in required_failures:
            print(f"  ✗ {item_id}: {msg}")
    return 1 if required_failures else 0

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--comfy", required=True)
    args = ap.parse_args()
    data = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    raise SystemExit(install_items(data, Path(args.comfy)))

if __name__ == "__main__":
    main()
