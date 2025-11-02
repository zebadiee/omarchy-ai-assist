#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S=omarchy
if command -v tmux >/dev/null 2>&1; then
  tmux has-session -t "$S" 2>/dev/null && tmux kill-session -t "$S" || true
fi
for p in switchboard init_mcp ai_http scheduler; do
  if [ -f "$ROOT/_ops/run/$p.pid" ]; then
    kill "$(cat "$ROOT/_ops/run/$p.pid")" 2>/dev/null || true
    rm -f "$ROOT/_ops/run/$p.pid"
  fi
done
echo "All services stopped."