#!/usr/bin/env python3
import json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def load(rel):
    return json.loads((ROOT / rel).read_text(encoding="utf-8"))

def validate_workflow(path: Path):
    data = json.loads(path.read_text(encoding="utf-8"))
    node_ids = {n["id"] for n in data.get("nodes", [])}
    links = data.get("links", [])
    link_ids = {l[0] for l in links}

    if len(node_ids) != len(data.get("nodes", [])):
        raise ValueError("duplicate node ids")
    if len(link_ids) != len(links):
        raise ValueError("duplicate link ids")

    for link in links:
        if link[1] not in node_ids or link[3] not in node_ids:
            raise ValueError(f"link {link[0]} references missing node")

    for node in data.get("nodes", []):
        for inp in node.get("inputs", []):
            lid = inp.get("link")
            if lid is not None and lid not in link_ids:
                raise ValueError(f"node {node['id']} input references missing link {lid}")
        for out in node.get("outputs", []):
            for lid in out.get("links") or []:
                if lid not in link_ids:
                    raise ValueError(f"node {node['id']} output references missing link {lid}")

    prompts = [n for n in data.get("nodes", []) if n.get("title") == "Positive Prompt"]
    notes = [n for n in data.get("nodes", []) if n.get("type") == "MarkdownNote"]
    if not prompts:
        raise ValueError("missing Positive Prompt node")
    if not notes:
        raise ValueError("missing MarkdownNote guide")

    system_prompt_nodes = [n for n in data.get("nodes", []) if n.get("title") == "SYSTEM PROMPT — DO NOT EDIT"]
    user_prompt_nodes = [n for n in data.get("nodes", []) if n.get("title") == "USER PROMPT — edit this"]
    system_negative_nodes = [n for n in data.get("nodes", []) if n.get("title") == "SYSTEM NEGATIVE — DO NOT EDIT"]
    user_negative_nodes = [n for n in data.get("nodes", []) if n.get("title") == "USER NEGATIVE — optional"]
    if system_prompt_nodes and not user_prompt_nodes:
        raise ValueError("missing USER PROMPT node")
    if system_negative_nodes and not user_negative_nodes:
        raise ValueError("missing USER NEGATIVE node")


    # Current native ComfyUI schema checks for nodes this repository constructs manually.
    expected_qwen_inputs = ["clip", "vae", "image1", "image2", "image3", "prompt"]
    for node in [n for n in data.get("nodes", []) if n.get("type") == "TextEncodeQwenImageEditPlus"]:
        names = [x.get("name") for x in node.get("inputs", [])]
        present_expected = [x for x in expected_qwen_inputs if x in names]
        if names[:len(present_expected)] != present_expected:
            raise ValueError(f"TextEncodeQwenImageEditPlus input order is not current-schema compatible: {names}")

    for node in [n for n in data.get("nodes", []) if n.get("type") == "StringConcatenate"]:
        if len(node.get("widgets_values", [])) < 3:
            raise ValueError("StringConcatenate must serialize string_a, string_b, delimiter widget state")

    for node in [n for n in data.get("nodes", []) if n.get("type") == "ReActorFaceSwap"]:
        if len(node.get("widgets_values", [])) != 11:
            raise ValueError("ReActorFaceSwap widget schema must have 11 values")
        names = [x.get("name") for x in node.get("inputs", [])]
        if names[:4] != ["input_image", "source_image", "face_model", "face_boost"]:
            raise ValueError(f"ReActorFaceSwap input schema mismatch: {names}")

    # Generic Impact FaceDetailer is intentionally excluded from the default Qwen edit chain.
    forbidden_impact = {"FaceDetailerPipe", "BasicPipeToDetailerPipe", "ToBasicPipe", "UltralyticsDetectorProvider"}
    present_forbidden = sorted({n.get("type") for n in data.get("nodes", []) if n.get("type") in forbidden_impact})
    if present_forbidden:
        raise ValueError(f"Impact FaceDetailer nodes are not allowed in production v8 workflows: {present_forbidden}")


def main():
    errors = []

    for manifest_name in ["manifests/models.json","manifests/custom-nodes.json","manifests/workflows.json"]:
        try:
            load(manifest_name)
            print("✓", manifest_name)
        except Exception as e:
            errors.append(f"{manifest_name}: {e}")

    wf_manifest = load("manifests/workflows.json")
    seen = set()
    for item in wf_manifest["items"]:
        if item["id"] in seen:
            errors.append(f"duplicate workflow id: {item['id']}")
        seen.add(item["id"])
        p = ROOT / item["path"]
        if not p.exists():
            errors.append(f"missing workflow file: {item['path']}")
            continue
        try:
            validate_workflow(p)
            print("✓", item["path"])
        except Exception as e:
            errors.append(f"{item['path']}: {e}")

    if errors:
        print("\nValidation errors:")
        for e in errors:
            print("-", e)
        raise SystemExit(1)

    print("\nRepository validation passed.")

if __name__ == "__main__":
    main()
