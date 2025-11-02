#!/usr/bin/env bash
set -euo pipefail
ROOT="${ROOT:-$PWD}"
bash "$ROOT/omarchy-ai-assist/speccy-kit/tools/pack.sh" "$@"
