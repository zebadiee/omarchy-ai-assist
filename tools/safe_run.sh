#!/usr/bin/env bash
set -euo pipefail

# ========== config ==========
SANDBOX="${SANDBOX:-nspawn}"    # nspawn|docker
ROOT_SNAPSHOT="${ROOT_SNAPSHOT:-auto}" # auto|skip
ALLOW_CHMOD_PATHS="${ALLOW_CHMOD_PATHS:-/opt /usr/local /home}"
DRY="${DRY:-0}"                # DRY=1 skips snapshot + apply, but runs scans + sandbox
# ============================

die(){ printf "\e[31m[SAFE]\e[0m %s\n" "$*" >&2; exit 1; }
need(){ command -v "$1" >/dev/null 2>&1 || die "Missing dep: $1"; }

need grep; need awk; need sed; need tee
command -v shellcheck >/dev/null 2>&1 || echo "[SAFE] shellcheck missing (optional)"

SCRIPT="${1:-}"; shift || true
[ -n "$SCRIPT" ] && [ -f "$SCRIPT" ] || die "usage: $0 path/to/script.sh [args...]"

# --- 1) Static red flags ---
if grep -nE '(^|[^a-zA-Z_])(rm[[:space:]]+-rf)[[:space:]]+/( |$)' "$SCRIPT"; then
  die "Absolute rm -rf on root detected"
fi
if grep -nE 'chmod[[:space:]]+-R[[:space:]]+7(7[0-7]|[0-7]7)' "$SCRIPT"; then
  echo "[SAFE] Recursive chmod 77x detected; verifying allowlist..."
  while IFS= read -r line; do
    path=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^\//) print $i}')
    ok=""
    for base in $ALLOW_CHMOD_PATHS; do
      [[ "${path}" == $base* ]] && ok="yes"
    done
    [ -n "$ok" ] || die "chmod -R on non-allowlisted path: ${path:-unknown}"
  done < <(grep -nE 'chmod[[:space:]]+-R[[:space:]]+7(7[0-7]|[0-7]7).*\/' "$SCRIPT")
fi
if grep -nE '/etc/sudoers([^.]|$)' "$SCRIPT"; then
  die "Direct /etc/sudoers edit detected. Use /etc/sudoers.d/*.conf + visudo -c"
fi

# Additional denylist patterns
if grep -nE '/etc/(pam\.d/|shadow|ssh/sshd_config)' "$SCRIPT"; then
  die "Direct edit of authentication/ssh config detected. Use drop-in files and validate."
fi
if grep -nE '(iptables[[:space:]]+-F|ufw[[:space:]]+reset|sysctl[[:space:]]+-w[[:space:]]+kernel\.)' "$SCRIPT"; then
  die "Dangerous system configuration command detected. Requires manual review."
fi
if grep -nE 'find[[:space:]]+/[[:space:]]+-exec[[:space:]]+(chmod|chown)' "$SCRIPT"; then
  die "Recursive find with chmod/chown on filesystem detected. Use allowlisted paths only."
fi

# Optional: shellcheck lint
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -x "$SCRIPT" || echo "[SAFE] shellcheck warnings above"
fi

# --- 2) Snapshot ---
if [[ "$ROOT_SNAPSHOT" == "auto" && "$DRY" -eq 0 ]]; then
  if command -v omarchy-snapshot >/dev/null 2>&1; then
    sudo omarchy-snapshot create "pre-safe-run-$(date +%s)" || true
  elif mount | grep -q btrfs; then
    sudo btrfs subvolume snapshot / "/root-backup-$(date +%Y%m%d-%H%M)" || true
  else
    echo "[SAFE] No snapshot tool found (continuing)."
  fi
elif [[ "$DRY" -eq 1 ]]; then
  echo "[SAFE] DRY RUN: Skipping snapshot"
fi

# --- 3) Sandbox execute ---
case "$SANDBOX" in
  nspawn)
    need systemd-nspawn
    root="/var/lib/machines/safe-$USER"
    sudo mkdir -p "$root"
    # minimal root overlay with bind mounts
    sudo systemd-nspawn -D "$root" \
      --bind-ro=/etc \
      --bind=/tmp \
      --bind-ro="$(pwd)":/work \
      /usr/bin/env bash -lc "cd /work; set -euo pipefail; bash '$SCRIPT' $*"
    ;;
  docker)
    need docker
    img="${SAFE_IMG:-debian:stable-slim}"
    docker run --rm -v "$(pwd)":/work -w /work "$img" \
      bash -lc "apt-get update >/dev/null 2>&1 || true; bash '$SCRIPT' $*"
    ;;
  *)
    die "Unknown SANDBOX=$SANDBOX"
esac

echo "[SAFE] Sandbox run succeeded."
if [[ "$DRY" -eq 1 ]]; then
  echo "[SAFE] DRY RUN completed - no changes applied to host"
else
  echo "[SAFE] Review diff, then apply to host manually if desired."
fi