#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8 LANG=C_UTF-8
LAB="${LAB:-$PWD/speccy-lab}"
PK="$LAB/packs"
mkdir -p "$LAB/logs"
python3 speccy-kit/tools/condenser.py "$PK" "${1:-0.88}" | tee -a "$LAB/logs/condense.log"
echo "REFLECT: condense-packs done" >> "$LAB/memory/training.log"