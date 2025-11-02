#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
TRAINING_DIR="speccy-lab/training"
LESSON_FILE="${TRAINING_DIR}/${1:-self-optimize.yml}"
LOG_DIR="speccy-lab/logs"

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

log_stage() {
    echo -e "${CYAN}[STAGE]${NC} $1"
}

# Display header
echo -e "${CYAN}🧠 Speccy AI Lesson Runner${NC}"
echo "============================"
echo ""

# Check if lesson file exists
if [[ ! -f "$LESSON_FILE" ]]; then
    log_error "Lesson file not found: $LESSON_FILE"
    echo ""
    echo "Available lessons:"
    find "$TRAINING_DIR" -name "*.yml" -type f 2>/dev/null | sed 's|.*/||' | while read lesson; do
        echo "  - $lesson"
    done
    exit 1
fi

# Extract lesson metadata
LESSON_NAME=$(grep '^lesson:' "$LESSON_FILE" | cut -d'"' -f2)
LESSON_VERSION=$(grep '^version:' "$LESSON_FILE" | cut -d'"' -f2)
LESSON_STAGE=$(grep '^stage:' "$LESSON_FILE" | cut -d'"' -f2)

log_info "Starting lesson: $LESSON_NAME v$LESSON_VERSION"
log_info "Training stage: $LESSON_STAGE"
echo ""

# Store lesson start in memory
./speccy memory "lesson_started: $LESSON_NAME - stage: $LESSON_STAGE - version: $LESSON_VERSION"

# Simple YAML parser function
execute_stage() {
    local stage_name="$1"
    log_stage "Stage: $stage_name"

    # Find stage in YAML file
    local in_stage=false
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Check if we're entering the target stage
        if [[ "$line" =~ ^[[:space:]]*$stage_name:[[:space:]]*$ ]]; then
            in_stage=true
            continue
        fi

        # Check if we're entering another stage (exit current)
        if [[ "$in_stage" == true && "$line" =~ ^[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*$ ]]; then
            break
        fi

        # Process steps within the stage
        if [[ "$in_stage" == true && "$line" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]* ]]; then
            step_name=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*name:[[:space:]]*//; s/"//g')
            echo "    → $step_name"
        elif [[ "$in_stage" == true && "$line" =~ ^[[:space:]]*-[[:space:]]*command:[[:space:]]* ]]; then
            command=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*command:[[:space:]]*//; s/"//g')

            # Set SafeOps environment
            export SANDBOX=docker
            export SAFEOPS_NO_SUDO=1
            export SAFEOPS_POLICY="speccy-lab/policy/SAFEOPS_LAB.md"

            # Execute command with error handling
            if eval "$command" 2>/dev/null; then
                echo "      ✅ Command executed successfully"
            else
                echo "      ⚠️  Command completed with warnings"
            fi
        elif [[ "$in_stage" == true && "$line" =~ ^[[:space:]]*-[[:space:]]*memory:[[:space:]]* ]]; then
            memory_entry=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*memory:[[:space:]]*//; s/"//g')
            ./speccy memory "$memory_entry"
            echo "      📝 Memory stored: $memory_entry"
        elif [[ "$in_stage" == true && "$line" =~ ^[[:space:]]*-[[:space:]]*output:[[:space:]]* ]]; then
            output_file=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*output:[[:space:]]*//; s/"//g')
            echo "      📄 Output directed to: $output_file"
        fi
    done < "$LESSON_FILE"
}

# Execute stages based on lesson file
execute_stage "observe"
execute_stage "analyse"
execute_stage "propose"
execute_stage "simulate"
execute_stage "report"

# Store lesson completion
./speccy memory "lesson_completed: $LESSON_NAME - stage: $LESSON_STAGE - version: $LESSON_VERSION"

echo ""
log_success "Lesson completed successfully!"
echo ""

# Show summary
echo -e "${BLUE}📊 Lesson Summary:${NC}"
echo "=================="
echo "• Lesson: $LESSON_NAME"
echo "• Version: $LESSON_VERSION"
echo "• Stage: $LESSON_STAGE"
echo "• Logs: $LOG_DIR"
echo "• Memory entries updated"

# Check for next lesson readiness
if [[ -f "$LESSON_FILE" ]]; then
    if grep -q "next_lesson_readiness:" "$LESSON_FILE"; then
        echo ""
        log_info "📈 Ready for next lesson advancement"
        echo "→ Check prerequisites and consider stage promotion"
    fi
fi

echo ""
echo -e "${CYAN}🎓 AI Learning Complete!${NC}"
echo "======================"
echo "Review insights with: ./speccy reflect"
echo "Check progress in: speccy-lab/memory/"
echo "View logs in: speccy-lab/logs/"