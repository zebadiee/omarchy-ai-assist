#!/usr/bin/env bash
set -euo pipefail

modules=(git os sqlite docker interpreter compiler http-server kv-store)

echo "BYOX module?"
select choice in "${modules[@]}"; do
  if [[ -n "${choice:-}" ]]; then
    make import-byox X="$choice" || true
    exit 0
  else
    echo "Choose 1..${#modules[@]}"
  fi
done
