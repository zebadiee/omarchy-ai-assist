#!/usr/bin/env bash
set -euo pipefail

: "${OM_OBSIDIAN_VAULT:=$HOME/Obsidian/Vault}"
REG="${1:-agents/registry.yaml}"

if ! command -v om-obs-set >/dev/null; then
  echo "om-obs-set not found. Install your VBH helpers first." >&2
  exit 2
fi

# default provider per agent (can be overridden via env)
default_provider() {
  case "$1" in
    sherlock-ohms) echo "${PROV_SHERLOCK:-gemini-2.0-flash}";;
    navigator)     echo "${PROV_NAVIGATOR:-codex}";;
    codex)         echo "${PROV_CODEX:-codex}";;
    palimpsest)    echo "${PROV_PALIMPSEST:-codex}";;
    *)             echo "${PROV_DEFAULT:-codex}";;
  esac
}

# parse registry (yq or awk fallback)
if command -v yq >/dev/null; then
  mapfile -t ITEMS < <(yq -r '.agents[] | "\(.id) \(.purpose)"' "$REG")
else
  ITEMS=()
  while read -r line; do
    case "$line" in
      -*id*|*purpose*) buf+="${line}" ;;
      "") if [[ -n "${buf:-}" ]]; then
            id=$(sed -n 's/.*id:[[:space:]]*//p' <<<"$buf" | head -1)
            pr=$(sed -n 's/.*purpose:[[:space:]]*//p' <<<"$buf" | head -1)
            [[ -n "$id" && -n "$pr" ]] && ITEMS+=("$id $pr")
            buf=""
          fi;;
    esac
  done < "$REG"
fi

echo "📒 Bootstrapping VBH facts into vault: $OM_OBSIDIAN_VAULT"
for row in "${ITEMS[@]}"; do
  agent="${row%% *}"
  purpose="${row#* }"
  provider="$(default_provider "$agent")"
  echo " • $agent / $purpose  → provider=$provider"
  om-obs-set "$agent" "$purpose" \
    scope="unified" site="Omarchy" open_tasks=0 provider="$provider" >/dev/null
done

echo "✅ VBH facts seeded. (Set OM_OBSIDIAN_VAULT in your shell profile for permanence.)"