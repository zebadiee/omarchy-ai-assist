#!/usr/bin/env python3
import sys, json, time, os, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POLICY = ROOT / "_ops" / "agents" / "switchboard.policy.json"
USAGE  = ROOT / "_ops" / "tokens" / "usage.json"

def load_json(p, default):
    try:
        return json.loads(Path(p).read_text())
    except Exception:
        return default

def now_ms(): return int(time.time()*1000)

def pick_provider():
    pol = load_json(POLICY, {})
    prio = pol.get("priority", [])
    providers = pol.get("providers", {})
    # honor deny_until and prefer flags
    preferred = [p for p in prio if providers.get(p,{}).get("prefer")]
    ordered = preferred + [p for p in prio if p not in preferred]
    t = now_ms()
    for p in ordered:
        di = providers.get(p,{}).get("deny_until")
        if di and t < di:  # still denied
            continue
        return p
    return ordered[0] if ordered else "openrouter"

def record_session(provider, ok=True, ms=0, meta=None):
    meta = meta or {}
    u = load_json(USAGE, {"sessions":[]})
    u["sessions"].append({
        "ts": now_ms(), "provider": provider, "ok": ok, "duration_ms": ms, "meta": meta
    })
    USAGE.parent.mkdir(parents=True, exist_ok=True)
    USAGE.write_text(json.dumps(u, indent=2))

def main():
    # very small stdio MCP: {"method":"route", "args":{"hint":"chat|code"}}
    for line in sys.stdin:
        try:
            req = json.loads(line.strip())
            if req.get("method") == "route":
                p = pick_provider()
                pol = load_json(POLICY, {})
                cli = pol.get("providers",{}).get(p,{}).get("cli","goose")
                print(json.dumps({"ok":True, "data":{"provider":p,"cli":cli}}), flush=True)
            elif req.get("method") == "record":
                a = req.get("args",{})
                record_session(a.get("provider","openrouter"), a.get("ok",True), a.get("duration_ms",0), a.get("meta",{}))
                print(json.dumps({"ok":True}), flush=True)
            else:
                print(json.dumps({"ok":False,"error":"unknown_method"}), flush=True)
        except Exception as e:
            print(json.dumps({"ok":False,"error":str(e)}), flush=True)

if __name__ == "__main__":
    main()