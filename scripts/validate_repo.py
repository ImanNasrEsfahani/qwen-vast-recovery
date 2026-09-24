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
