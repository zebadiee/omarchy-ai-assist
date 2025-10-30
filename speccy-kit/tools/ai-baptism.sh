#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "${CYAN}🌊 Speccy AI Baptism v1.0${NC}"
echo "============================="
echo "${BLUE}Training AI assistant with SafeOps guardrails${NC}"
echo ""

# Check prerequisites
echo "${YELLOW}🔍 Checking prerequisites...${NC}"
if [[ ! -d "speccy-lab" ]]; then
    echo "${RED}❌ Training sandbox not found. Please run setup first.${NC}"
    exit 1
fi

if [[ ! -f "speccy-lab/config.yml" ]]; then
    echo "${RED}❌ Training configuration not found.${NC}"
    exit 1
fi

echo "${GREEN}✅ Prerequisites OK${NC}"
echo ""

# Stage 1: Observation & Shadow Mode
echo "${BLUE}👁️  Stage 1: Shadow Mode${NC}"
echo "AI observes real speccy operations..."

# Run validation and capture output
echo "→ Running workflow validation..."
./speccy workflow validate > speccy-lab/logs/validate.log 2>&1

# Store shadow mode observation
./speccy memory "shadow_mode_observation - completed workflow validation successfully"
echo "${GREEN}✅ Shadow mode complete${NC}"
echo ""

# Stage 2: Memory Formation
echo "${BLUE}🧠 Stage 2: Memory Formation${NC}"
echo "Creating experience replay..."

# Analyze the validation log
if grep -q "Registry OK" speccy-lab/logs/validate.log; then
    ./speccy memory "learned_pattern - workflow validation succeeds when registry is intact"
fi

if grep -q "CLI OK" speccy-lab/logs/validate.log; then
    ./speccy memory "learned_pattern - CLI routing works correctly"
fi

echo "${GREEN}✅ Memory formation complete${NC}"
echo ""

# Stage 3: Policy Integration
echo "${BLUE}🛡️  Stage 3: Policy Integration${NC}"
echo "Installing SafeOps guardrails..."

# Set environment variables
export SANDBOX=docker
export SAFEOPS_NO_SUDO=1
export SAFEOPS_POLICY="speccy-lab/policy/SAFEOPS_LAB.md"

echo "→ SafeOps environment configured"
echo "${GREEN}✅ Policy integration complete${NC}"
echo ""

# Stage 4: Controlled Autonomy Test
echo "${BLUE}🤖 Stage 4: Controlled Autonomy${NC}"
echo "Testing autonomous capabilities with guardrails..."

# Check current stage
CURRENT_STAGE=$(grep 'training_stage:' speccy-lab/config.yml | cut -d' ' -f2)
echo "→ Current training stage: $CURRENT_STAGE"

# Run dry-run autonomous test
if ./speccy autonomous; then
    echo "${GREEN}✅ Controlled autonomy test passed${NC}"
    ./speccy memory "milestone_achieved - controlled_autonomy_success"
else
    echo "${YELLOW}⚠️  Controlled autonomy test requires manual review${NC}"
    ./speccy memory "milestone_noted - controlled_autonomy_needs_review"
fi
echo ""

# Stage 5: Reflection & Learning
echo "${BLUE}📚 Stage 5: Reflection & Learning${NC}"
echo "AI self-assessment and improvement suggestions..."

# Generate reflection report
echo "→ Generating reflection report..."
./speccy reflect > speccy-lab/logs/reflection-$(date +%Y%m%d-%H%M%S).log

# Store learning insights
./speccy memory "reflection_complete - identified optimization opportunities in workflow execution"

echo "${GREEN}✅ Reflection complete${NC}"
echo ""

# Stage 6: Graduation Readiness
echo "${BLUE}🎓 Stage 6: Graduation Assessment${NC}"
echo "Evaluating readiness for next stage..."

# Count successful operations
SUCCESS_COUNT=$(grep -c "success\|complete\|OK" speccy-lab/memory/training.log 2>/dev/null || echo "0")
TOTAL_OPERATIONS=$(wc -l < speccy-lab/memory/training.log 2>/dev/null || echo "1")

echo "→ Success rate: $SUCCESS_COUNT/$TOTAL_OPERATIONS operations"

if [[ $SUCCESS_COUNT -gt $((TOTAL_OPERATIONS / 2)) ]]; then
    echo "${GREEN}✅ Ready for stage progression${NC}"
    ./speccy memory "graduation_ready - success rate adequate for advancement"
    
    # Suggest next stage
    case "$CURRENT_STAGE" in
        "sandbox")
            echo "→ Suggestion: Promote to 'advisor' stage"
            ;;
        "advisor")
            echo "→ Suggestion: Promote to 'operator' stage"
            ;;
        "operator")
            echo "→ Suggestion: Promote to 'autonomous' stage"
            ;;
        *)
            echo "→ Suggestion: Continue training at current stage"
            ;;
    esac
else
    echo "${YELLOW}⚠️  Additional training recommended${NC}"
    ./speccy memory "graduation_not_ready - requires more training"
fi

echo ""
echo "${CYAN}🎉 AI Baptism Complete!${NC}"
echo "========================="
echo "${GREEN}Training Summary:${NC}"
echo "• Shadow mode observations recorded"
echo "• Memory patterns established"
echo "• SafeOps guardrails integrated"
echo "• Controlled autonomy tested"
echo "• Reflection and learning completed"
echo "• Graduation readiness assessed"
echo ""
echo "${BLUE}Next Steps:${NC}"
echo "1. Review memory logs: ./speccy reflect"
echo "2. Test autonomous mode: ./speccy autonomous"
echo "3. Progress training stages as ready"
echo "4. Monitor AI performance and safety"
echo ""
echo "${YELLOW}Remember: Always keep SafeOps enabled!${NC}"
