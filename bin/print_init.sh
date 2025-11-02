#!/usr/bin/env bash
set -euo pipefail
FILE="_ops/init/INIT.md"
[ -f "$FILE" ] || exit 0
repo="$(grep -oP '(?<=<!--INIT:GIT_REPO-->).*(?=<!--/INIT:GIT_REPO-->)' "$FILE" || true)"
branch="$(grep -oP '(?<=<!--INIT:GIT_BRANCH-->).*(?=<!--/INIT:GIT_BRANCH-->)' "$FILE" || true)"
head="$(grep -oP '(?<=<!--INIT:GIT_HEAD-->).*(?=<!--/INIT:GIT_HEAD-->)' "$FILE" || true)"
router="$(grep -oP '(?<=<!--INIT:ROUTER_PROVIDER-->).*(?=<!--/INIT:ROUTER_PROVIDER-->)' "$FILE" || true)"
stamp="$(grep -oP '(?<=<!--INIT:STAMP-->).*(?=<!--/INIT:STAMP-->)' "$FILE" || true)"
echo "┌─ INIT ───────────────────────────────────────────────"
echo "│ Repo: ${repo:-?}  Branch: ${branch:-?}  @${head:-?}"
echo "│ Router: ${router:-openrouter}  Refreshed: ${stamp:-?}"
echo "└──────────────────────────────────────────────────────"