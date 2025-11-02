#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Mode toggle - brutal honesty vs polite review
if [ "${ROAST_MODE:-mean}" = "mean" ]; then
  export AI_TONE="🔥 Brutal Honesty Mode"
else
  export AI_TONE="✨ Polite Review Mode"
fi
echo "Roast Mode: $AI_TONE"

grab(){ "$@" 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g' | tail -n 500; }

# Collect system data for roasting
LINT="$(grab make -s lint || true)"
TEST="$(grab make -s test || true)"
TOKENS="$(grab make -s token-status || true)"
CI="$( [ -f .github/workflows/ci.yml ] && echo "CI config present" || echo "No CI config" )"
INIT="$( [ -f _ops/init/INIT.md ] && sed -n '1,100p' _ops/init/INIT.md || echo "INIT missing" )"

sep(){ printf "\n\033[1;31m==== %s ====\033[0m\n" "$1"; }

roast_prompt () {
cat <<EOF
You're a ${1}. Your job is to roast the developer mercilessly.
You are sarcastic, witty, and brutally honest — but useful.
If the work is good, you still find flaws for fun.
If it's bad, you go full Gordon Ramsay.
Never apologize. Deliver 3-5 short bullets.
Always end with: "🔥 Final Verdict: [1–10], where 10 means 'shockingly competent'".
EOF
}

sep "CODE ROAST"
{
  roast_prompt "senior software engineer who roasts code like a stand-up comic"
  echo "Code context:"
  echo "$LINT" | head -n 100
  echo
  echo "$TEST" | head -n 50
} | bin/ai_cli session

sep "OPS ROAST"
{
  roast_prompt "grizzled DevOps SRE veteran who mocks fragile pipelines"
  echo "Ops context:"
  echo "$TOKENS"
} | bin/ai_cli session

sep "UX ROAST"
{
  roast_prompt "terminal UX designer who roasts CLI experiences with venomous sarcasm"
  echo "UX context:"
  echo "$INIT" | head -n 100
} | bin/ai_cli session

echo ""
echo "$AI_TONE Roast session complete! 🔥"