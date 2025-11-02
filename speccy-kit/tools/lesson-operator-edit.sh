#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8 LANG=C.UTF-8

ROOT="${ROOT:-$PWD}"
LAB="${LAB:-$PWD/speccy-lab}"

. speccy-kit/tools/safeops.sh

echo "[INFO] Operator Lesson 1: Safe self-edit starting"

# 1) Create/update a small LAB note
target_note="$LAB/NOTES.md"
deny_sudo "write note"
atomic_write "$target_note" <<'MD'
# Speccy Lab Operator Notes

- This file is maintained via SafeOps (atomic writes only).
- Lesson: Operator self-edit verified.
MD
echo "[SUCCESS] Wrote $target_note"

# 2) Append a harmless example to a pack source (if sway pack exists)
pack_src="$LAB/packs/sway/sources/sway-workspaces.md"
if [ -f "$pack_src" ]; then
  require_in_lab "$pack_src"
  # idempotent append (only once)
  if ! grep -q "## Quick tip: workspace cycle" "$pack_src"; then
    printf "\n## Quick tip: workspace cycle\n- Example: \`bindsym \$mod+Tab workspace next\`\n" >> "$pack_src"
    echo "[SUCCESS] Appended tip to $pack_src"
  else
    echo "[INFO] Tip already present in $pack_src"
  fi
fi

echo "[INFO] Re-index any affected pack(s)"
# Re-index sway if present
if [ -f "$LAB/packs/sway/pack.yml" ]; then
  bash speccy-kit/tools/pack.sh sway install || true
fi

echo "[SUCCESS] Operator Lesson 1 finished"