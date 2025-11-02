#!/usr/bin/env bash
set -euo pipefail

# Knowledge Pack Management Tool
# Handles installation, verification, and citation of offline knowledge packs

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LAB="$ROOT/speccy-lab"
PACK_DIR="$LAB/packs/${1:-}"
CMD="${2:-install}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Help function
show_help() {
  echo "Knowledge Pack Manager"
  echo ""
  echo "Usage: $0 <pack_id> <command> [options]"
  echo ""
  echo "Commands:"
  echo "  install    Install and index a knowledge pack"
  echo "  verify     Verify pack integrity (sample first 5 entries)"
  echo "  cite [N]   Retrieve N citations (default: 3)"
  echo "  list       List available packs"
  echo "  info       Show pack information"
  echo ""
  echo "Available packs:"
  for pack_dir in "$LAB/packs"/*/; do
    if [[ -d "$pack_dir" && -f "$pack_dir/pack.yml" ]]; then
      pack_name=$(basename "$pack_dir")
      echo "  - $pack_name"
    fi
  done
}

# List available packs
list_packs() {
  log_info "Available knowledge packs:"
  for pack_dir in "$LAB/packs"/*/; do
    if [[ -d "$pack_dir" && -f "$pack_dir/pack.yml" ]]; then
      pack_name=$(basename "$pack_dir")
      pack_version=$(yq -r '.version // "unknown"' "$pack_dir/pack.yml" 2>/dev/null || echo "unknown")
      echo "  • $pack_name (v$pack_version)"
    fi
  done
}

# Show pack information
show_pack_info() {
  if [[ ! -f "$PACK_DIR/pack.yml" ]]; then
    log_error "Pack manifest not found: $PACK_DIR/pack.yml"
    exit 1
  fi

  local pack_id=$(yq -r '.id // "unknown"' "$PACK_DIR/pack.yml")
  local pack_version=$(yq -r '.version // "unknown"' "$PACK_DIR/pack.yml")
  local pack_license=$(yq -r '.license // "unknown"' "$PACK_DIR/pack.yml")

  log_info "Pack Information: $pack_id"
  echo "Version: $pack_version"
  echo "License: $pack_license"
  echo "Directory: $PACK_DIR"

  if [[ -f "$PACK_DIR/index.jsonl" ]]; then
    local entry_count=$(wc -l < "$PACK_DIR/index.jsonl")
    echo "Indexed entries: $entry_count"
  else
    log_warning "Pack not installed yet (run 'install' command)"
  fi
}

