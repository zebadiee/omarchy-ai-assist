#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok(){ printf "${GREEN}✅ %s${NC}\n" "$1"; }
warn(){ printf "${YELLOW}⚠️  %s${NC}\n" "$1"; }
need(){ command -v "$1" >/dev/null 2>&1 && ok "$1" || warn "missing: $1"; }

echo "Speccy Health Check:"
echo "=================="
need git; need jq; need yq
need docker || warn "missing: docker (optional)"
need node  || warn "missing: node (optional)"
need python || warn "missing: python (optional)"
need go || warn "missing: go (optional)"
[ -f speccy-kit/workflows/registry.yml ] && ok "workflow registry" || warn "missing: workflow registry"
[ -x ./speccy ] && ok "speccy CLI" || warn "missing: speccy CLI"
[ -d speccy-kit/templates ] && ok "project templates" || warn "missing: project templates"
[ -d speccy-kit/prompts ] && ok "prompt framework" || warn "missing: prompt framework"

echo ""
echo "Environment:"
echo "============"
[ -n "${SANDBOX:-}" ] && ok "SANDBOX=$SANDBOX" || warn "SANDBOX not set"
[ -n "${SAFEOPS_NO_SUDO:-}" ] && ok "SAFEOPS_NO_SUDO=1" || warn "SAFEOPS_NO_SUDO not set"

echo ""
echo "Speccy-Kit is ready! 🚀"
