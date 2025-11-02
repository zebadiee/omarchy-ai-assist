#!/usr/bin/env python3
import os, json, subprocess, datetime, re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
INIT=ROOT/"_ops"/"init"/"INIT.md"
POLICY=ROOT/"_ops"/"agents"/"switchboard.policy.json"
USAGE=ROOT/"_ops"/"tokens"/"usage.json"
TOKSTATE=ROOT/"_ops"/"tokens"/"state.json"

def sh(cmd):
    return subprocess.check_output(cmd, shell=True, text=True).strip()

def git_info():
    try:
        repo=sh("basename -s .git `git rev-parse --show-toplevel`")
        branch=sh("git rev-parse --abbrev-ref HEAD")
        head=sh("git rev-parse --short HEAD")
        return repo, branch, head
    except Exception:
        return "unknown","unknown","unknown"

def router_provider():
    # read last timing or prefer policy first entry
    try:
        pol=json.loads(POLICY.read_text())
        prio=pol.get("priority",[])
        return prio[0] if prio else "openrouter"
    except Exception:
        return "openrouter"

def policy_json():
    try:
        return json.dumps(json.loads(POLICY.read_text()), indent=2)
    except Exception:
        return "{}"

def tokens_summary():
    try:
        st=json.loads(TOKSTATE.read_text())
        provs=st.get("providers",{})
        parts=[]
        for name, data in provs.items():
            keys=data.get("keys",[])
            healthy=sum(1 for k in keys if k.get("cb_open_until",0)==0)
            total=len(keys)
            parts.append(f"- {name}: {healthy}/{total} healthy")
        return "\n".join(parts) if parts else "No providers configured."
    except Exception:
        return "No data yet."

def stamp():
    return datetime.datetime.utcnow().replace(microsecond=0).isoformat()+"Z"

def replace_tag(text, tag, content):
    pat=re.compile(rf"(<!--INIT:{tag}-->)(.*?)(<!--/INIT:{tag}-->)", re.S)
    return pat.sub(rf"\1{content}\3", text)

def main():
    INIT.parent.mkdir(parents=True, exist_ok=True)
    if not INIT.exists():
        INIT.write_text("# INIT missing – run make init-refresh\n")
    text=INIT.read_text()
    repo,branch,head=git_info()
    text=replace_tag(text,"STAMP",stamp())
    text=replace_tag(text,"GIT_REPO",repo)
    text=replace_tag(text,"GIT_BRANCH",branch)
    text=replace_tag(text,"GIT_HEAD",head)
    text=replace_tag(text,"ROUTER_PROVIDER",router_provider())
    text=replace_tag(text,"POLICY_JSON",policy_json())
    text=replace_tag(text,"TOKENS_SUMMARY",tokens_summary())
    INIT.write_text(text)
    print(f"Refreshed {INIT}")

if __name__=="__main__":
    main()