# Install and index pack
install_pack() {
  if [[ ! -f "$PACK_DIR/pack.yml" ]]; then
    log_error "Pack manifest not found: $PACK_DIR/pack.yml"
    exit 1
  fi

  local pack_id="hyprland"
  local max_chars=1200
  local overlap=120

  # Try to get values from yq if available
  if command -v yq >/dev/null 2>&1; then
    pack_id=$(yq -r '.id // "unknown"' "$PACK_DIR/pack.yml" 2>/dev/null || echo "unknown")
    max_chars=$(yq -r '.normalize.max_chars // 1200' "$PACK_DIR/pack.yml" 2>/dev/null || echo "1200")
    overlap=$(yq -r '.normalize.overlap // 120' "$PACK_DIR/pack.yml" 2>/dev/null || echo "120")
  fi

  log_info "Installing pack: $pack_id"
  log_info "Chunk size: $max_chars chars, overlap: $overlap chars"

  # Create sources directory if it doesn't exist
  mkdir -p "$PACK_DIR/sources"

  # Check if source files exist
  local has_sources=false
  if command -v yq >/dev/null 2>&1; then
    while IFS= read -r glob; do
      for f in $PACK_DIR/$glob; do
        if [[ -f "$f" ]]; then
          has_sources=true
          break 2
        fi
      done
    done < <(yq -r '.sources[].path' "$PACK_DIR/pack.yml" 2>/dev/null || true)
  else
    # Default pattern when yq is not available
    for f in $PACK_DIR/sources/*; do
      if [[ -f "$f" ]]; then
        has_sources=true
        break
      fi
    done
  fi

  if [[ "$has_sources" == false ]]; then
    log_warning "No source files found. Creating sample content..."
    create_sample_content "$pack_id"
  fi

  # Process source files and create index
  log_info "Processing source files..."
  local temp_file=$(mktemp)

  if command -v yq >/dev/null 2>&1; then
    while IFS= read -r glob; do
      for f in $PACK_DIR/$glob; do
        [[ -f "$f" ]] || continue
        process_file "$f" "$pack_id" "$max_chars" "$overlap" "$temp_file"
      

      done
    done < <(yq -r '.sources[].path' "$PACK_DIR/pack.yml" 2>/dev/null || true)
  else
    # Default pattern when yq is not available
    for f in $PACK_DIR/sources/*; do
      [[ -f "$f" ]] || continue
      process_file "$f" "$pack_id" "$max_chars" "$overlap" "$temp_file"
    done
  fi

  # Convert to JSONL format
  log_info "Creating JSONL index..."
  cp "$temp_file" "$PACK_DIR/index.jsonl"

  rm -f "$temp_file"

  local entry_count=$(wc -l < "$PACK_DIR/index.jsonl")
  log_success "Pack installed: $entry_count entries indexed"
  log_info "Index file: $PACK_DIR/index.jsonl"
}

# Process individual file function
process_file() {
  local f="$1" pack_id="$2" max_chars="$3" overlap="$4" temp_file="$5"

  local rel_path="${f#$ROOT/}"
  local sha=$(sha256sum "$f" | awk '{print $1}')

  python3 "$ROOT/omarchy-ai-assist/speccy-kit/tools/chunker.py" "$f" "$pack_id" "$max_chars" "$overlap" "$temp_file" "$ROOT"



  local entry_count=$(wc -l < "$PACK_DIR/index.jsonl")
  log_success "Pack installed: $entry_count entries indexed"
  log_info "Index file: $PACK_DIR/index.jsonl"
}

# Create sample content for demonstration
create_sample_content() {
  local pack_id="$1"

  case "$pack_id" in
    "hyprland")
      cat > "$PACK_DIR/sources/hyprland-config.md" <<'EOF'
# Hyprland Configuration

## Basic Configuration
Hyprland uses a simple configuration file format located at ~/.config/hypr/hyprland.conf.

## Monitor Configuration
```
monitor=,preferred,auto,auto
```

## Input Configuration
```
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = no
    }
    sensitivity = 0
}
```

## Window Rules
Window rules allow you to set properties for specific applications:
```
windowrule=float,^(pavucontrol)$
windowrule=size 50% 50%,^(firefox)$
```

## Key Bindings
Key bindings are defined using the bind keyword:
```
bind = SUPER, Return, exec, kitty
bind = SUPER, Q, killactive
bind = SUPER, M, exit
```

## Animation Settings
```
animations {
    enabled = yes
    animation = windows, 1, 7, default
    animation = workspaces, 1, 6, default
}
```
EOF
      ;;
    "systemd")
      cat > "$PACK_DIR/sources/systemd-units.md" <<'EOF'
# Systemd Units

## Service Files
Systemd service files define how services are managed.

## Basic Service Structure
```ini
[Unit]
Description=My Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/my-service
Restart=always

[Install]
WantedBy=multi-user.target
```

## Security Hardening
```ini
[Service]
# Basic sandboxing
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
NoNewPrivileges=true

# Resource limits
MemoryMax=512M
CPUQuota=50%
```

## Timer Units
Timer units replace cron for scheduled tasks:
```ini
[Unit]
Description=Daily backup

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```
EOF
      ;;
    *)
      mkdir -p "$PACK_DIR/sources"
      echo "# Sample content for $pack_id" > "$PACK_DIR/sources/sample.md"
      echo "This is sample knowledge content for the $pack_id pack." >> "$PACK_DIR/sources/sample.md"
      ;;
  esac
}

# Verify pack integrity
verify_pack() {
  if [[ ! -f "$PACK_DIR/index.jsonl" ]]; then
    log_error "Pack not installed. Run 'install' first."
    exit 1
  fi

  log_info "Verifying pack integrity (sample first 5 entries)..."

  local errors=0
  head -n 5 "$PACK_DIR/index.jsonl" | while IFS= read -r line; do
    local src=$(echo "$line" | jq -r '.source')
    local expected_sha=$(echo "$line" | jq -r '.sha256')

    if [[ -f "$ROOT/$src" ]]; then
      local actual_sha=$(sha256sum "$ROOT/$src" | awk '{print $1}')
      if [[ "$expected_sha" == "$actual_sha" ]]; then
        log_success "OK  $src"
      else
        log_error "MISMATCH $src (expected: $expected_sha, actual: $actual_sha)"
        errors=$((errors + 1))
      fi
    else
      log_warning "Source file not found: $src"
    fi
  done

  if [[ $errors -eq 0 ]]; then
    log_success "Pack verification completed successfully"
  else
    log_error "Pack verification failed with $errors errors"
    exit 1
  fi
}

# Retrieve citations from pack
cite_pack() {
  local count="${3:-3}"

  if [[ ! -f "$PACK_DIR/index.jsonl" ]]; then
    log_error "Pack not installed. Run 'install' first."
    exit 1
  fi

  local total_entries=$(wc -l < "$PACK_DIR/index.jsonl")
  if [[ $total_entries -eq 0 ]]; then
    log_warning "No entries found in pack"
    return
  fi

  log_info "Retrieving $count citations from pack (total: $total_entries entries)..."

  # Random sample of entries
  : "${PACK_SEED:=42}"
  shuf --random-source=<(yes "$PACK_SEED") -n "$count" "$PACK_DIR/index.jsonl" | while IFS= read -r line; do
    echo "$line" | jq -r '"• " + (.source // "(unknown)") + " — " + ((.text // "" ) | gsub("\n"; " ") | .[0:200]) + "..."' 2>/dev/null \
      || printf '• (raw) %s\n' "$(echo "$line" | head -c 200)"
  done
}

# Main command routing
case "${1:-}" in
  -h|--help)
    show_help
    exit 0
    ;;
  list)
    find "$LAB/packs" -maxdepth 1 -mindepth 1 -type d -printf "%f\n"
    exit 0
    ;;
  "")
    show_help
    exit 2
    ;;
esac

if [[ ! -d "$PACK_DIR" ]]; then
  log_error "Pack not found: $PACK_DIR"
  echo ""
  list_packs
  exit 1
fi

case "$CMD" in
  install)
    install_pack
    ;;
  verify)
    verify_pack
    ;;
  cite)
    cite_pack "$@"
    ;;
  info)
    show_pack_info
    ;;
  list)
    find "$LAB/packs" -maxdepth 1 -mindepth 1 -type d -printf "%f\n"
    ;;
  stats)
    total=$(wc -l < "$PACK_DIR/index.jsonl" 2>/dev/null || echo 0)
    echo "$1: $total entries"
    ;;
  search)
    q="${3:-}"; [ -n "$q" ] || { echo "Usage: pack.sh <pack> search <query>"; exit 2; }
    grep -i --color=never -n "$q" "$PACK_DIR/index.jsonl" | head -n 10 | cut -d: -f1 | while IFS= read -r line; do
      sed -n "${line}p" "$PACK_DIR/index.jsonl" | jq -r '"• " + .source + " — " + (.text | gsub("\n"; " ") | .[0:160]) + "..."' || printf '• (raw) %s\n' "$(sed -n "${line}p" "$PACK_DIR/index.jsonl" | head -c 160)"
    done
    ;;
  *)
    echo "Unknown command: $CMD"
    echo ""
    show_help
    exit 2
    ;;
esac