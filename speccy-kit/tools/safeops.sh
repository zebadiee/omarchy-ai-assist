#!/usr/bin/env bash
set -euo pipefail

# Defaults
ROOT="${ROOT:-$PWD}"
LAB="${LAB:-$PWD/speccy-lab}"

deny_sudo() {
  if [ "${SAFEOPS_NO_SUDO:-1}" = "1" ]; then
    if grep -qE '(^|[^A-Za-z0-9_-])sudo([^A-Za-z0-9_-]|$)' <<<"${*:-}"; then
      echo "[SAFEOPS] sudo is disabled in this context." >&2
      exit 77
    fi
  fi
}

require_in_lab() {
  local p="$1"
  local abs
  abs="$(realpath -m -- "$p")"
  local lab_abs
  lab_abs="$(realpath -m -- "$LAB")"
  case "$abs" in
    "$lab_abs"/*) ;; # ok
    *) echo "[SAFEOPS] Path must be inside LAB: $LAB (got: $abs)" >&2; exit 78;;
  esac
}

atomic_write() {
  # atomic_write <target> <stdin>
  local target="$1"
  require_in_lab "$target"
  local dir; dir="$(dirname "$target")"
  mkdir -p "$dir"
  local tmp; tmp="$(mktemp "${target}.XXXX")"
  cat > "$tmp"
  mv -f "$tmp" "$target"
}

# Convenience guarded edit:
safe_replace() {
  # safe_replace <file> <sed_expr>
  local f="$1"; shift
  require_in_lab "$f"
  local tmp; tmp="$(mktemp)"
  sed "$@" -- "$f" >"$tmp"
  mv -f "$tmp" "$f"
}