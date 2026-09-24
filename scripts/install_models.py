#!/usr/bin/env python3
import argparse, hashlib, json, os, shutil, subprocess, time
from pathlib import Path
from huggingface_hub import hf_hub_download

MIN_FILE_SIZE = 1_000_000

def valid_file(path: Path) -> bool:
    return path.exists() and path.stat().st_size > MIN_FILE_SIZE

def sha256_file(path: Path, chunk=16*1024*1024):
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()

def verify_hash(item, dest: Path):
    expected = item.get("expected_sha256")
    if not expected or not valid_file(dest):
        return True
    # Hashing 20+ GB files is expensive; opt-in at runtime.
    if os.getenv("QVR_VERIFY_SHA256", "0") != "1":
        return True
    actual = sha256_file(dest)
    if actual.lower() != expected.lower():
        raise RuntimeError(f"SHA256 mismatch for {item['id']}: expected {expected}, got {actual}")
    return True

def hf_once(repo_id, filename, stage: Path):
    return Path(hf_hub_download(
        repo_id=repo_id,
        filename=filename,
        local_dir=stage,
    ))

def download_hf_source(source, item, comfy: Path, stage: Path, retries=3):
    dest = comfy / item["target"]
    dest.parent.mkdir(parents=True, exist_ok=True)
    last = None
    for attempt in range(1, retries+1):
        try:
            src = hf_once(source["repo_id"], source["filename"], stage)
            if src.resolve() != dest.resolve():
                shutil.move(str(src), str(dest))
            if not valid_file(dest):
                raise RuntimeError(f"downloaded file is missing or too small: {dest}")
            verify_hash(item, dest)
            return
        except Exception as exc:
            last = exc
            print(f"  attempt {attempt}/{retries} failed: {exc}")
            if attempt < retries:
                time.sleep(min(3*attempt, 8))
    raise RuntimeError(str(last))

def download_civitai_source(source, item, comfy: Path):
    dest = comfy / item["target"]
    dest.parent.mkdir(parents=True, exist_ok=True)
    url = f"https://civitai.com/api/download/models/{source['model_version_id']}"
    token_name = source.get("env_token")
    token = os.getenv(token_name, "") if token_name else ""
    if token:
        url += f"?token={token}"
    cmd = [
        "curl","-fL","--retry","5","--retry-all-errors","--retry-delay","3",
        "--connect-timeout","30","-C","-","-o",str(dest),url
    ]
    rc = subprocess.run(cmd).returncode
    if rc != 0 or not valid_file(dest):
        dest.unlink(missing_ok=True)
        raise RuntimeError(f"Civitai download failed for modelVersionId={source['model_version_id']}")
    verify_hash(item, dest)

def source_from_item(item):
    src = {"provider": item["provider"]}
    for key in ("repo_id","filename","model_version_id","env_token"):
        if key in item:
            src[key] = item[key]
    return src

def install_one(item, comfy: Path, stage: Path):
    dest = comfy / item["target"]
    if valid_file(dest):
        try:
            verify_hash(item, dest)
            print(f"✓ {item['id']}: already installed")
            return True, "already-installed"
        except Exception:
            print(f"! {item['id']}: existing file failed hash check; re-downloading")
            dest.unlink(missing_ok=True)

    sources = [source_from_item(item)] + item.get("fallbacks", [])
    errors = []
    for idx, source in enumerate(sources, 1):
        try:
            provider = source["provider"]
            print(f"  source {idx}/{len(sources)}: {provider}")
            if provider == "huggingface":
                download_hf_source(source, item, comfy, stage)
            elif provider == "civitai":
                download_civitai_source(source, item, comfy)
            else:
                raise RuntimeError(f"unsupported provider: {provider}")
            print(f"✓ {item['id']}: {dest.name}")
            return True, provider
        except Exception as exc:
            errors.append(f"{source.get('provider')}: {exc}")
            print(f"  source failed: {errors[-1]}")
            dest.unlink(missing_ok=True)

    return False, "; ".join(errors)

def install_items(data, comfy: Path):
    stage = comfy / ".qwen2511-downloads"
    stage.mkdir(parents=True, exist_ok=True)

    required_failures = []
    optional_failures = []
    successes = []

    for item in data["items"]:
        if not item.get("install_by_default", False):
            continue
        print(f"\n↓ {item['name']} [{item['id']}]")
        try:
            ok, detail = install_one(item, comfy, stage)
        except Exception as exc:
            ok, detail = False, str(exc)
        if ok:
            successes.append(item["id"])
        elif item.get("required", False):
            required_failures.append((item["id"], detail))
            print(f"✗ REQUIRED FAILED: {item['id']} — continuing with remaining items")
        else:
            optional_failures.append((item["id"], detail))
            print(f"⚠ OPTIONAL FAILED: {item['id']} — continuing")

    print("\n=== MODEL INSTALL SUMMARY ===")
    print(f"Installed/present: {len(successes)}")
    if optional_failures:
        print("Optional warnings:")
        for item_id, msg in optional_failures:
            print(f"  - {item_id}: {msg}")
    if required_failures:
        print("Required failures:")
        for item_id, msg in required_failures:
            print(f"  - {item_id}: {msg}")

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
