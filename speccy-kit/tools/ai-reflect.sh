#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MEMORY_LOG="speccy-lab/memory/training.log"
VALIDATION_LOG="speccy-lab/logs/validation-history.log"

echo "${BLUE}🧠 AI Reflection & Analysis${NC}"
echo "==========================="
echo ""

# Show current training stage
STAGE=$(grep 'training_stage:' speccy-lab/config.yml | cut -d' ' -f2 || echo 'unknown')
echo "${YELLOW}Current Stage:${NC} $STAGE"
echo ""

if [[ -f "$MEMORY_LOG" ]]; then
    echo "${GREEN}📝 Recent Memory Entries:${NC}"
    echo "----------------------------"
    tail -n 10 "$MEMORY_LOG"
    echo ""
fi

if [[ -f "$VALIDATION_LOG" ]]; then
    echo "${GREEN}📊 Recent Validation Results:${NC}"
    echo "----------------------------"
    tail -n 5 "$VALIDATION_LOG"
    echo ""
fi

# Show learning suggestions
echo "${GREEN}💡 Learning Opportunities:${NC}"
echo "----------------------------"
echo "1. Review failed workflow steps for optimization"
echo "2. Identify repetitive manual tasks for automation"
echo "3. Analyze successful patterns for best practices"
echo "4. Consider expanding template coverage"
echo ""

# Memory statistics
if [[ -f "$MEMORY_LOG" ]]; then
    TOTAL_ENTRIES=$(wc -l < "$MEMORY_LOG")
    TODAY_ENTRIES=$(grep "$(date '+%Y-%m-%d')" "$MEMORY_LOG" | wc -l)
    echo "${BLUE}📈 Memory Stats:${NC}"
    echo "  Total entries: $TOTAL_ENTRIES"
    echo "  Today's entries: $TODAY_ENTRIES"
fi
