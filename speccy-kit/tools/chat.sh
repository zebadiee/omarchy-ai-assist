#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8 LANG=C.UTF-8

ROOT="${ROOT:-"$PWD"}"
LAB="${LAB:-"/home/zebadiee/Documents/speccy-lab"}"
MEM="$LAB/memory"; LOGS="$LAB/logs"
mkdir -p "$MEM" "$LOGS"

PACKS_DIR="$LAB/packs"

usage(){
  echo "Usage: chat.sh [--once 'query']  OR  chat.sh (interactive)"
}

search_all() {
  q="$1"
  PACKS_DIR="$LAB/packs"

  # Collect all indexes (prefer index.jsonl if fresh, else index.compact.jsonl fallback)
  mapfile -t idx < <(
    find "$PACKS_DIR" -maxdepth 2 -type f \( -name index.jsonl -o -name index.compact.jsonl \) 2>/dev/null \
    | sort | awk -F'/index' '!seen[$1]++{print $0}'
  )
  [ "${#idx[@]}" -gt 0 ] || { echo "[WARN] No packs indexed yet."; return 0; }

  # Normalise + tokenise the query (lowercase; split on non-alnum)
  q_norm="$(printf '%s' "$q" | tr '[:upper:]' '[:lower:]')"
  # tokens: words only (drop punctuation)
  read -r -a TOKS <<<"$(printf '%s' "$q_norm" | tr -cs 'a-z0-9+' ' ')"

  tmp="$(mktemp)"; : >"$tmp"

  # Scan every JSONL line from every pack and score by token hits (with a few synonyms)
  for f in "${idx[@]}"; do
    while IFS= read -r line; do
      # Extract fields; tolerate missing keys
      src="$(printf '%s' "$line" | jq -r '.source // ""' 2>/dev/null || true)"
      txt="$(printf '%s' "$line" | jq -r '.text // ""' 2>/dev/null || true)"
      [ -n "$src$txt" ] || continue

      # Lowercased haystack
      hay="$(printf '%s\n%s\n' "$src" "$txt" | tr '[:upper:]' '[:lower:]')"

      score=0
      for t in "${TOKS[@]}"; do
        [ -n "$t" ] || continue
        # Simple synonym expansion
        case "$t" in
          binds|binding|bindings) pat='bindsym|bind|binding' ;;
          timer|timers)           pat='timer|timers|list-timers' ;;
          workspace|workspaces)   pat='workspace' ;;
          hypr|hyprland)          pat='hyprland' ;;
          *)                      pat="$(printf '%s' "$t" | sed 's/[][^$.*/\\]/\\&/g')" ;;
        esac
        if printf '%s' "$hay" | grep -qiE "$pat"; then
          score=$((score+1))
        fi
      done

      if [ "$score" -gt 0 ]; then
        # Keep full JSON for pretty print later; prepend numeric score for ranking
        printf '%s\t%s\t%s\n' "$score" "$f" "$line" >>"$tmp"
      fi
    done < "$f"
  done

  if [ ! -s "$tmp" ]; then
    echo "• No pack hits for: $q"
    rm -f "$tmp"
    return 0
  fi

  # Sort by score desc then stable
  # Print top 8 snippets nicely
  sort -t$'	' -k1,1nr "$tmp" | head -n 8 | while IFS=$'	' read -r score file line;
  do
    # Friendly output
    echo "$line" | jq -r '("• " + (.source // "(unknown)")) + " — " +
      (((.text // "") | gsub("\n"; " ") ) | .[0:220]) + "..."' 2>/dev/null \
      || printf '• (raw) %s\n' "$(echo "$line" | head -c 220)"
  done
  rm -f "$tmp"
}

reflect_note() {
  q="$1"
  echo "REFLECT: $(date -Iseconds) chat-query: ${q}" >> "$MEM/training.log"
}

if [ "${1:-}" = "--once" ]; then
  shift
  q="${1:-}"; [ -n "$q" ] || { usage; exit 2; }
  echo "🔎 Query: $q"
  search_all "$q"
  reflect_note "$q"
  exit 0
fi

# Interactive loop (Ctrl-C to exit)
echo "Speccy Chat (pack search). Type your query and press Enter. Ctrl-C to quit."
while true;
do
  printf "\n?> "
  if ! IFS= read -r q; then echo; break; fi
  [ -n "$q" ] || continue
  echo
  search_all "$q"
  reflect_note "$q"
done
