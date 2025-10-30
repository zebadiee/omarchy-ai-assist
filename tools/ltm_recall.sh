#!/bin/bash
# LTM Recall Tool
# Searches and retrieves memory entries from the long-term memory store

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
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }

# Usage
usage() {
    cat << USAGE_EOF
LTM Recall Tool - Search Long-Term Memory

USAGE:
    ltm_recall.sh [OPTIONS] [QUERY]

OPTIONS:
    -q, --query QUERY        Search query string
    -t, --type TYPE          Filter by type: fact|preference|term|milestone
    -s, --scope SCOPE        Filter by scope: global|project|module
    -w, --who WHO            Filter by source: declan|system|agent
    -d, --days DAYS          Only entries within last N days
    -l, --limit LIMIT        Maximum results to return (default: 10)
    -r, --recent             Show most recent entries
    -c, --count              Show only count of matching entries
    -f, --format FORMAT      Output format: json|pretty|summary (default: pretty)
    -h, --help               Show this help

EXAMPLES:
    # Search for specific text
    ltm_recall.sh -q "JWT authentication"

    # Filter by type and scope
    ltm_recall.sh -t fact -s project

    # Recent preferences
    ltm_recall.sh -t preference --recent -l 5

    # Count all memories
    ltm_recall.sh --count

    # Search from last 30 days
    ltm_recall.sh -d 30 "API"

    # JSON output for scripting
    ltm_recall.sh -q "theme" -f json
USAGE_EOF
}

# Initialize defaults
QUERY=""
TYPE=""
SCOPE=""
WHO=""
DAYS=""
LIMIT=10
RECENT=false
COUNT=false
FORMAT="pretty"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -q|--query)
            QUERY="$2"
            shift 2
            ;;
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
        -d|--days)
            DAYS="$2"
            shift 2
            ;;
        -l|--limit)
            LIMIT="$2"
            shift 2
            ;;
        -r|--recent)
            RECENT=true
            shift
            ;;
        -c|--count)
            COUNT=true
            shift
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            # If no query flag specified, treat as query
            if [[ -z "$QUERY" ]]; then
                QUERY="$1"
            else
                log_error "Multiple queries provided. Use -q for explicit query."
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate format
if [[ ! "$FORMAT" =~ ^(json|pretty|summary)$ ]]; then
    log_error "Invalid format: $FORMAT. Must be: json|pretty|summary"
    exit 1
fi

# Validate limit
if ! [[ "$LIMIT" =~ ^[0-9]+$ ]]; then
    log_error "Limit must be a positive integer: $LIMIT"
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

# Validate days
if [[ -n "$DAYS" && ! "$DAYS" =~ ^[0-9]+$ ]]; then
    log_error "Days must be a positive integer: $DAYS"
    exit 1
fi

# Validate type
if [[ -n "$TYPE" && ! "$TYPE" =~ ^(fact|preference|term|milestone)$ ]]; then
    log_error "Invalid type: $TYPE. Must be: fact|preference|term|milestone"
    exit 1
fi

# Validate scope
if [[ -n "$SCOPE" && ! "$SCOPE" =~ ^(global|project|module)$ ]]; then
    log_error "Invalid scope: $SCOPE. Must be: global|project|module"
    exit 1
fi

# Validate who
if [[ -n "$WHO" && ! "$WHO" =~ ^(declan|system|agent)$ ]]; then
    log_error "Invalid source: $WHO. Must be: declan|system|agent"
    exit 1
fi

# Calculate date threshold
DATE_THRESHOLD=""
if [[ -n "$DAYS" ]]; then
    DATE_THRESHOLD=$(date -d "$DAYS days ago" -Iseconds 2>/dev/null || date -v-${DAYS}d -Iseconds 2>/dev/null)
    if [[ -z "$DATE_THRESHOLD" ]]; then
        log_error "Failed to calculate date threshold"
        exit 1
    fi
fi

# Build jq filter
JQ_FILTER="."

# Add date filter
if [[ -n "$DATE_THRESHOLD" ]]; then
    JQ_FILTER="$JQ_FILTER | select(.ts >= \"$DATE_THRESHOLD\")"
