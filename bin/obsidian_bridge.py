#!/usr/bin/env python3
import os, json, shutil, subprocess, datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CFG  = ROOT / "_ops" / "obsidian" / "config.json"
INIT = ROOT / "_ops" / "init" / "INIT.md"
USAGE = ROOT / "_ops" / "tokens" / "usage.json"
STATE = ROOT / "_ops" / "tokens" / "state.json"

def cfg():
    c = json.loads(CFG.read_text())
    c["vault_path"] = str(Path(os.path.expanduser(c["vault_path"])).resolve())
    return c

def ensure_dirs(*paths):
    for p in paths:
        Path(p).mkdir(parents=True, exist_ok=True)

def today_title(fmt: str) -> str:
    d = datetime.date.today()
    return d.strftime(fmt.replace("yyyy", "%Y").replace("mm", "%m").replace("dd", "%d"))

def sync_init():
    c = cfg()
    dst_dir = Path(c["vault_path"]) / c["ops_folder"]
    ensure_dirs(dst_dir)
    if INIT.exists():
        shutil.copy2(INIT, dst_dir / "INIT.md")
        print(f"INIT synced → {dst_dir/'INIT.md'}")
    else:
        print("INIT not found (run `make init-refresh` first).")

def export_usage():
    c = cfg()
    dst_dir = Path(c["vault_path"]) / c["tokens_folder"]
    ensure_dirs(dst_dir)
    if USAGE.exists():
        shutil.copy2(USAGE, dst_dir / "usage.json")
    if STATE.exists():
        shutil.copy2(STATE, dst_dir / "state.json")
    print(f"Token files exported → {dst_dir}")

def new_daily():
    c = cfg()
    daily_dir = Path(c["vault_path"]) / c["daily_folder"]
    ensure_dirs(daily_dir)
    title = today_title(c["daily_title_fmt"])
    note = daily_dir / f"{title}.md"
    if not note.exists():
        note.write_text(f"# {title}\n\n## Tasks\n\n- [ ] \n\n## Notes\n\n")
        print(f"Created {note}")
    else:
        print(f"Daily exists {note}")
    if c.get("use_obsidian_protocol"):
        try:
            subprocess.run(["xdg-open", f"obsidian://open?vault={Path(c['vault_path']).name}&file={c['daily_folder']}/{title}.md"], check=False)
        except Exception:
            pass

def log_session():
    """
    Append a compact log line to today's note.
    Env vars expected (set by ai_cli): OB_PROVIDER, OB_OK, OB_MS (ints)
    """
    c = cfg()
    daily_dir = Path(c["vault_path"]) / c["daily_folder"]
    ensure_dirs(daily_dir)
    title = today_title(c["daily_title_fmt"])
    note = daily_dir / f"{title}.md"
    if not note.exists():
        new_daily()
    provider = os.getenv("OB_PROVIDER", "unknown")
    ok = os.getenv("OB_OK", "false")
    ms = os.getenv("OB_MS", "0")
    line = f"- {datetime.datetime.now().strftime('%H:%M:%S')} · **{provider}** · {'✅' if ok=='true' else '❌'} · {ms} ms\n"
    with open(note, "a", encoding="utf-8") as f:
        f.write("\n### AI Sessions\n" if "### AI Sessions" not in note.read_text(encoding="utf-8") else "")
        f.write(line)
    print(f"Logged session → {note}")

def main():
    import sys
    if len(sys.argv) < 2:
        print("usage: obsidian_bridge.py [sync-init|export-usage|new-daily|log-session]")
        raise SystemExit(2)
    cmd = sys.argv[1]
    if cmd == "sync-init":
        sync_init()
    elif cmd == "export-usage":
        export_usage()
    elif cmd == "new-daily":
        new_daily()
    elif cmd == "log-session":
        log_session()
    else:
        print(f"unknown command: {cmd}")
        raise SystemExit(2)

if __name__ == "__main__":
    main()