#!/usr/bin/env bash
# Omarchy ⇄ Quantum-Forge one-button launch
# idempotent; safe to run multiple times
set -euo pipefail

# --- Config ---------------------------------------------------------------
PROJECT_ROOT="${PROJECT_ROOT:-$HOME/Documents/omarchy-ai-assist}"
OM_ROOT_DEFAULT="$HOME/.omarchy/current"
VAULT_DEFAULT="$HOME/Obsidian/Vault"
EDITOR_BIN="${EDITOR_BIN:-codium}"   # change to code or code-oss if you prefer
MDL_THRESHOLD_DEFAULT="${MDL_THRESHOLD_DEFAULT:--0.10}"
SAFEOPS_DEFAULT="${SAFEOPS_DEFAULT:-1}"
PORT_MON="${PORT_MON:-8088}"

# --- Resolve paths --------------------------------------------------------
cd "$PROJECT_ROOT"
OM_ROOT="${OMARCHY_ROOT:-$OM_ROOT_DEFAULT}"
export OMARCHY_ROOT="$OM_ROOT"
export OM_OBSIDIAN_VAULT="${OM_OBSIDIAN_VAULT:-$VAULT_DEFAULT}"
mkdir -p "$OM_ROOT/logs"

# --- Tokens / Build ID ----------------------------------------------------
if [ -f "$OM_ROOT/tokens/env.sh" ]; then
  # shellcheck disable=SC1090
  source "$OM_ROOT/tokens/env.sh"
else
  echo "⚠️  Tokens file missing: $OM_ROOT/tokens/env.sh (providers that need keys will be skipped)."
fi

if command -v om-shra >/dev/null 2>&1; then
  export OMARCHY_BUILD_ID="$(om-shra || echo manual-$(date -u +%Y%m%dT%H%M%SZ))"
else
  export OMARCHY_BUILD_ID="manual-$(date -u +%Y%m%dT%H%M%SZ)"
fi

# --- VBH facts bootstrap (first-run convenience) -------------------------
if [ -x scripts/om-vbh-bootstrap.sh ]; then
  echo "📒 Seeding VBH facts (bootstrap)…"
  ./scripts/om-vbh-bootstrap.sh || true
fi

# --- Quantum-Forge Monitor (telemetry) -----------------------------------
start_monitor_bg() {
  if command -v systemctl >/dev/null 2>&1; then
    # user service
    UNIT="$HOME/.config/systemd/user/quantum-forge-monitor.service"
    mkdir -p "$(dirname "$UNIT")"
    cat > "$UNIT" <<EOF
[Unit]
Description=Quantum-Forge monitor (:${PORT_MON})

[Service]
ExecStart=${PROJECT_ROOT}/quantum-forge-monitor
Restart=always
RestartSec=2
WorkingDirectory=${PROJECT_ROOT}
Environment=OMARCHY_ROOT=${OMARCHY_ROOT}

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable --now quantum-forge-monitor.service
  else
    # fallback: nohup
    if ! pgrep -f "quantum-forge-monitor" >/dev/null 2>&1; then
      nohup "${PROJECT_ROOT}/quantum-forge-monitor" >/dev/null 2>&1 &
    fi
  fi
}
if [ -x "${PROJECT_ROOT}/quantum-forge-monitor" ]; then
  echo "📡 Starting telemetry monitor…"
  start_monitor_bg
else
  echo "ℹ️  quantum-forge-monitor binary not found; skipping (build via: cd cmd/quantum-forge-monitor && go build -o ../../quantum-forge-monitor)"
fi

# --- Quantum adapter is on-demand (kept as shim in your pipeline) --------
if [ -f "${PROJECT_ROOT}/quantum/adapter/qaoa_reduce.py" ]; then
  echo "⚛️  Quantum adapter available (qaoa_reduce.py)."
fi

# --- Auto-promotion schedule (one-shot this run) -------------------------
export MDL_THRESHOLD="${MDL_THRESHOLD:-$MDL_THRESHOLD_DEFAULT}"
if [ -x scripts/auto_promote.sh ]; then
  echo "🔄 Auto-promotion check (ΔMDL < ${MDL_THRESHOLD})…"
  ./scripts/auto_promote.sh || true
fi

# --- Health check (warnings non-fatal) -----------------------------------
if [ -x scripts/health-check.sh ]; then
  echo "🩺 Running health check…"
  ./scripts/health-check.sh || true
fi

# --- SafeOps hooks re-enable (with escape hatch) -------------------------
if [ -d ".githooks" ]; then
  git config core.hooksPath .githooks
  export SAFEOPS="${SAFEOPS:-$SAFEOPS_DEFAULT}"
  echo "🛡️  SafeOps hooks active (SAFEOPS=${SAFEOPS}; set SAFEOPS=0 to bypass on a commit)."
fi

# --- Editor integration: Continue → your local ai_cli --------------------
# Creates .continue/config.json with a local model that calls your ai_cli stack.
CONT_DIR=".continue"
mkdir -p "$CONT_DIR"
cat > "$CONT_DIR/config.json" <<'JSON'
{
  "models": {
    "omarchy-local": {
      "cmd": "TS_FORCE_PROVIDER=local /home/zebadiee/Documents/omarchy-ai-assist/bin/ai_cli"
    }
  },
  "defaultModel": "omarchy-local"
}
JSON
echo "🧩 Continue config ready: ${PROJECT_ROOT}/.continue/config.json → local Omarchy agent."

# --- Launch VSCodium workspace (optional) --------------------------------
if command -v "$EDITOR_BIN" >/dev/null 2>&1; then
  echo "🧰 Launching ${EDITOR_BIN} with Omarchy workspace…"
  "$EDITOR_BIN" "$PROJECT_ROOT" >/dev/null 2>&1 &
else
  echo "ℹ️  Editor '${EDITOR_BIN}' not found; open your editor manually if desired."
fi

# --- Friendly summary -----------------------------------------------------
DASH="http://localhost:${PORT_MON}"
echo ""
echo "✅ Omarchy One-Button Launch complete."
echo "   • Dashboard:  ${DASH}"
echo "   • Metrics:    ${DASH}/metrics.json"
echo "   • VBH Vault:  ${OM_OBSIDIAN_VAULT}"
echo "   • Build ID:   ${OMARCHY_BUILD_ID}"
echo "   • Promotion:  MDL_THRESHOLD=${MDL_THRESHOLD}"
echo ""
echo "Tips:"
echo "  - Ask your assistant in terminal:  AI_PURPOSE=assist scripts/../bin/ai_cli <<< 'Draft status update.'"
echo "  - In VSCodium: open the Continue panel → it uses your local Omarchy agent."
echo "  - Commit override when hooks block:  SAFEOPS=0 git commit -m '…'"
