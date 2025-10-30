#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKFLOW_REGISTRY="speccy-kit/workflows/registry.yml"
WORKFLOW_NAME="${2:-}"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if workflow name is provided
if [[ -z "$WORKFLOW_NAME" ]]; then
    echo "Available workflows:"
    if [[ -f "$WORKFLOW_REGISTRY" ]]; then
        # Parse YAML to list workflows (simple approach)
        grep -E "^\s+[a-zA-Z_][a-zA-Z0-9_]*:" "$WORKFLOW_REGISTRY" | sed 's/^\s*//;s/:.*//' | while read workflow; do
            echo "  - $workflow"
        done
    else
        echo "  (No workflow registry found)"
    fi
    echo ""
    echo "Usage: $0 <workflow-name>"
    echo "Example: $0 lint_test"
    exit 1
fi

# Check if workflow registry exists
if [[ ! -f "$WORKFLOW_REGISTRY" ]]; then
    log_error "Workflow registry not found: $WORKFLOW_REGISTRY"
    exit 1
fi

# Check if the workflow exists in registry
if ! grep -q "^\s*$WORKFLOW_NAME:" "$WORKFLOW_REGISTRY"; then
    log_error "Workflow '$WORKFLOW_NAME' not found in registry"
    echo ""
    echo "Available workflows:"
    grep -E "^\s+[a-zA-Z_][a-zA-Z0-9_]*:" "$WORKFLOW_REGISTRY" | sed 's/^\s*//;s/:.*//' | while read workflow; do
        echo "  - $workflow"
    done
    exit 1
fi

log_info "Running workflow: $WORKFLOW_NAME"

# Parse and execute workflow steps
echo ""
log_info "Workflow steps for '$WORKFLOW_NAME':"

# Simple YAML parser for workflow steps
in_workflow=false
step_count=0

while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

    # Check if we're entering the target workflow
    if [[ "$line" =~ ^[[:space:]]*$WORKFLOW_NAME:[[:space:]]*$ ]]; then
        in_workflow=true
        continue
    fi

    # Check if we're entering another workflow (exit current)
    if [[ "$in_workflow" == true && "$line" =~ ^[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*$ ]]; then
        break
    fi

    # Process steps within the workflow
    if [[ "$in_workflow" == true && "$line" =~ ^[[:space:]]*-+[[:space:]]*run:[[:space:]]* ]]; then
        step_count=$((step_count + 1))
        command=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*run:[[:space:]]*//')

        echo "  Step $step_count: $command"

        # Execute the command
        echo -n "  → "
        if eval "$command"; then
            log_success "Step $step_count completed successfully"
        else
            log_error "Step $step_count failed with exit code $?"
            echo ""
            log_error "Workflow '$WORKFLOW_NAME' failed at step $step_count"
            exit 1
        fi
        echo ""
    fi
done < "$WORKFLOW_REGISTRY"

if [[ "$step_count" -eq 0 ]]; then
    log_warning "No steps found for workflow '$WORKFLOW_NAME'"
    exit 1
fi

log_success "Workflow '$WORKFLOW_NAME' completed successfully!"