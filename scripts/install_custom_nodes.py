#!/usr/bin/env python3
import argparse, hashlib, json, subprocess, sys, time, urllib.request
from pathlib import Path

def run(cmd, cwd=None, quiet=False):
    print('+', ' '.join(str(x) for x in cmd))
    kwargs = {}
    if quiet:
        kwargs.update(stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return subprocess.run(cmd, cwd=cwd, **kwargs)

def sha256_file(path: Path, chunk=8*1024*1024):
    h=hashlib.sha256()
    with path.open('rb') as f:
        while True:
            b=f.read(chunk)
            if not b: break
            h.update(b)
    return h.hexdigest()

def asset_valid(asset, comfy: Path):
    p=comfy/asset['path']
    if not p.exists() or p.stat().st_size < int(asset.get('min_size',1)):
        return False
    expected=asset.get('sha256')
    if expected:
        actual=sha256_file(p)
        if actual.lower()!=expected.lower():
            print(f'⚠ asset hash mismatch: {p}')
            return False
    return True

def download_asset(asset, comfy: Path, retries=3):
    p=comfy/asset['path']; p.parent.mkdir(parents=True,exist_ok=True)
    url=asset.get('url')
    if not url: raise RuntimeError(f'missing required asset and no fallback URL: {asset["path"]}')
    tmp=p.with_suffix(p.suffix+'.part')
    for attempt in range(1,retries+1):
        try:
            print(f'↓ asset {asset["path"]} attempt {attempt}/{retries}')
            urllib.request.urlretrieve(url,tmp)
            tmp.replace(p)
            if not asset_valid(asset,comfy):
                p.unlink(missing_ok=True)
                raise RuntimeError('downloaded asset failed size/hash verification')
            print(f'✓ asset: {p}')
            return
        except Exception as e:
            tmp.unlink(missing_ok=True)
            if attempt==retries: raise
            print('  retry after error:',e); time.sleep(attempt*2)

def ensure_assets(item, comfy: Path):
    for asset in item.get('required_assets',[]):
        if asset_valid(asset,comfy):
            print(f'✓ asset already valid: {asset["path"]}')
        else:
            download_asset(asset,comfy)

def checkout_repo(item, dest: Path):
    ref=item.get('ref')
    if dest.exists() and not (dest/'.git').exists():
        raise RuntimeError(f'{dest} exists but is not a git checkout; not deleting user data')
    if not (dest/'.git').exists():
        rc=run(['git','clone','--depth','1',item['repo'],str(dest)]).returncode
        if rc!=0: raise RuntimeError('git clone failed')
    if ref:
        rc=run(['git','-C',str(dest),'fetch','--depth','1','origin',ref]).returncode
        if rc!=0: raise RuntimeError(f'git fetch pinned ref failed: {ref}')
        rc=run(['git','-C',str(dest),'checkout','--detach',ref]).returncode
        if rc!=0: raise RuntimeError(f'git checkout pinned ref failed: {ref}')
        head=subprocess.check_output(['git','-C',str(dest),'rev-parse','HEAD'],text=True).strip()
        if head!=ref: raise RuntimeError(f'pinned ref mismatch: expected {ref}, got {head}')
        print(f'✓ pinned ref: {head}')
    else:
        rc=run(['git','-C',str(dest),'pull','--ff-only']).returncode
        if rc!=0: print(f'⚠ {item["id"]}: git pull failed; keeping existing checkout')

def load_selection(path):
    if not path:
        return {}
    p=Path(path)
    if not p.exists():
        return {}
    return json.loads(p.read_text(encoding='utf-8'))

def reactor_runtime_healthy(require_cuda):
    code = (
        "import onnxruntime as ort; "
        "p=ort.get_available_providers(); "
        "print('onnxruntime', ort.__version__, p); "
        + ("raise SystemExit(0 if 'CUDAExecutionProvider' in p else 2)"
           if require_cuda else "raise SystemExit(0)")
    )
    return run([sys.executable,'-c',code]).returncode == 0

def prepare_reactor_runtime(selection):
    # ReActor's pinned installer still imports pkg_resources. Setuptools 82+
    # removed it, so keep the last compatible line for this isolated ComfyUI env.
    if run([sys.executable,'-m','pip','install','-q','setuptools==81.0.0']).returncode!=0:
        raise RuntimeError('could not install ReActor setuptools compatibility pin')

    req = selection.get('reactor',{}).get('onnxruntime_requirement')
    cuda_available = bool(selection.get('hardware',{}).get('cuda_available'))
    if not req:
        req = 'onnxruntime-gpu>=1.27,<2' if cuda_available else 'onnxruntime'

    if reactor_runtime_healthy(cuda_available):
        print('✓ existing ONNX Runtime is healthy for ReActor')
        return

    print(f'Preparing ReActor runtime: {req}')
    run([sys.executable,'-m','pip','uninstall','-y','onnxruntime','onnxruntime-gpu'], quiet=True)
    if run([sys.executable,'-m','pip','install','-U',req]).returncode!=0:
        raise RuntimeError(f'failed to install {req}')
    if not reactor_runtime_healthy(cuda_available):
        raise RuntimeError(f'ONNX Runtime installed but CUDA provider is unavailable ({req})')
    print(f'✓ ReActor runtime ready: {req}')

def install_one(item, custom_root: Path, comfy: Path, selection):
    dest=custom_root/item['directory']
    checkout_repo(item,dest)

    if item.get('id') == 'reactor':
        prepare_reactor_runtime(selection)

    req=dest/'requirements.txt'
    if item.get('install_requirements') and req.exists():
        if run([sys.executable,'-m','pip','install','-r',str(req)]).returncode!=0:
            raise RuntimeError('requirements installation failed')

    install_py=dest/'install.py'
    if item.get('run_install_py'):
        if not install_py.exists(): raise RuntimeError('manifest requires install.py but it is missing')
        if run([sys.executable,str(install_py)],cwd=dest).returncode!=0:
            raise RuntimeError('install.py failed')

    ensure_assets(item,comfy)

def install_items(data, comfy: Path, selection):
    custom_root=comfy/'custom_nodes'; custom_root.mkdir(parents=True,exist_ok=True)
    required_failures=[]; optional_failures=[]
    for item in data['items']:
        if not item.get('install_by_default',False): continue
        print(f'\n↓ {item["name"]} [{item["id"]}]')
        try:
            install_one(item,custom_root,comfy,selection)
            print(f'✓ {item["id"]}')
        except Exception as exc:
            bucket=required_failures if item.get('required',False) else optional_failures
            bucket.append((item['id'],str(exc)))
            print(('✗ REQUIRED NODE FAILED' if item.get('required',False) else '⚠ OPTIONAL NODE FAILED')+f': {item["id"]} — continuing')
    print('\n=== CUSTOM NODE SUMMARY ===')
    for i,m in optional_failures: print(f'  ⚠ {i}: {m}')
    for i,m in required_failures: print(f'  ✗ {i}: {m}')
    return 1 if required_failures else 0

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--manifest',required=True)
    ap.add_argument('--comfy',required=True)
    ap.add_argument('--selection')
    a=ap.parse_args()
    data=json.loads(Path(a.manifest).read_text(encoding='utf-8'))
    selection=load_selection(a.selection)
    raise SystemExit(install_items(data,Path(a.comfy),selection))

if __name__=='__main__':
    main()
