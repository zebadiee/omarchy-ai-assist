#!/bin/bash
#
# Omarchy AI Ecosystem Startup Script
#
# This script can be added to .bashrc or run manually to ensure
# the ecosystem is initialized and ready for use.
#

OMARCHY_DIR="$HOME/Documents/omarchy-ai-assist"
STARTUP_SCRIPT="$OMARCHY_DIR/startup-check.js"

# Only run if we're in an interactive shell and omarchy directory exists
if [[ $- == *i* ]] && [[ -d "$OMARCHY_DIR" ]]; then
    # Check if Node.js is available
    if command -v node >/dev/null 2>&1; then
        # Change to omarchy directory and run startup check
        cd "$OMARCHY_DIR" && node "$STARTUP_SCRIPT" 2>/dev/null || true
    fi
fi

# Export useful aliases for quick access
alias omai='cd $OMARCHY_DIR && node omai.js'
alias om-usage='cd $OMARCHY_DIR && node omai.js --usage'
alias om-init='cd $OMARCHY_DIR && node omarchy-init.js'
alias om-dashboard='cd $OMARCHY_DIR && ./ai-dashboard.sh'

# Show status if requested
if [[ "$1" == "status" ]]; then
    echo "🤖 Omarchy AI Ecosystem Status:"
    echo "   Directory: $OMARCHY_DIR"
    echo "   Commands: omai, om-usage, om-init, om-dashboard"
fi