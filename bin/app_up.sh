#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ensure_init() { make -s -C "$ROOT" init-refresh || true; }

start_bg() {
  mkdir -p "$ROOT/_ops/run"
  (cd "$ROOT"; python3 agents/switchboard_mcp.py > _ops/run/switchboard.log 2>&1 & echo $! > _ops/run/switchboard.pid)
  (cd "$ROOT"; python3 agents/init_mcp.py       > _ops/run/init_mcp.log 2>&1 & echo $! > _ops/run/init_mcp.pid)
  (cd "$ROOT"; bash   bin/ai_http.sh            > _ops/run/ai_http.log 2>&1 & echo $! > _ops/run/ai_http.pid)
  (cd "$ROOT"; bash   _ops/scheduler/run.sh     > _ops/run/scheduler.log 2>&1 & echo $! > _ops/run/scheduler.pid || true)
}

start_tmux() {
  local S=omarchy
  tmux has-session -t "$S" 2>/dev/null && { echo "tmux session '$S' already running"; return; }
  tmux new-session  -d -s "$S" -c "$ROOT" \; rename-window 'dashboard'
  tmux send-keys -t "$S":1 'make init-show; tail -f _ops/run/*.log 2>/dev/null' C-m

  tmux new-window   -t "$S" -n 'switchboard' -c "$ROOT"
  tmux send-keys    -t "$S":2 'python3 agents/switchboard_mcp.py | sed -u "s/^/[switchboard] /"' C-m

  tmux new-window   -t "$S" -n 'init-mcp' -c "$ROOT"
  tmux send-keys    -t "$S":3 'python3 agents/init_mcp.py       | sed -u "s/^/[init-mcp] /"' C-m

  tmux new-window   -t "$S" -n 'ai-http' -c "$ROOT"
  tmux send-keys    -t "$S":4 'bash bin/ai_http.sh               | sed -u "s/^/[ai-http] /"' C-m

  tmux new-window   -t "$S" -n 'scheduler' -c "$ROOT"
  tmux send-keys    -t "$S":5 'bash _ops/scheduler/run.sh        | sed -u "s/^/[scheduler] /"' C-m

  tmux new-window   -t "$S" -n 'shell' -c "$ROOT"
  tmux send-keys    -t "$S":6 'bin/ai_cli --help || true' C-m

  echo "tmux session '$S' started. Run: tmux attach -t $S"
}

ensure_init
if command -v tmux >/dev/null 2>&1; then start_tmux; else start_bg; fi