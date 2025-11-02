#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8 LANG=C.UTF-8
LAB="${LAB:-$PWD/speccy-lab}"
MEM="$LAB/memory"; LOGS="$LAB/logs"
mkdir -p "$MEM" "$LOGS"

keep_tail () { # keep last N unique lines preserving recency
  local file="$1" ; local N="$2"
  [ -f "$file" ] || return 0
  tac "$file" | awk '!seen[$0]++' | head -n "$N" | tac > "$file.tmp" && mv "$file.tmp" "$file"
}

# training log: keep last 2k unique lines
keep_tail "$MEM/training.log" 2000

# validation history: last 1k
keep_tail "$LOGS/validation-history.log" 1000

# any lesson logs
find "$LOGS" -type f -name "lesson-*.log" -size +1M -print0 | while IFS= read -r -d '' f; do
  keep_tail "$f" 2000
done

echo "REFLECT: memory_gc trimmed logs @ $(date -Iseconds)" >> "$MEM/training.log"
echo "[gc] memory/logs compaction done"