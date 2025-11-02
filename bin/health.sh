#!/usr/bin/env bash
set -euo pipefail
ok() { printf "✅ %s\n" "$1"; }
warn(){ printf "⚠️  %s\n" "$1"; }
fail(){ printf "❌ %s\n" "$1"; exit 1; }

test -f "_ops/init/INIT.md" && ok "INIT present" || warn "INIT missing (make init-refresh)"
pgrep -f "agents/switchboard_mcp.py" >/dev/null && ok "Switchboard MCP" || warn "Switchboard not running"
pgrep -f "agents/init_mcp.py"       >/dev/null && ok "INIT MCP"        || warn "INIT MCP not running"
pgrep -f "bin/ai_http.sh"           >/dev/null && ok "ai_http shim"    || warn "ai_http not running"
pgrep -f "_ops/scheduler/run.sh"    >/dev/null && ok "Scheduler"       || warn "Scheduler not running"
[ -S /tmp/tmux-$(id -u)/default ] && ok "tmux socket exists" || warn "tmux socket not found"
exit 0