fi

# Add type filter
if [[ -n "$TYPE" ]]; then
    JQ_FILTER="$JQ_FILTER | select(.type == \"$TYPE\")"
fi

# Add scope filter
if [[ -n "$SCOPE" ]]; then
    JQ_FILTER="$JQ_FILTER | select(.scope == \"$SCOPE\")"
fi

# Add who filter
if [[ -n "$WHO" ]]; then
    JQ_FILTER="$JQ_FILTER | select(.who == \"$WHO\")"
fi

# Add query filter
if [[ -n "$QUERY" ]]; then
    # Case-insensitive search in text field
    JQ_FILTER="$JQ_FILTER | select(.text | test(\"$QUERY\"; \"i\"))"
fi

# Execute search
RESULTS=$(jq -c "$JQ_FILTER" "$LTM_STORE" 2>/dev/null)

if [[ $? -ne 0 ]]; then
    log_error "Failed to search LTM store"
    exit 1
fi

# Handle recent sorting
if [[ "$RECENT" == "true" ]]; then
    RESULTS=$(echo "$RESULTS" | jq -s 'sort_by(.ts) | reverse | .[]')
fi

# Count results
RESULT_COUNT=$(echo "$RESULTS" | wc -l)

if [[ "$COUNT" == "true" ]]; then
    echo "$RESULT_COUNT"
    exit 0
fi

# Apply limit
if [[ "$RESULT_COUNT" -gt "$LIMIT" ]]; then
    RESULTS=$(echo "$RESULTS" | head -n "$LIMIT")
    TRUNCATED=true
else
    TRUNCATED=false
fi

# Output results
if [[ -z "$RESULTS" ]]; then
    log_warn "No matching memories found"
    exit 0
fi

case "$FORMAT" in
    "json")
        if [[ "$TRUNCATED" == "true" ]]; then
            echo "$RESULTS" | jq -s '.'
        else
            echo "$RESULTS" | jq -s '.'
        fi
        ;;
    "pretty")
        echo -e "${CYAN}=== Memory Search Results ===${NC}"
        echo "Query: ${QUERY:-<all>}"
        [[ -n "$TYPE" ]] && echo "Type: $TYPE"
        [[ -n "$SCOPE" ]] && echo "Scope: $SCOPE"
        [[ -n "$WHO" ]] && echo "Source: $WHO"
        [[ -n "$DAYS" ]] && echo "Within: $DAYS days"
        echo "Results: $(echo "$RESULTS" | wc -l) entries"
        echo

        echo "$RESULTS" | while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                # Parse JSON fields
                ts=$(echo "$line" | jq -r '.ts')
                who=$(echo "$line" | jq -r '.who')
                type=$(echo "$line" | jq -r '.type')
                scope=$(echo "$line" | jq -r '.scope')
                text=$(echo "$line" | jq -r '.text')
                ttl=$(echo "$line" | jq -r '.ttl_days')
                evidence_count=$(echo "$line" | jq -e '.evidence | length' 2>/dev/null || echo "0")

                # Format timestamp
                ts_formatted=$(date -d "$ts" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$ts")

                echo -e "${GREEN}[$type|$scope]${NC} ${YELLOW}($who)${NC} ${CYAN}$ts_formatted${NC}"
                echo "$text"

                if [[ "$evidence_count" -gt 0 ]]; then
                    echo -e "${BLUE}Evidence: $evidence_count source(s)${NC}"
                fi

                echo -e "${BLUE}TTL: ${ttl} days${NC}"
                echo
            fi
        done

        if [[ "$TRUNCATED" == "true" ]]; then
            echo -e "${YELLOW}... (showing first $LIMIT of $RESULT_COUNT results)${NC}"
        fi
        ;;
    "summary")
        echo "$RESULTS" | while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                text=$(echo "$line" | jq -r '.text')
                type=$(echo "$line" | jq -r '.type')
                scope=$(echo "$line" | jq -r '.scope')
                echo "[$type|$scope] $text"
            fi
        done
        ;;
esac

log_success "Found $(echo "$RESULTS" | wc -l) matching memories"