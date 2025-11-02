#!/bin/bash

# Quantum-Forge Production Deployment Script
# Deploys the integrated Quantum-Forge system to production

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_ENV="${1:-production}"
BACKUP_DIR="$HOME/.omarchy/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Helper functions
print_header() {
    echo -e "${BLUE}🚀 $1${NC}"
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

# Pre-flight checks
preflight_check() {
    print_header "Pre-flight Deployment Checks"

    # Check if we're in the right directory
    if [[ ! -f "$PROJECT_ROOT/quantum-forge" ]]; then
        print_error "quantum-forge binary not found. Run build first."
        exit 1
    fi

    # Check Node.js dependencies
    if ! npm list --production &> /dev/null; then
        print_error "Node.js dependencies not installed. Run 'npm install --production'"
        exit 1
    fi

    # Check Go dependencies
    if ! cd "$PROJECT_ROOT/cmd/quantum_forge" && go mod verify &> /dev/null; then
        print_error "Go dependencies not verified"
        exit 1
    fi

    # Check health
    if ! "$PROJECT_ROOT/scripts/health-check.sh" &> /dev/null; then
        print_warning "Health check has warnings. Review before proceeding."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Deployment cancelled"
            exit 0
        fi
    fi

    print_success "Pre-flight checks passed"
    echo
}

# Create backup
create_backup() {
    print_header "Creating System Backup"

    mkdir -p "$BACKUP_DIR"

    local backup_name="omarchy_backup_$TIMESTAMP"
    local backup_path="$BACKUP_DIR/$backup_name"

    print_info "Creating backup: $backup_name"

    mkdir -p "$backup_path"

    # Backup configuration files
    if [[ -d "$HOME/.npm-global/omarchy-wagon" ]]; then
        cp -r "$HOME/.npm-global/omarchy-wagon" "$backup_path/"
        print_success "Configuration files backed up"
    fi

    # Backup blueprints
    if [[ -d "$PROJECT_ROOT/.omarchy" ]]; then
        cp -r "$PROJECT_ROOT/.omarchy" "$backup_path/"
        print_success "Blueprints backed up"
    fi

    # Backup current binary
    if [[ -f "$PROJECT_ROOT/quantum-forge" ]]; then
        cp "$PROJECT_ROOT/quantum-forge" "$backup_path/"
        print_success "Binary backed up"
    fi

    # Create backup metadata
    cat > "$backup_path/backup_info.txt" << EOF
Backup created: $(date)
Environment: $DEPLOY_ENV
Git commit: $(git rev-parse HEAD 2>/dev/null || echo "Unknown")
Node.js version: $(node --version)
Go version: $(go version)
System: $(uname -a)
EOF

    print_success "Backup completed: $backup_path"
    echo
}

# Deploy binaries and scripts
deploy_binaries() {
    print_header "Deploying Binaries and Scripts"

    # Ensure deployment directories exist
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/share/omarchy"

    # Deploy quantum-forge binary
    if [[ "$DEPLOY_ENV" == "production" ]]; then
        cp "$PROJECT_ROOT/quantum-forge" "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/quantum-forge"
        print_success "quantum-forge binary deployed"
    fi

    # Deploy scripts
    cp "$PROJECT_ROOT/scripts/health-check.sh" "$HOME/.local/share/omarchy/"
    chmod +x "$HOME/.local/share/omarchy/health-check.sh"
    print_success "Health check script deployed"

    # Update PATH if needed
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        print_warning "$HOME/.local/bin not in PATH"
        print_info "Add to PATH: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi

    echo
}

# Configure environment
configure_environment() {
    print_header "Configuring Environment"

    # Create environment configuration
    local env_file="$HOME/.omarchy/environment"
    mkdir -p "$(dirname "$env_file")"

    cat > "$env_file" << EOF
# Quantum-Forge Environment Configuration
# Generated: $(date)
# Environment: $DEPLOY_ENV

# VBH Configuration
export OM_VBH_SCOPE="unified"
export OM_VBH_SITE="Omarchy"
export OM_VBH_PROVIDER="quantum-forge"
export OM_VBH_COUNTER="1"

# Paths
export OMARCHY_ROOT="$PROJECT_ROOT"
export OM_BLUEPRINT_DIR="$PROJECT_ROOT/.omarchy/palimpsest/blueprints"
export OM_CONFIG_DIR="$HOME/.npm-global/omarchy-wagon"

# Cache Configuration
export OM_CACHE_TTL="86400"  # 24 hours
export OM_CACHE_MAX_SIZE="1000"

# Performance
export OM_MAX_WORKERS="4"
export OM_TIMEOUT="300"  # 5 minutes

# Deployment
export OM_DEPLOY_ENV="$DEPLOY_ENV"
export OM_DEPLOY_TIMESTAMP="$TIMESTAMP"
EOF

    print_success "Environment configuration created: $env_file"

    # Source the environment file for this session
    # shellcheck source=/dev/null
    source "$env_file"

    print_success "Environment configured"
    echo
}

# Setup systemd services (optional)
setup_services() {
    if [[ "$DEPLOY_ENV" != "production" ]]; then
        print_info "Skipping service setup (non-production environment)"
        return
    fi

    print_header "Setting Up System Services"

    # Create systemd service for quantum-forge monitor (future feature)
    # This is a placeholder for future monitoring service

    print_info "System service setup (placeholder for future monitoring)"
    print_warning "Service configuration will be added in Phase 2"
    echo
}

# Verify deployment
verify_deployment() {
    print_header "Verifying Deployment"

    # Check quantum-forge binary
    if command -v quantum-forge &> /dev/null; then
        print_success "quantum-forge binary accessible"

        # Test quantum-forge
        if quantum-forge --help &> /dev/null; then
            print_success "quantum-forge functional"
        else
            print_error "quantum-forge not functional"
            return 1
        fi
    else
        print_error "quantum-forge not in PATH"
        return 1
    fi

    # Check AI hub functionality
    if node "$PROJECT_ROOT/ai-collaboration-hub.js" --help &> /dev/null; then
        print_success "AI Collaboration Hub functional"
    else
        print_error "AI Collaboration Hub not functional"
        return 1
    fi

    # Check MCP agents
    local mcp_agents=(
        "workflow-coordinator-mcp.js"
        "knowledge-mcp.js"
        "token-manager-mcp.js"
    )

    for agent in "${mcp_agents[@]}"; do
        if node -c "$PROJECT_ROOT/mcp-superagents/$agent" &> /dev/null; then
            print_success "$agent syntax valid"
        else
            print_error "$agent syntax error"
            return 1
        fi
    done

    print_success "Deployment verification completed"
    echo
}

# Run post-deployment tests
run_tests() {
    print_header "Running Post-Deployment Tests"

    # Test blueprint generation
    print_info "Testing blueprint generation..."
    if quantum-forge -save-only -open-tasks 1 &> /dev/null; then
        print_success "Blueprint generation test passed"
    else
        print_error "Blueprint generation test failed"
        return 1
    fi

    # Test MDL calculation
    print_info "Testing MDL calculation..."
    if node "$PROJECT_ROOT/ai-collaboration-hub.js" mdl-calculate "$PROJECT_ROOT/package.json" &> /dev/null; then
        print_success "MDL calculation test passed"
    else
        print_error "MDL calculation test failed"
        return 1
    fi

    # Test cache system
    print_info "Testing cache system..."
    if node "$PROJECT_ROOT/ai-collaboration-hub.js" cache-stats &> /dev/null; then
        print_success "Cache system test passed"
    else
        print_error "Cache system test failed"
        return 1
    fi

    print_success "All post-deployment tests passed"
    echo
}

# Cleanup old backups
cleanup_backups() {
    print_header "Cleaning Up Old Backups"

    # Keep only the last 10 backups
    local backup_count=$(find "$BACKUP_DIR" -name "omarchy_backup_*" -type d | wc -l)

    if [[ $backup_count -gt 10 ]]; then
        print_info "Removing old backups (keeping latest 10)..."

        find "$BACKUP_DIR" -name "omarchy_backup_*" -type d | \
            sort -r | \
            tail -n +11 | \
            xargs rm -rf

        print_success "Old backups cleaned up"
    else
        print_info "No cleanup needed ($backup_count backups)"
    fi

    echo
}

# Generate deployment report
generate_report() {
    print_header "Deployment Report"

    local report_file="$HOME/.omarchy/deployment_report_$TIMESTAMP.txt"
    mkdir -p "$(dirname "$report_file")"

    cat > "$report_file" << EOF
Quantum-Forge Deployment Report
================================
Deployment Date: $(date)
Environment: $DEPLOY_ENV
Timestamp: $TIMESTAMP

System Information:
- OS: $(uname -s -r)
- Architecture: $(uname -m)
- Node.js: $(node --version)
- Go: $(go version)
- Git: $(git --version 2>/dev/null || echo "Not available")

Deployment Status:
- Backup Created: Yes
- Binaries Deployed: Yes
- Environment Configured: Yes
- Services Setup: Deferred to Phase 2
- Verification: Passed
- Tests: Passed

Deployed Components:
- quantum-forge CLI: $("$PROJECT_ROOT/quantum-forge" --version 2>/dev/null || echo "Unknown")"
- AI Collaboration Hub: Functional
- MCP Superagents: 3 agents deployed
- Blueprints: $(find "$PROJECT_ROOT/.omarchy/palimpsest/blueprints" -name "*.json" 2>/dev/null | wc -l) blueprints

Next Steps:
1. Review system health: $HOME/.local/share/omarchy/health-check.sh
2. Monitor performance metrics
3. Configure backup automation
4. Plan Phase 2 deployment

For support, see: $PROJECT_ROOT/QUANTUM_FORGE_INTEGRATION.md
EOF

    print_success "Deployment report generated: $report_file"

    # Show summary
    echo
    print_info "Deployment Summary:"
    print_info "  Environment: $DEPLOY_ENV"
    print_info "  Timestamp: $TIMESTAMP"
    print_info "  Backup: $BACKUP_DIR/omarchy_backup_$TIMESTAMP"
    print_info "  Report: $report_file"
    print_info "  Health Check: $HOME/.local/share/omarchy/health-check.sh"
    echo

    print_success "🎉 Quantum-Forge deployment completed successfully!"
    print_info "System is ready for production use."
    echo
}

# Rollback function
rollback() {
    print_header "Rolling Back Deployment"

    local backup_name="${1:-latest}"

    if [[ "$backup_name" == "latest" ]]; then
        backup_name=$(find "$BACKUP_DIR" -name "omarchy_backup_*" -type d | sort -r | head -1)
    fi

    local backup_path="$BACKUP_DIR/$backup_name"

    if [[ ! -d "$backup_path" ]]; then
        print_error "Backup not found: $backup_name"
        exit 1
    fi

    print_warning "Rolling back to: $backup_name"
    print_warning "This will replace current files with backup versions"

    read -p "Continue rollback? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Rollback cancelled"
        exit 0
    fi

    # Restore configuration
    if [[ -d "$backup_path/omarchy-wagon" ]]; then
        cp -r "$backup_path/omarchy-wagon" "$HOME/.npm-global/"
        print_success "Configuration restored"
    fi

    # Restore blueprints
    if [[ -d "$backup_path/.omarchy" ]]; then
        cp -r "$backup_path/.omarchy" "$PROJECT_ROOT/"
        print_success "Blueprints restored"
    fi

    # Restore binary
    if [[ -f "$backup_path/quantum-forge" ]]; then
        cp "$backup_path/quantum-forge" "$HOME/.local/bin/"
        print_success "Binary restored"
    fi

    print_success "Rollback completed"
    print_info "Restart any running services"
}

# Main deployment flow
main() {
    local command="${1:-deploy}"

    case "$command" in
        "deploy")
            preflight_check
            create_backup
            deploy_binaries
            configure_environment
            setup_services
            verify_deployment
            run_tests
            cleanup_backups
            generate_report
            ;;
        "rollback")
            rollback "$2"
            ;;
        "verify")
            verify_deployment
            run_tests
            ;;
        *)
            echo "Usage: $0 {deploy|rollback [backup_name]|verify}"
            echo "  deploy  - Deploy to production (default)"
            echo "  rollback - Rollback to previous backup"
            echo "  verify  - Verify current deployment"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"