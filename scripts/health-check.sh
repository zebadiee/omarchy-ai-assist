#!/bin/bash

# Quantum-Forge System Health Verification Script
# Verifies all components of the integrated system are functioning correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OMARCHY_DIR="$HOME/.npm-global/omarchy-wagon"
BLUEPRINT_DIR="$PROJECT_ROOT/.omarchy/palimpsest/blueprints/quantum-forge"

# Helper functions
print_header() {
    echo -e "${BLUE}🔷 $1${NC}"
    echo "================================================================================"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo "ℹ️  $1"
}

check_file_exists() {
    local file="$1"
    local description="$2"

    if [[ -f "$file" ]]; then
        print_success "$description exists"
        return 0
    else
        print_error "$description missing: $file"
        return 1
    fi
}

check_directory_exists() {
    local dir="$1"
    local description="$2"

    if [[ -d "$dir" ]]; then
        print_success "$description exists"
        return 0
    else
        print_error "$description missing: $dir"
        return 1
    fi
}

check_command_exists() {
    local cmd="$1"
    local description="$2"

    if command -v "$cmd" &> /dev/null; then
        print_success "$description available"
        return 0
    else
        print_error "$description not found"
        return 1
    fi
}

check_node_module() {
    local module="$1"
    local description="$2"

    if cd "$PROJECT_ROOT" && npm list "$module" &> /dev/null; then
        print_success "$description available"
        return 0
    else
        print_error "$description not installed"
        return 1
    fi
}

