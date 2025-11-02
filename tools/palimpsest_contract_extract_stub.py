#!/usr/bin/env python3
import json
import sys
from collections import Counter
from pathlib import Path

if len(sys.argv) < 3:
    print("usage: palimpsest_contract_extract_stub.py <traces.jsonl> <output.json>")
    sys.exit(1)

trace_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])
records = []
with trace_path.open() as fh:
    for line in fh:
        line = line.strip()
        if not line:
            continue
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError:
            pass

if not records:
    raise SystemExit("no records parsed")

states = sorted({r.get("state", "") for r in records})
actions = Counter(r.get("action", "") for r in records)
reward_stats = {
    "count": len(records),
    "min": min(r.get("reward", 0) for r in records),
    "max": max(r.get("reward", 0) for r in records),
    "avg": sum(r.get("reward", 0) for r in records) / len(records),
}
contract = {
    "id": "contract-" + records[0].get("id", "unknown")[:8],
    "inputs": ["state"],
    "outputs": ["action", "reward"],
    "states": states,
    "actions_ranked": actions.most_common(),
    "reward_stats": reward_stats,
    "invariants": {
        "reward_range": [reward_stats["min"], reward_stats["max"]],
        "state_domain": states,
    },
    "tests": [
        {
            "name": "noop-demo",
            "given_state": states[0],
            "expect_action": actions.most_common(1)[0][0],
        }
    ],
}
out_path.write_text(json.dumps(contract, indent=2))
print(json.dumps(contract, indent=2))
