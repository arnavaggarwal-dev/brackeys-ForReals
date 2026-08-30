"""Build a graphify-shaped knowledge graph from a Godot project.

graphify's own AST pass has no GDScript parser - `.gd` is not in its
CODE_EXTENSIONS - so `/graphify` sees this repo as three markdown files and a
pile of sprites. This walks the .gd and .tscn sources instead and emits the same
node_link graph.json plus a GRAPH_REPORT.md, so `graphify query`, `graphify
path` and `graphify explain` keep working against a graph that matches reality.
"""

import json
import re
from collections import defaultdict
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "graphify-out"

AUTOLOADS = {"Style", "Data", "Sfx", "Game", "Trends", "Save"}

RE_CLASS = re.compile(r"^class_name\s+(\w+)", re.M)
RE_EXTENDS = re.compile(r"^extends\s+(\w+)", re.M)
RE_FUNC = re.compile(r"^(?:static\s+)?func\s+(\w+)", re.M)
RE_SIGNAL = re.compile(r"^signal\s+(\w+)", re.M)
RE_RES = re.compile(r'"(res://[^"]+)"')
RE_EXT_RESOURCE = re.compile(r'\[ext_resource[^\]]*path="(res://[^"]+)"')


def strip_strings(text: str) -> str:
    """Reference counting must not see class names quoted inside strings."""
    text = re.sub(r'"""[\s\S]*?"""', '""', text)
    text = re.sub(r'"[^"\n]*"', '""', text)
    return re.sub(r"^\s*#.*$", "", text, flags=re.M)


def scan() -> dict:
    files = {}
    for path in sorted(ROOT.rglob("*.gd")):
        rel = path.relative_to(ROOT).as_posix()
        if rel.startswith(("graphify-out/", "tools/")):
            continue
        raw = path.read_text(encoding="utf-8", errors="replace")
        code = strip_strings(raw)
        cls = RE_CLASS.search(raw)
        files[rel] = {
            "kind": "script",
            "class": cls.group(1) if cls else None,
            "extends": (RE_EXTENDS.search(raw).group(1) if RE_EXTENDS.search(raw) else None),
            "funcs": RE_FUNC.findall(raw),
            "signals": RE_SIGNAL.findall(raw),
            "resources": sorted(set(RE_RES.findall(raw))),
            "lines": raw.count("\n") + 1,
            "code": code,
        }
    for path in sorted(ROOT.rglob("*.tscn")):
        rel = path.relative_to(ROOT).as_posix()
        raw = path.read_text(encoding="utf-8", errors="replace")
        files[rel] = {
            "kind": "scene",
            "class": None,
            "extends": None,
            "funcs": [],
            "signals": [],
            "resources": sorted(set(RE_EXT_RESOURCE.findall(raw))),
            "lines": raw.count("\n") + 1,
            "code": "",
        }
    return files


def build(files: dict) -> tuple[list, list]:
    owner = {}
    for rel, info in files.items():
        if info["class"]:
            owner[info["class"]] = rel

    nodes = []
    for rel, info in files.items():
        label = info["class"] or Path(rel).stem
        if rel.endswith(".tscn"):
            label = Path(rel).stem + ".tscn"
        nodes.append({
            "id": rel,
            "label": label,
            "file_type": "code",
            "source_file": rel,
            "kind": info["kind"],
            "lines": info["lines"],
            "funcs": len(info["funcs"]),
            "signals": info["signals"],
        })

    seen = defaultdict(lambda: {"n": 0, "rel": ""})
    for rel, info in files.items():
        # a script referencing another class by name
        if info["code"]:
            for cls, target in owner.items():
                if target == rel:
                    continue
                hits = len(re.findall(r"\b%s\b" % re.escape(cls), info["code"]))
                if hits:
                    key = (rel, target)
                    seen[key]["n"] += hits
                    seen[key]["rel"] = "references"
            for name in AUTOLOADS:
                hits = len(re.findall(r"\b%s\." % name, info["code"]))
                if hits:
                    target = "scripts/%s.gd" % name.lower()
                    if target in files and target != rel:
                        key = (rel, target)
                        seen[key]["n"] += hits
                        seen[key]["rel"] = "uses_autoload"
            if info["extends"] and info["extends"] in owner:
                key = (rel, owner[info["extends"]])
                seen[key]["rel"] = "extends"
                seen[key]["n"] = max(seen[key]["n"], 1)
        # a file naming a resource path
        for res in info["resources"]:
            target = res.replace("res://", "")
            if target in files and target != rel:
                key = (rel, target)
                seen[key]["n"] += 1
                seen[key]["rel"] = "instantiates" if target.endswith(".tscn") else "loads"

    links = []
    for (src, dst), d in sorted(seen.items()):
        links.append({
            "source": src,
            "target": dst,
            "relation": d["rel"],
            "confidence": "EXTRACTED",
            "confidence_score": 1.0,
            "weight": float(d["n"]),
        })
    return nodes, links