# Main health check
main() {
    local errors=0
    local warnings=0

    print_header "Quantum-Forge System Health Check"
    print_info "Project Root: $PROJECT_ROOT"
    print_info "Timestamp: $(date)"
    echo

    # 1. Core Files and Directories
    print_header "1. Core Files and Directories"

    # Essential files
    check_file_exists "$PROJECT_ROOT/ai-collaboration-hub.js" "AI Collaboration Hub" || ((errors++))
    check_file_exists "$PROJECT_ROOT/quantum-forge" "Quantum-Forge CLI" || ((errors++))
    check_file_exists "$PROJECT_ROOT/QUANTUM_FORGE_INTEGRATION.md" "Integration Documentation" || ((errors++))
    check_file_exists "$PROJECT_ROOT/docs/CHANGELOG_QUANTUM_FORGE.md" "Changelog" || ((errors++))
    check_file_exists "$PROJECT_ROOT/docs/ROADMAP_PHASE2.md" "Phase 2 Roadmap" || ((errors++))

    # Essential directories
    check_directory_exists "$PROJECT_ROOT/mcp-superagents" "MCP Superagents" || ((errors++))
    check_directory_exists "$PROJECT_ROOT/cmd/quantum_forge" "Quantum-Forge Source" || ((errors++))
    check_directory_exists "$OMARCHY_DIR" "Omarchy Configuration" || ((errors++))
    check_directory_exists "$BLUEPRINT_DIR" "Blueprint Storage" || ((errors++))

    echo

    # 2. Command Line Tools
    print_header "2. Command Line Tools"

    check_command_exists "node" "Node.js" || ((errors++))
    check_command_exists "go" "Go Compiler" || ((errors++))

    # Check quantum-forge CLI
    if check_command_exists "$PROJECT_ROOT/quantum-forge" "Quantum-Forge CLI"; then
        # Test quantum-forge help
        if "$PROJECT_ROOT/quantum-forge" --help &> /dev/null; then
            print_success "Quantum-Forge CLI functional"
        else
            print_error "Quantum-Forge CLI not functional"
            ((errors++))
        fi
    else
        ((errors++))
    fi

    echo

    # 3. Node.js Dependencies
    print_header "3. Node.js Dependencies"

    check_node_module "@modelcontextprotocol/sdk" "MCP SDK" || ((errors++))

    # Check if we can run the AI hub
    if node "$PROJECT_ROOT/ai-collaboration-hub.js" --help &> /dev/null; then
        print_success "AI Collaboration Hub functional"
    else
        print_error "AI Collaboration Hub not functional"
        ((errors++))
    fi

    echo

    # 4. Configuration Files
    print_header "4. Configuration and State"

    # Check for configuration files
    local config_files=(
        "$OMARCHY_DIR/vbh-facts.json"
        "$OMARCHY_DIR/ai-collaboration.json"
        "$OMARCHY_DIR/semantic-cache.json"
        "$OMARCHY_DIR/mdl-history.json"
    )

    for config_file in "${config_files[@]}"; do
        if check_file_exists "$config_file" "$(basename "$config_file")"; then
            # Check if file is valid JSON
            if python3 -m json.tool "$config_file" &> /dev/null; then
                print_success "$(basename "$config_file") valid JSON"
            else
                print_warning "$(basename "$config_file") invalid JSON"
                ((warnings++))
            fi
        else
            # Not an error if file doesn't exist - it will be created
            print_info "$(basename "$config_file") will be created on first run"
        fi
    done

    echo

    # 5. Blueprint System
    print_header "5. Blueprint System"

    local blueprint_count=$(find "$BLUEPRINT_DIR" -name "*.json" 2>/dev/null | wc -l)
    if [[ $blueprint_count -gt 0 ]]; then
        print_success "$blueprint_count blueprint(s) found"

        # Check latest blueprint
        local latest_blueprint=$(find "$BLUEPRINT_DIR" -name "*.json" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        if [[ -n "$latest_blueprint" ]]; then
            print_info "Latest blueprint: $(basename "$latest_blueprint")"

            # Validate blueprint JSON
            if python3 -m json.tool "$latest_blueprint" &> /dev/null; then
                print_success "Latest blueprint valid JSON"
            else
                print_error "Latest blueprint invalid JSON"
                ((errors++))
            fi
        fi
    else
        print_warning "No blueprints found (run: ./quantum-forge -save-only)"
        ((warnings++))
    fi

    echo

    # 6. MCP Superagents
    print_header "6. MCP Superagents"

    local mcp_agents=(
        "workflow-coordinator-mcp.js"
        "knowledge-mcp.js"
        "token-manager-mcp.js"
    )

    for agent in "${mcp_agents[@]}"; do
        if check_file_exists "$PROJECT_ROOT/mcp-superagents/$agent" "$agent"; then
            # Basic syntax check
            if node -c "$PROJECT_ROOT/mcp-superagents/$agent" 2>/dev/null; then
                print_success "$agent syntax valid"
            else
                print_error "$agent syntax error"
                ((errors++))
            fi
        else
            ((errors++))
        fi
    done

    echo

    # 7. Performance Quick Tests
    print_header "7. Performance Quick Tests"

    # Test MDL calculation
    print_info "Testing MDL calculation..."
    if node "$PROJECT_ROOT/ai-collaboration-hub.js" mdl-calculate "$PROJECT_ROOT/package.json" &> /dev/null; then
        print_success "MDL calculation functional"
    else
        print_error "MDL calculation failed"
        ((errors++))
    fi

    # Test VBH validation
    print_info "Testing VBH validation..."
    echo "#VBH:1:abc12345
CONFIRM:{\"scope\":\"test\",\"site\":\"test\",\"open_tasks\":0,\"provider\":\"test\"}

Test content" > /tmp/test_vbh.txt

    if node "$PROJECT_ROOT/ai-collaboration-hub.js" vbh-validate /tmp/test_vbh.txt &> /dev/null; then
        print_success "VBH validation functional"
    else
        print_error "VBH validation failed"
        ((errors++))
    fi

    rm -f /tmp/test_vbh.txt

    # Test cache stats
    print_info "Testing cache system..."
    if node "$PROJECT_ROOT/ai-collaboration-hub.js" cache-stats &> /dev/null; then
        print_success "Cache system functional"
    else
        print_error "Cache system failed"
        ((errors++))
    fi

    echo

    # 8. Disk Space and Resources
    print_header "8. System Resources"

    # Check disk space
    local available_space=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $4}')
    local used_percent=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')

    print_info "Available disk space: $available_space"
    print_info "Disk usage: ${used_percent}%"

    if [[ $used_percent -gt 90 ]]; then
        print_error "Disk usage critically high"
        ((errors++))
    elif [[ $used_percent -gt 80 ]]; then
        print_warning "Disk usage high"
        ((warnings++))
    else
        print_success "Disk usage acceptable"
    fi

    # Check memory usage
    if command -v free &> /dev/null; then
        local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        print_info "Memory usage: ${mem_usage}%"

        if [[ $mem_usage -gt 90 ]]; then
            print_error "Memory usage critically high"
            ((errors++))
        elif [[ $mem_usage -gt 80 ]]; then
            print_warning "Memory usage high"
            ((warnings++))
        fi
    fi

    echo

    # 9. Summary
    print_header "Health Check Summary"

    if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
        print_success "All systems operational!"
        echo
        print_info "Quantum-Forge integration is fully functional"
        print_info "Ready for production use"
        exit_code=0
    elif [[ $errors -eq 0 ]]; then
        print_success "All systems operational with warnings"
        echo
        print_warning "Warnings detected: $warnings"
        print_info "System functional but monitor warnings"
        exit_code=1
    else
        print_error "System issues detected"
        echo
        print_error "Errors: $errors"
        print_warning "Warnings: $warnings"
        print_info "Address errors before production use"
        exit_code=2
    fi

    echo
    print_info "For troubleshooting, see: $PROJECT_ROOT/QUANTUM_FORGE_INTEGRATION.md"
    print_info "For Phase 2 plans, see: $PROJECT_ROOT/docs/ROADMAP_PHASE2.md"

    exit $exit_code
}

# Run main function
main "$@"