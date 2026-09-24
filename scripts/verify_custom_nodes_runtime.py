#!/usr/bin/env python3
import argparse, hashlib, importlib.util, json, sys, traceback
from pathlib import Path


def sha256_file(path: Path, chunk=8*1024*1024):
    h=hashlib.sha256()
    with path.open('rb') as f:
        while True:
            b=f.read(chunk)
            if not b: break
            h.update(b)
    return h.hexdigest()


def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--comfy',required=True); ap.add_argument('--manifest',required=True); a=ap.parse_args()
    comfy=Path(a.comfy).resolve(); data=json.loads(Path(a.manifest).read_text(encoding='utf-8'))
    failures=[]
    sys.path.insert(0,str(comfy))
    for item in data['items']:
        if not item.get('install_by_default',False): continue
        dest=comfy/'custom_nodes'/item['directory']
        print(f'\nRuntime probe: {item["id"]}')
        if not dest.exists():
            failures.append(f'{item["id"]}: directory missing'); continue
        for asset in item.get('required_assets',[]):
            p=comfy/asset['path']; ok=p.exists() and p.stat().st_size>=int(asset.get('min_size',1))
            if ok and asset.get('sha256'): ok=sha256_file(p).lower()==asset['sha256'].lower()
            print(('✓' if ok else '✗'),p)
            if not ok: failures.append(f'{item["id"]}: invalid asset {asset["path"]}')
        if item['id']=='reactor':
            try:
                name='qvr_reactor_probe'
                spec=importlib.util.spec_from_file_location(name,dest/'__init__.py',submodule_search_locations=[str(dest)])
                mod=importlib.util.module_from_spec(spec); sys.modules[name]=mod; spec.loader.exec_module(mod)
                mappings=getattr(mod,'NODE_CLASS_MAPPINGS',{})
                if 'ReActorFaceSwap' not in mappings:
                    raise RuntimeError('ReActorFaceSwap not registered in NODE_CLASS_MAPPINGS')
                cls=mappings['ReActorFaceSwap']
                required=list(cls.INPUT_TYPES().get('required',{}).keys())
                expected=['enabled','input_image','swap_model','facedetection','face_restore_model','face_restore_visibility','codeformer_weight','detect_gender_input','detect_gender_source','input_faces_index','source_faces_index','console_log_level']
                if required!=expected:
                    raise RuntimeError(f'ReActor schema drift: {required}')
                print('✓ ReActorFaceSwap imports and current schema matches workflow pack')
            except Exception as e:
                print('✗ ReActor runtime import/registration failed:',e)
                traceback.print_exc()
                failures.append(f'reactor runtime: {e}')
    if failures:
        print('\nRuntime verification failures:')
        for x in failures: print('  ✗',x)
        return 1
    print('\n✓ Custom-node runtime verification passed')
    return 0
if __name__=='__main__': raise SystemExit(main())