def report(nodes: list, links: list) -> str:
    deg = defaultdict(int)
    fan_out = defaultdict(int)
    fan_in = defaultdict(int)
    for e in links:
        deg[e["source"]] += 1
        deg[e["target"]] += 1
        fan_out[e["source"]] += 1
        fan_in[e["target"]] += 1
    by_id = {n["id"]: n for n in nodes}

    gods = sorted(nodes, key=lambda n: -deg[n["id"]])[:10]
    biggest = sorted((n for n in nodes if n["kind"] == "script"), key=lambda n: -n["lines"])[:10]
    scenes = [n for n in nodes if n["kind"] == "scene"]
    orphans = [n for n in nodes if deg[n["id"]] == 0]

    out = ["# Graph Report - ForReals  (%s)" % date.today().isoformat(), ""]
    out += ["Built by `tools/gdgraph.py`. graphify's AST pass has no GDScript",
            "parser, so this walks the `.gd` and `.tscn` sources directly and writes",
            "the same `graph.json` shape.", ""]
    out += ["## Summary",
            "- %d nodes · %d edges" % (len(nodes), len(links)),
            "- %d scripts · %d scenes" % (len(nodes) - len(scenes), len(scenes)),
            "- %d lines of GDScript" % sum(n["lines"] for n in nodes if n["kind"] == "script"),
            "- Extraction: 100% EXTRACTED (no inference, no LLM)", ""]

    out += ["## God Nodes (most connected)"]
    for i, n in enumerate(gods, 1):
        out.append("%d. `%s` - %d edges (%d out, %d in)" % (
            i, n["label"], deg[n["id"]], fan_out[n["id"]], fan_in[n["id"]]))
    out.append("")

    out += ["## Biggest Files (refactor pressure)"]
    for n in biggest:
        out.append("- `%s` - %d lines, %d functions" % (n["source_file"], n["lines"], n["funcs"]))
    out.append("")

    out += ["## Scenes"]
    for n in sorted(scenes, key=lambda n: n["id"]):
        users = [by_id[e["source"]]["label"] for e in links if e["target"] == n["id"]]
        out.append("- `%s` - instanced by %s" % (
            n["source_file"], ", ".join(sorted(set(users))) if users else "nothing (entry point)"))
    out.append("")

    if orphans:
        out += ["## Unreferenced"]
        for n in orphans:
            out.append("- `%s`" % n["source_file"])
        out.append("")
    return "\n".join(out)


def main() -> None:
    files = scan()
    nodes, links = build(files)
    OUT.mkdir(exist_ok=True)
    (OUT / "graph.json").write_text(json.dumps({
        "directed": False, "multigraph": False, "graph": {},
        "nodes": nodes, "links": links,
    }, indent=2), encoding="utf-8")
    (OUT / "GRAPH_REPORT.md").write_text(report(nodes, links), encoding="utf-8")
    print("%d nodes, %d edges" % (len(nodes), len(links)))


if __name__ == "__main__":
    main()
