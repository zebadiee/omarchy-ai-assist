#!/usr/bin/env bash
# Entropy collapse helper for Omarchy modules.
# Scans key binaries, maps inter-module loops, extracts verbs, and
# emits a consolidated .entropy.json plus a human-readable report.

set -euo pipefail

MODULE_DIR_DEFAULT="$HOME/.local/bin"
MODULE_GLOB_DEFAULT="om-*"

MODULE_DIR="${MODULE_DIR:-$MODULE_DIR_DEFAULT}"
MODULE_GLOB="${MODULE_GLOB:-$MODULE_GLOB_DEFAULT}"
OUTPUT_JSON="${OUTPUT_JSON:-.entropy.json}"
OUTPUT_REPORT="${OUTPUT_REPORT:-entropy.loops.txt}"
RETIRED_DEFAULT=("om-aks-verify" "om-3lh-verify")

mapfile -t MODULE_PATHS < <(find "$MODULE_DIR" -maxdepth 1 -type f -name "$MODULE_GLOB" ! -name "*.bak" | sort)

if [[ ${#MODULE_PATHS[@]} -eq 0 ]]; then
  echo "[reduce] no modules matched in $MODULE_DIR (glob: $MODULE_GLOB)" >&2
  exit 2
fi

MODULE_LIST=$(printf '%s\n' "${MODULE_PATHS[@]}")
if [[ -n "${RETIRED+x}" && -n "${RETIRED}" ]]; then
  RETIRED_ARR=()
  for item in ${RETIRED}; do
    RETIRED_ARR+=("$item")
  done
else
  RETIRED_ARR=("${RETIRED_DEFAULT[@]}")
fi
RETIRED_LIST=$(printf '%s\n' "${RETIRED_ARR[@]}")

OUT_JSON="$OUTPUT_JSON" OUT_REPORT="$OUTPUT_REPORT" MODULE_BASE="$MODULE_DIR" \
  MODULE_LIST="$MODULE_LIST" RETIRED_LIST="$RETIRED_LIST" \
  python3 <<'PY'
import os
import re
import json
import sys
from collections import Counter, defaultdict

out_json = os.environ["OUT_JSON"]
out_report = os.environ["OUT_REPORT"]
module_dir = os.environ["MODULE_BASE"]
module_paths = [line for line in os.environ.get("MODULE_LIST", "").splitlines() if line.strip()]
retired = [item for item in os.environ.get("RETIRED_LIST", "").splitlines() if item]

if not module_paths:
    print("[reduce] No module paths provided", file=sys.stderr)
    sys.exit(3)

name_from_path = {path: os.path.basename(path) for path in module_paths}

verb_candidates = [
    "route", "budget", "enforce", "seed", "ensure", "verify",
    "monitor", "guard", "report", "hydrate", "cache", "bridge", "sync"
]

fallback_verbs = {
    "om-agent": "route",
    "om-preflight": "budget",
    "om-vbh-prepend": "signal",
    "om-vbh-verify": "enforce",
    "om-obs-set": "seed",
    "om-obs-ensure": "seed",
    "om-sem-cache": "cache",
    "om-guard": "guard",
    "om-agent-health": "monitor",
    "om-usage": "report",
    "om-shra": "hash",
}

module_info = {}
pattern = re.compile(r"\bom-[a-z0-9\-]+")

def extract_intro_comments(text):
    intro = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("#"):
            intro.append(stripped.lstrip("#").strip())
            continue
        break
    return intro

def pick_verb(name, intro_lines):
    for line in intro_lines:
        lower = line.lower()
        if "verb:" in lower:
            return line.split(":", 1)[1].strip().split()[0]
    for cand in verb_candidates:
        for line in intro_lines:
            if cand in line.lower():
                return cand
    return fallback_verbs.get(name, "support")

adjacency = defaultdict(dict)
call_counts = defaultdict(Counter)

for path in module_paths:
    name = name_from_path[path]
    try:
        with open(path, "r", encoding="utf-8") as handle:
            text = handle.read()
    except OSError as exc:
        print(f"[reduce] warn: unable to read {path}: {exc}", file=sys.stderr)
        continue

    intro_lines = extract_intro_comments(text)
    verb = pick_verb(name, intro_lines)

    calls = pattern.findall(text)
    counts = Counter([call for call in calls if call != name])
    call_counts[name].update(counts)
    adjacency[name].update(counts)

    module_info[name] = {
        "path": path,
        "intro": intro_lines[:8],
        "verb": verb,
        "calls": sorted(counts.keys()),
    }

nodes = list(module_info.keys())

index = {}
lowlink = {}
stack = []
onstack = set()
sccs = []
idx = 0

def strongconnect(v):
    global idx
    index[v] = idx
    lowlink[v] = idx
    idx += 1
    stack.append(v)
    onstack.add(v)

    for w in adjacency.get(v, {}):
        if w not in module_info:
            continue
        if w not in index:
            strongconnect(w)
            lowlink[v] = min(lowlink[v], lowlink[w])
        elif w in onstack:
            lowlink[v] = min(lowlink[v], index[w])

    if lowlink[v] == index[v]:
        comp = []
        while True:
            w = stack.pop()
            onstack.remove(w)
            comp.append(w)
            if w == v:
                break
        sccs.append(sorted(comp))

for v in nodes:
    if v not in index:
        strongconnect(v)

loop_components = [comp for comp in sccs if len(comp) > 1]

def component_weight(comp):
    weight = 0
    for a in comp:
        for b, count in call_counts.get(a, {}).items():
            if b in comp:
                weight += count
    return weight

core_label = None
if loop_components:
    core_comp = max(loop_components, key=component_weight)
    core_label = " + ".join(core_comp)
else:
    # fall back to module with highest outbound references
    core_label = max(nodes, key=lambda name: sum(call_counts.get(name, {}).values()))

verbs_out = {name: info["verb"] for name, info in module_info.items()}

data = {
    "core": core_label,
    "verbs": verbs_out,
    "retired": retired,
    "module_dir": module_dir,
}

with open(out_json, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2, sort_keys=True)
    fh.write("\n")

with open(out_report, "w", encoding="utf-8") as rep:
    rep.write("# Entropy Loop Report\n\n")
    rep.write(f"Modules scanned ({len(nodes)}): {', '.join(sorted(nodes))}\n\n")
    if loop_components:
        rep.write("## Loops\n")
        for comp in sorted(loop_components, key=component_weight, reverse=True):
            rep.write(f"- {' -> '.join(comp)} (weight={component_weight(comp)})\n")
        rep.write("\n")
    else:
        rep.write("## Loops\n- none detected (graph acyclic)\n\n")
    rep.write("## Verbs\n")
    for name in sorted(nodes):
        rep.write(f"- {name}: {module_info[name]['verb']}\n")
    rep.write("\n## Notes\n- Retired: " + (", ".join(retired) if retired else "none") + "\n")
    rep.write(f"- Core loop label: {core_label}\n")

print(f"[reduce] entropy map written to {out_json} and {out_report}")
PY
