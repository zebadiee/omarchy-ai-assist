#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8 LANG=C_UTF-8

ROOT="${ROOT:-$PWD}"
LAB="${LAB:-$PWD/speccy-lab}"
LOGS="$LAB/logs"; MEM="$LAB/memory"
mkdir -p "$LOGS" "$MEM"

. speccy-kit/tools/safeops.sh

echo "[INFO] Operator Lesson 2: Safe revert starting"

target="$LAB/packs/sway/sources/sway-workspaces.md"
backup_dir="$LOGS/backups"; mkdir -p "$backup_dir"

if [ ! -f "$target" ]; then
  echo "[INFO] No sway workspaces file found, skipping revert step."
else
  require_in_lab "$target"
  ts="$(date -Iseconds)"
  cp -a "$target" "$backup_dir/sway-workspaces.md.$(date +%Y%m%d-%H%M%S).bak"
  # Remove our Lesson 1 tip block if present (clean & idempotent)
  safe_tmp="$(mktemp)"
  awk '
    BEGIN{skip=0}
    /^## Quick tip: workspace cycle/{skip=1;next}
    skip==1 && NF==0 {skip=0;next}
    skip==1 {next}
    {print}
  ' "$target" > "$safe_tmp"
  mv -f "$safe_tmp" "$target"
  echo "SAFEOPS:REVERT $ts file=$target" >> "$LOGS/tamperlog.jsonl"
  echo "[SUCCESS] Reverted lesson tip in $target (backup saved)."
fi

# Re-index sway (if present)
if [ -f "$LAB/packs/sway/pack.yml" ]; then
  bash speccy-kit/tools/pack.sh sway install || true
fi

# Audit signals
echo "REFLECT: $(date -Iseconds) revert-safe: removed lesson tip & re-indexed sway" >> "$MEM/training.log"
echo "DRY-RUN:OK $(date -Iseconds)" >> "$LOGS/lesson-operator2.log"

echo "[SUCCESS] Operator Lesson 2 finished"