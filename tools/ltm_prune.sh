#!/bin/bash
# LTM Prune Tool
# Removes expired and duplicate entries from the long-term memory store

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMORY_DIR="$(dirname "$SCRIPT_DIR")/memory"
LTM_STORE="$MEMORY_DIR/ltm_store.jsonl"
LTM_BACKUP="$MEMORY_DIR/ltm_store.backup.jsonl"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }

# Usage
usage() {
    cat << USAGE_EOF
LTM Prune Tool - Clean up Long-Term Memory

USAGE:
    ltm_prune.sh [OPTIONS]

OPTIONS:
    -d, --dry-run          Show what would be removed without actually removing
    -k, --keep-days DAYS   Override TTL and keep entries newer than N days
    -r, --remove-duplicates    Remove duplicate entries (same text, type, scope)
    -b, --backup           Create backup before pruning (default: true)
    --no-backup            Skip backup creation
    -f, --force            Skip confirmation prompts
    -v, --verbose          Show detailed information
    -h, --help             Show this help

EXAMPLES:
    # Dry run to see what would be pruned
    ltm_prune.sh --dry-run

    # Prune expired entries with backup
    ltm_prune.sh

    # Remove entries older than 90 days (override TTL)
    ltm_prune.sh -k 90

    # Remove duplicates only
    ltm_prune.sh -r

    # Force prune without backup
    ltm_prune.sh --force --no-backup
USAGE_EOF
}

# Initialize defaults
DRY_RUN=false
KEEP_DAYS=""
REMOVE_DUPLICATES=false
BACKUP=true
FORCE=false
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -k|--keep-days)
            KEEP_DAYS="$2"
            shift 2
            ;;
        -r|--remove-duplicates)
            REMOVE_DUPLICATES=true
            shift
            ;;
        -b|--backup)
            BACKUP=true
            shift
            ;;
        --no-backup)
            BACKUP=false
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate keep-days
if [[ -n "$KEEP_DAYS" && ! "$KEEP_DAYS" =~ ^[0-9]+$ ]]; then
    log_error "Keep days must be a positive integer: $KEEP_DAYS"
    exit 1
fi

# Check if LTM store exists
if [[ ! -f "$LTM_STORE" ]]; then
    log_error "LTM store not found: $LTM_STORE"
    exit 1
fi

# Check if store is empty
if [[ ! -s "$LTM_STORE" ]]; then
    log_warn "LTM store is empty"
    exit 0
fi

# Get current stats
TOTAL_ENTRIES=$(wc -l < "$LTM_STORE")
log_info "LTM store contains $TOTAL_ENTRIES entries"

# Create backup if requested and not dry run
if [[ "$BACKUP" == "true" && "$DRY_RUN" == "false" ]]; then
    cp "$LTM_STORE" "$LTM_BACKUP"
    log_info "Created backup: $LTM_BACKUP"
fi

# Create temporary files for processing
TEMP_STORE=$(mktemp)
TEMP_EXPIRED=$(mktemp)
TEMP_DUPLICATES=$(mktemp)
TEMP_FINAL=$(mktemp)

# Cleanup function
cleanup() {
    rm -f "$TEMP_STORE" "$TEMP_EXPIRED" "$TEMP_DUPLICATES" "$TEMP_FINAL"
}
trap cleanup EXIT

# Copy original store to temp
cp "$LTM_STORE" "$TEMP_STORE"

# Calculate cutoff date
CUTOFF_DATE=""
if [[ -n "$KEEP_DAYS" ]]; then
    CUTOFF_DATE=$(date -d "$KEEP_DAYS days ago" -Iseconds 2>/dev/null || date -v-${KEEP_DAYS}d -Iseconds 2>/dev/null)
    if [[ -z "$CUTOFF_DATE" ]]; then
        log_error "Failed to calculate cutoff date"
        exit 1
    fi
    log_info "Keeping entries newer than: $CUTOFF_DATE ($KEEP_DAYS days)"
fi

# Function to check if entry is expired
is_expired() {
    local entry="$1"
    local ts=$(echo "$entry" | jq -r '.ts')
    local ttl_days=$(echo "$entry" | jq -r '.ttl_days')

    # If keep-days is specified, use that instead of TTL
    if [[ -n "$KEEP_DAYS" ]]; then
        [[ "$ts" < "$CUTOFF_DATE" ]] && return 0 || return 1
    fi

    # Use TTL from entry
    local expiry_date
    expiry_date=$(date -d "$ts + $ttl_days days" -Iseconds 2>/dev/null || date -v+${ttl_days}d -Iseconds -d "$ts" 2>/dev/null)

    if [[ -z "$expiry_date" ]]; then
        log_warn "Could not calculate expiry date for entry: $ts"
        return 1  # Keep if we can't calculate
    fi

    local current_date
    current_date=$(date -Iseconds)

    [[ "$current_date" > "$expiry_date" ]] && return 0 || return 1
}

# Function to identify duplicates
find_duplicates() {
    # Group by text, type, and scope, keep the newest
    jq -s 'group_by(.text, .type, .scope) | map(sort_by(.ts) | reverse | .[1:]) | flatten' "$TEMP_STORE" | jq -c '.[]'
}

