#!/usr/bin/env python3
import argparse, json, os, shutil, subprocess
from pathlib import Path
from huggingface_hub import hf_hub_download

def valid_file(path: Path) -> bool:
    return path.exists() and path.stat().st_size > 1_000_000

def download_hf(item, comfy: Path, stage: Path):
    dest = comfy / item["target"]
    if valid_file(dest):
        print(f"✓ {item['id']}: already installed")
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    src = Path(hf_hub_download(
        repo_id=item["repo_id"],
        filename=item["filename"],
        local_dir=stage
    ))
    shutil.move(str(src), str(dest))
    print(f"✓ {item['id']}: {dest.name}")

def download_civitai(item, comfy: Path):
    dest = comfy / item["target"]
    if valid_file(dest):
        print(f"✓ {item['id']}: already installed")
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    url = f"https://civitai.com/api/download/models/{item['model_version_id']}"
    token_name = item.get("env_token")
    token = os.getenv(token_name, "") if token_name else ""
    if token:
        url += f"?token={token}"
    cmd = ["curl","-fL","--retry","5","--retry-delay","3","--connect-timeout","30","-C","-","-o",str(dest),url]
    rc = subprocess.run(cmd).returncode
    if rc != 0 or not valid_file(dest):
        dest.unlink(missing_ok=True)
        raise SystemExit(f"ERROR: failed to download {item['id']}. Set {token_name} if authentication is required.")
    print(f"✓ {item['id']}: {dest.name}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--comfy", required=True)
    args = ap.parse_args()

    comfy = Path(args.comfy)
    data = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    stage = comfy / ".qwen2511-downloads"
    stage.mkdir(parents=True, exist_ok=True)

    for item in data["items"]:
        if not item.get("install_by_default", False):
            continue
        provider = item["provider"]
        print(f"↓ {item['name']}")
        if provider == "huggingface":
            download_hf(item, comfy, stage)
        elif provider == "civitai":
            download_civitai(item, comfy)
        else:
            raise SystemExit(f"ERROR: unsupported provider: {provider}")

if __name__ == "__main__":
    main()
