#!/bin/bash
# LTM Append Tool
# Adds new memory entries to the long-term memory store

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMORY_DIR="$(dirname "$SCRIPT_DIR")/memory"
LTM_STORE="$MEMORY_DIR/ltm_store.jsonl"

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
LTM Append Tool - Add entries to Long-Term Memory

USAGE:
    ltm_append.sh [OPTIONS]

OPTIONS:
    -t, --type TYPE        Memory type: fact|preference|term|milestone
    -s, --scope SCOPE      Memory scope: global|project|module
    -w, --who WHO          Source: declan|system|agent (default: agent)
    --ttl DAYS             TTL in days (default: 180 for facts, 365 for others)
    -f, --file FILE        Evidence file path
    -l, --line LINE        Evidence line number
    -q, --quote QUOTE      Evidence quote
    --text TEXT            Memory text (can be read from stdin)
    -h, --help             Show this help

EXAMPLES:
    # Add a fact with evidence
    ltm_append.sh -t fact -s project -f src/auth.js -l 45 -q "jwt.sign()" --text "Auth service uses JWT tokens"

    # Add a user preference
    ltm_append.sh -t preference -s global -w declan --text "User prefers dark theme"

    # Add from stdin
    echo "API endpoint returns JSON" | ltm_append.sh -t fact -s project -f api.js

    # Quick add (minimal options)
    ltm_append.sh --text "MCP = Model Context Protocol" -t term -s global
USAGE_EOF
}

# Initialize defaults
TYPE=""
SCOPE=""
WHO="agent"
TTL=""
TEXT=""
EVIDENCE_FILE=""
EVIDENCE_LINE=""
EVIDENCE_QUOTE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            TYPE="$2"
            shift 2
            ;;
        -s|--scope)
            SCOPE="$2"
            shift 2
            ;;
        -w|--who)
            WHO="$2"
            shift 2
            ;;
        --ttl)
            TTL="$2"
            shift 2
            ;;
        -f|--file)
            EVIDENCE_FILE="$2"
            shift 2
            ;;
        -l|--line)
            EVIDENCE_LINE="$2"
            shift 2
            ;;
        -q|--quote)
            EVIDENCE_QUOTE="$2"
            shift 2
            ;;
        --text)
            TEXT="$2"
            shift 2
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

# Read text from stdin if not provided
if [[ -z "$TEXT" ]]; then
    if [[ -t 0 ]]; then
        log_error "No text provided. Use --text or pipe from stdin."
        usage
        exit 1
    else
        TEXT=$(cat)
    fi
fi

# Validate required fields
if [[ -z "$TYPE" ]]; then
    log_error "Memory type is required (-t|--type)"
    usage
    exit 1
fi

if [[ ! "$TYPE" =~ ^(fact|preference|term|milestone)$ ]]; then
    log_error "Invalid type: $TYPE. Must be: fact|preference|term|milestone"
    exit 1
fi

if [[ -z "$SCOPE" ]]; then
    log_error "Memory scope is required (-s|--scope)"
    usage
    exit 1
fi

if [[ ! "$SCOPE" =~ ^(global|project|module)$ ]]; then
    log_error "Invalid scope: $SCOPE. Must be: global|project|module"
    exit 1
fi

if [[ -z "$WHO" ]]; then
    log_error "Source is required (-w|--who)"
    usage
    exit 1
fi

if [[ ! "$WHO" =~ ^(declan|system|agent)$ ]]; then
    log_error "Invalid source: $WHO. Must be: declan|system|agent"
    exit 1
fi

# Set default TTL based on type
if [[ -z "$TTL" ]]; then
    case "$TYPE" in
        "fact") TTL=180 ;;
        "preference"|"term"|"milestone") TTL=365 ;;
    esac
fi

# Validate TTL is a number
if ! [[ "$TTL" =~ ^[0-9]+$ ]]; then
    log_error "TTL must be a positive integer: $TTL"
    exit 1
fi

# Create memory directory if it doesn't exist
mkdir -p "$MEMORY_DIR"

# Initialize LTM store if it doesn't exist
if [[ ! -f "$LTM_STORE" ]]; then
    touch "$LTM_STORE"
    log_info "Created LTM store: $LTM_STORE"
fi

# Build evidence array
EVIDENCE_JSON="[]"

if [[ -n "$EVIDENCE_FILE" ]]; then
    # Validate file exists
    if [[ ! -f "$EVIDENCE_FILE" ]]; then
        log_error "Evidence file not found: $EVIDENCE_FILE"
        exit 1
    fi

    # Set default line if not provided
    if [[ -z "$EVIDENCE_LINE" ]]; then
        EVIDENCE_LINE=0
    fi

    # Validate line number
    if ! [[ "$EVIDENCE_LINE" =~ ^[0-9]+$ ]]; then
        log_error "Line number must be a positive integer: $EVIDENCE_LINE"
        exit 1
    fi

    # Extract quote if not provided
    if [[ -z "$EVIDENCE_QUOTE" ]]; then
        if [[ "$EVIDENCE_LINE" -gt 0 ]]; then
            EVIDENCE_QUOTE=$(sed -n "${EVIDENCE_LINE}p" "$EVIDENCE_FILE" | head -c 200)
        else
            EVIDENCE_QUOTE="File: $EVIDENCE_FILE"
        fi
    fi

    # Escape JSON strings
    EVIDENCE_FILE_ESC=$(echo "$EVIDENCE_FILE" | sed 's/"/\\"/g')
    EVIDENCE_QUOTE_ESC=$(echo "$EVIDENCE_QUOTE" | sed 's/"/\\"/g' | tr '\n' ' ')

    EVIDENCE_JSON="[{\"file\":\"$EVIDENCE_FILE_ESC\",\"line\":$EVIDENCE_LINE,\"quote\":\"$EVIDENCE_QUOTE_ESC\"}]"
fi

# Create timestamp
TIMESTAMP=$(date -Iseconds)

# Escape text for JSON
TEXT_ESC=$(echo "$TEXT" | sed 's/"/\\"/g' | tr '\n' ' ')

# Build JSON entry
JSON_ENTRY="{\"ts\":\"$TIMESTAMP\",\"who\":\"$WHO\",\"type\":\"$TYPE\",\"scope\":\"$SCOPE\",\"text\":\"$TEXT_ESC\",\"evidence\":$EVIDENCE_JSON,\"ttl_days\":$TTL}"

# Validate JSON
if ! echo "$JSON_ENTRY" | jq . >/dev/null 2>&1; then
    log_error "Invalid JSON generated"
    exit 1
fi

# Append to LTM store
echo "$JSON_ENTRY" >> "$LTM_STORE"

log_success "Memory entry added to LTM store"
log_info "Type: $TYPE, Scope: $SCOPE, TTL: ${TTL} days"
log_info "Text: $TEXT"

# Show current store size
STORE_SIZE=$(wc -l < "$LTM_STORE")
log_info "LTM store now contains $STORE_SIZE entries"