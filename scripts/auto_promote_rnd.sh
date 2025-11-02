#!/usr/bin/env bash
set -euo pipefail
BASE="${OMARCHY_ROOT:-$HOME/.omarchy/current}"
LOG="$BASE/logs/mdl.jsonl";mkdir -p "$(dirname "$LOG")"
DELTA=$(jq -r '.[-1].delta // -0.1' "$LOG" 2>/dev/null || echo -0.1)
THRESH=${MDL_THRESHOLD:--0.2}
if (( $(echo "$DELTA < $THRESH" | bc -l) ));then
  ID=$(date -u +%Y%m%dT%H%M%SZ)-auto-rnd
  echo "{\"ts\":\"$(date -u +%FT%TZ)\",\"build\":\"$ID\",\"mdl_delta\":$DELTA}" >> "$BASE/builds.jsonl"
  echo "Promoted R&D build $ID (ΔMDL=$DELTA)"
fi
