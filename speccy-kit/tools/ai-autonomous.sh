#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo "${BLUE}🤖 Speccy AI Autonomy Test${NC}"
echo "==========================="

# Check current training stage
STAGE=$(grep 'training_stage:' speccy-lab/config.yml | cut -d' ' -f2 || echo 'unknown')
echo "${YELLOW}Current Stage:${NC} $STAGE"

# Safety check: only allow autonomous mode in later stages
case "$STAGE" in
    "sandbox"|"advisor")
        echo "${RED}❌ Autonomy not allowed in stage: $STAGE${NC}"
        echo "Progress through stages: sandbox → advisor → operator → autonomous"
        exit 1
        ;;
    "operator"|"autonomous")
        echo "${GREEN}✅ Autonomy permitted in stage: $STAGE${NC}"
        ;;
    *)
        echo "${YELLOW}⚠️  Unknown stage: $STAGE - proceeding with caution${NC}"
        ;;
esac

# Run in dry-run mode for safety
echo ""
echo "${BLUE}🧪 Running dry-run autonomy test...${NC}"
echo ""

# Set SafeOps environment
export SANDBOX=docker
export SAFEOPS_NO_SUDO=1
export SAFEOPS_POLICY="speccy-lab/policy/SAFEOPS_LAB.md"

# Execute dry-run workflow
if DRY=1 ./speccy workflow lint_test; then
    echo "${GREEN}✅ Dry-run autonomy test passed${NC}"
    
    # Record successful autonomous execution
    ./speccy memory "autonomous_dry_run_success - stage: $STAGE"
    
    # Suggest next steps
    echo ""
    echo "${BLUE}🎯 Next Steps:${NC}"
    echo "1. Review dry-run output"
    echo "2. Consider promoting to full execution"
    echo "3. Expand autonomous capabilities"
else
    echo "${RED}❌ Dry-run autonomy test failed${NC}"
    ./speccy memory "autonomous_dry_run_failure - stage: $STAGE"
    exit 1
fi
