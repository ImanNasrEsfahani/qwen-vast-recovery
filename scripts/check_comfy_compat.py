#!/usr/bin/env python3
import argparse
from pathlib import Path

REQUIRED = [
    "TextEncodeQwenImageEditPlus",
    "PrimitiveStringMultiline",
    "StringConcatenate",
    "ModelSamplingAuraFlow",
    "CFGNorm",
]

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--comfy',required=True); a=ap.parse_args()
    root=Path(a.comfy)
    search_roots=[root/'comfy_extras', root/'nodes.py']
    corpus=[]
    if (root/'comfy_extras').exists():
        for p in (root/'comfy_extras').rglob('*.py'):
            try: corpus.append(p.read_text(encoding='utf-8',errors='ignore'))
            except: pass
    if (root/'nodes.py').exists(): corpus.append((root/'nodes.py').read_text(encoding='utf-8',errors='ignore'))
    text='\n'.join(corpus)
    missing=[x for x in REQUIRED if x not in text]
    if missing:
        print('✗ ComfyUI is too old/incompatible for this workflow pack.')
        print('Missing core nodes:', ', '.join(missing))
        print('Update ComfyUI, then rerun the installer.')
        return 1
    print('✓ ComfyUI core compatibility check passed')
    return 0
if __name__=='__main__': raise SystemExit(main())