# Process expired entries
log_info "Checking for expired entries..."
EXPIRED_COUNT=0

while IFS= read -r entry; do
    if is_expired "$entry"; then
        echo "$entry" >> "$TEMP_EXPIRED"
        ((EXPIRED_COUNT++))
        if [[ "$VERBOSE" == "true" ]]; then
            text=$(echo "$entry" | jq -r '.text')
            ts=$(echo "$entry" | jq -r '.ts')
            echo "  EXPIRED: $text ($ts)"
        fi
    fi
done < <(jq -c '.' "$TEMP_STORE")

if [[ $EXPIRED_COUNT -gt 0 ]]; then
    log_info "Found $EXPIRED_COUNT expired entries"
else
    log_info "No expired entries found"
fi

# Process duplicate entries
DUPLICATE_COUNT=0
if [[ "$REMOVE_DUPLICATES" == "true" ]]; then
    log_info "Checking for duplicate entries..."

    while IFS= read -r entry; do
        echo "$entry" >> "$TEMP_DUPLICATES"
        ((DUPLICATE_COUNT++))
        if [[ "$VERBOSE" == "true" ]]; then
            text=$(echo "$entry" | jq -r '.text')
            type=$(echo "$entry" | jq -r '.type')
            scope=$(echo "$entry" | jq -r '.scope')
            echo "  DUPLICATE: [$type|$scope] $text"
        fi
    done < <(find_duplicates)

    if [[ $DUPLICATE_COUNT -gt 0 ]]; then
        log_info "Found $DUPLICATE_COUNT duplicate entries"
    else
        log_info "No duplicate entries found"
    fi
else
    log_info "Skipping duplicate check (use -r to enable)"
fi

# Calculate total removals
TOTAL_REMOVALS=$((EXPIRED_COUNT + DUPLICATE_COUNT))

if [[ $TOTAL_REMOVALS -eq 0 ]]; then
    log_success "No entries need to be pruned"
    exit 0
fi

# Show summary
echo
echo -e "${YELLOW}=== Prune Summary ===${NC}"
echo "Total entries: $TOTAL_ENTRIES"
echo "Expired entries: $EXPIRED_COUNT"
echo "Duplicate entries: $DUPLICATE_COUNT"
echo "Total to remove: $TOTAL_REMOVALS"
echo "Entries remaining: $((TOTAL_ENTRIES - TOTAL_REMOVALS))"
echo

# Confirm unless forced or dry run
if [[ "$DRY_RUN" == "false" && "$FORCE" == "false" ]]; then
    echo -n "Proceed with pruning? [y/N] "
    read -r response
    if [[ ! "$response" =~ ^[yY] ]]; then
        log_info "Pruning cancelled"
        exit 0
    fi
fi

# Perform pruning
if [[ "$DRY_RUN" == "true" ]]; then
    log_info "DRY RUN: Would remove $TOTAL_REMOVALS entries"
    exit 0
fi

# Create new store without expired and duplicate entries
jq -c '.' "$TEMP_STORE" > "$TEMP_FINAL"

# Remove expired entries
if [[ $EXPIRED_COUNT -gt 0 ]]; then
    jq -c '.' "$TEMP_EXPIRED" | while IFS= read -r expired; do
        expired_text=$(echo "$expired" | jq -r '.text')
        # Remove lines containing this exact entry
        grep -vF "$expired" "$TEMP_FINAL" > "${TEMP_FINAL}.tmp" || true
        mv "${TEMP_FINAL}.tmp" "$TEMP_FINAL"
    done
fi

# Remove duplicate entries
if [[ $DUPLICATE_COUNT -gt 0 ]]; then
    jq -c '.' "$TEMP_DUPLICATES" | while IFS= read -r duplicate; do
        duplicate_text=$(echo "$duplicate" | jq -r '.text')
        # Remove lines containing this exact entry
        grep -vF "$duplicate" "$TEMP_FINAL" > "${TEMP_FINAL}.tmp" || true
        mv "${TEMP_FINAL}.tmp" "$TEMP_FINAL"
    done
fi

# Verify the new store
NEW_COUNT=$(wc -l < "$TEMP_FINAL")
EXPECTED_COUNT=$((TOTAL_ENTRIES - TOTAL_REMOVALS))

if [[ $NEW_COUNT -ne $EXPECTED_COUNT ]]; then
    log_error "Pruning error: expected $EXPECTED_COUNT entries, got $NEW_COUNT"
    if [[ "$BACKUP" == "true" ]]; then
        log_info "Restoring from backup..."
        cp "$LTM_BACKUP" "$LTM_STORE"
    fi
    exit 1
fi

# Replace original store
mv "$TEMP_FINAL" "$LTM_STORE"

# Show final stats
log_success "Pruning completed successfully"
echo "Removed: $TOTAL_REMOVALS entries"
echo "Remaining: $NEW_COUNT entries"
echo "Space saved: $(echo "scale=2; ($TOTAL_REMOVALS * 100) / $TOTAL_ENTRIES" | bc)%"

if [[ "$BACKUP" == "true" ]]; then
    echo "Backup available at: $LTM_BACKUP"
fi