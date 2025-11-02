#!/usr/bin/env bash
# omarchy-finalize.sh — Finalize Omarchy R&D workflow
# Tracks local artifacts by default, runs one-button launcher + smoke tests,
# tails telemetry logs, and ensures gh default repo is set.

set -euo pipefail

REPO_REMOTE="${REPO:-zebadiee/omarchy-ai-assist}"
TRACK_ARTIFACTS="${TRACK_ARTIFACTS:-1}" # 1 = track, 0 = ignore
ARTIFACTS=(.continue .project files .gitattributes)

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo "❌ Not inside a git repository. cd into the repo root first."
  exit 1
fi

cd "$repo_root"
echo "📍 Finalizing Omarchy R&D in $repo_root"

# Ensure GitHub CLI knows which repo to target.
if ! gh repo view >/dev/null 2>&1; then
  echo "🐙 Setting gh default repo → $REPO_REMOTE"
  gh repo set-default "$REPO_REMOTE" || true
fi

# Handle local development artifacts.
if [[ "$TRACK_ARTIFACTS" == "1" ]]; then
  echo "🗂  Tracking local artifacts: ${ARTIFACTS[*]}"
  git add "${ARTIFACTS[@]}" 2>/dev/null || true
  if ! git diff --cached --quiet; then
    SAFEOPS=0 git commit -m "chore(dev): track local artifacts (.continue/ .project/ files/ .gitattributes)"
    git push || true
  else
    echo "   (no artifact changes to commit)"
  fi
else
  echo "🙈 Ignoring local artifacts (TRACK_ARTIFACTS=0)"
  {
    echo ""
    echo "# Dev artifacts"
    for art in "${ARTIFACTS[@]}"; do
      echo "${art%/}/"
    done
  } >> .gitignore
  git add .gitignore
  SAFEOPS=0 git commit -m "chore(dev): ignore local artifacts in .gitignore" || true
  git push || true
fi

echo "🩺 Running one-button launcher"
./scripts/omarchy_one_button.sh || true

echo "▶ R&D smoke (rnd-run/search/stop)"
make rnd-run
make rnd-search
make rnd-stop

echo "🧹 Optional cleanup (rnd-clean)"
make rnd-clean || true

usage_log="$HOME/.omarchy/current/logs/usage.jsonl"
mdl_log="$HOME/.omarchy/current/logs/mdl.jsonl"
builds_log="$HOME/.omarchy/current/builds.jsonl"

echo "📊 Telemetry tail:"
[[ -f "$usage_log" ]] && tail -n 5 "$usage_log" || echo "  (usage log not found)"

echo "📉 MDL tail:"
[[ -f "$mdl_log" ]] && tail -n 5 "$mdl_log" || echo "  (mdl log not found)"

echo "🏷  Build registry tail:"
[[ -f "$builds_log" ]] && tail -n 5 "$builds_log" || echo "  (builds log not found)"

echo "✅ Finalize complete. (TRACK_ARTIFACTS=$TRACK_ARTIFACTS)"
