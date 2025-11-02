#!/usr/bin/env bash
set -euo pipefail
BASE="${OMARCHY_ROOT:-$HOME/.omarchy/current}"
REG="$BASE/builds.jsonl"; mkdir -p "$(dirname "$REG")"

# Require last MDL snapshot and last blueprint delta
MDL_LINE="$(tail -n1 "$BASE/logs/mdl.jsonl" 2>/dev/null || true)"
[ -n "$MDL_LINE" ] || { echo "no MDL snapshot; skip"; exit 0; }

DELTA="$(echo "$MDL_LINE" | jq -r '.delta // 0')"
BLABEL="$(jq -r '.label // "quantum-forge-unknown"' "$BASE/../palimpsest/blueprints/quantum-forge/quantum-forge-2.json" 2>/dev/null || echo "quantum-forge-2")"

THRESHOLD="${MDL_THRESHOLD:-0}"
if awk "BEGIN{exit !($DELTA < $THRESHOLD)}"; then
  BID="$(date -u +%Y%m%dT%H%M%SZ)-auto"
  echo "{\"ts\":\"$(date -u +%FT%TZ)\",\"build\":\"$BID\",\"blueprint\":\"$BLABEL\",\"mdl_delta\":$DELTA}" >> "$REG"
  if command -v omx >/dev/null; then omx pin default "$BID" || true; fi
  echo "Promoted build $BID (ΔMDL=$DELTA)"
else
  echo "No promotion (ΔMDL=$DELTA, threshold=$THRESHOLD)"
fi