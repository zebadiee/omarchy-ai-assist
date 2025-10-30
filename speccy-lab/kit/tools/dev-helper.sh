#!/usr/bin/env bash
# Speccy Kit - Development Helper
# Automated development environment setup and management

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
log_info() { echo -e "${BLUE}[SPECCY]${NC} $1"; }
log_success() { echo -e "${GREEN}[SPECCY]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[SPECCY]${NC} $1"; }
log_error() { echo -e "${RED}[SPECCY]${NC} $1"; }
log_step() { echo -e "${CYAN}[SPECCY]${NC} $1"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TOOLS_DIR="$PROJECT_ROOT/tools"

# Detect project type
detect_project_type() {
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        echo "node"
    elif [[ -f "$PROJECT_ROOT/pyproject.toml" ]] || [[ -f "$PROJECT_ROOT/setup.py" ]]; then
        echo "python"
    elif [[ -f "$PROJECT_ROOT/go.mod" ]]; then
        echo "go"
    elif [[ -f "$PROJECT_ROOT/Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "$PROJECT_ROOT/pom.xml" ]]; then
        echo "maven"
    elif [[ -f "$PROJECT_ROOT/build.gradle" ]] || [[ -f "$PROJECT_ROOT/build.gradle.kts" ]]; then
        echo "gradle"
    else
        echo "unknown"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install tool if not exists
ensure_tool() {
    local tool="$1"
    local install_cmd="$2"

    if ! command_exists "$tool"; then
        log_warn "$tool not found, installing..."
        if command_exists "npm"; then
            npm install -g "$tool"
        elif command_exists "pip"; then
            pip install "$tool"
        elif command_exists "go"; then
            go install "$install_cmd"
        else
            log_error "Cannot install $tool - no package manager found"
            return 1
        fi
        log_success "$tool installed"
    else
        log_info "$tool already available"
    fi
}

# Setup Node.js project
setup_node_project() {
    log_step "Setting up Node.js project..."

    # Install dependencies
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        log_info "Installing npm dependencies..."
        npm install

        # Check for dev dependencies
        if npm list eslint >/dev/null 2>&1; then
            log_info "ESLint is available"
        else
            log_warn "ESLint not found, consider adding to devDependencies"
        fi

        if npm list prettier >/dev/null 2>&1; then
            log_info "Prettier is available"
        else
            log_warn "Prettier not found, consider adding to devDependencies"
        fi

        # Setup husky if not already configured
        if [[ ! -d "$PROJECT_ROOT/.husky" ]] && [[ -f "$PROJECT_ROOT/package.json" ]]; then
            log_info "Setting up Git hooks with Husky..."
            npx husky install
            npx husky add .husky/pre-commit "npm run lint && npm test"
            log_success "Git hooks configured"
        fi
    fi
}

# Setup Python project
setup_python_project() {
    log_step "Setting up Python project..."

    # Create virtual environment if not exists
    if [[ ! -d "$PROJECT_ROOT/venv" ]]; then
        log_info "Creating Python virtual environment..."
        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip
        log_success "Virtual environment created"
    else
        log_info "Virtual environment already exists"
        source venv/bin/activate
    fi

    # Install dependencies
    if [[ -f "$PROJECT_ROOT/pyproject.toml" ]]; then
        log_info "Installing dependencies from pyproject.toml..."
        pip install -e .[dev]
    elif [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
        log_info "Installing dependencies from requirements.txt..."
        pip install -r requirements.txt
    fi

    # Setup pre-commit if not configured
    if [[ ! -f "$PROJECT_ROOT/.pre-commit-config.yaml" ]]; then
        log_info "Setting up pre-commit hooks..."
        cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files

  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black

  - repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
      - id: flake8

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.3.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
EOF
        pre-commit install
        log_success "Pre-commit hooks configured"
    fi
}

# Setup Go project
setup_go_project() {
    log_step "Setting up Go project..."

    # Download dependencies
    if [[ -f "$PROJECT_ROOT/go.mod" ]]; then
        log_info "Downloading Go modules..."
        go mod download
        go mod tidy
    fi

    # Install useful Go tools
    ensure_tool "gofmt" "golang.org/x/tools/cmd/goimports@latest"
    ensure_tool "golangci-lint" "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
    ensure_tool "mockgen" "go.uber.org/mock/mockgen@latest"

    # Setup pre-commit if not configured
    if [[ ! -f "$PROJECT_ROOT/.pre-commit-config.yaml" ]]; then
        log_info "Setting up pre-commit hooks..."
        cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files

  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v3.0.0
    hooks:
      - id: prettier
        types_or: [go, golangci-lint]

  - repo: local
    hooks:
      - id: go-fmt
        name: go fmt
        entry: gofmt
        language: system
        args: [-s, -w]
        types: [go]

      - id: go-vet
        name: go vet
        entry: go vet
        language: system
        types: [go]
        pass_filenames: false

      - id: golangci-lint
        name: golangci-lint
        entry: golangci-lint run
        language: system
        types: [go]
EOF
        pre-commit install
        log_success "Pre-commit hooks configured"
    fi
}

# Setup Rust project
setup_rust_project() {
    log_step "Setting up Rust project..."

    # Check Rust installation
    if ! command_exists "cargo"; then
        log_error "Rust/Cargo not found. Please install from https://rustup.rs/"
        return 1
    fi

    # Install useful Rust tools
    ensure_tool "cargo-watch" "cargo-watch@latest"
    ensure_tool "cargo-expand" "cargo-expand@latest"
    ensure_tool "cargo-audit" "cargo-audit@latest"

    # Setup pre-commit if not configured
    if [[ ! -f "$PROJECT_ROOT/.pre-commit-config.yaml" ]]; then
        log_info "Setting up pre-commit hooks..."
        cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files

  - repo: local
    hooks:
      - id: cargo-fmt
        name: cargo fmt
        entry: cargo fmt
        language: system
        args: [--all, --]
        types: [rust]
        pass_filenames: false

      - id: cargo-clippy
        name: cargo clippy
        entry: cargo clippy
        language: system
        args: [--all-targets, --all-features, -- -D warnings]
        types: [rust]
        pass_filenames: false

      - id: cargo-test
        name: cargo test
        entry: cargo test
        language: system
        args: [--all-targets, --all-features]
        types: [rust]
        pass_filenames: false
EOF
        pre-commit install
        log_success "Pre-commit hooks configured"
    fi
}

# Create development scripts
create_dev_scripts() {
    log_step "Creating development scripts..."

    # Create scripts directory
    mkdir -p "$PROJECT_ROOT/scripts"

    # Create common dev script
    cat > "$PROJECT_ROOT/scripts/dev.sh" << 'EOF'
#!/bin/bash
# Development helper script

set -euo pipefail

case "${1:-help}" in
    "start")
        echo "Starting development server..."
        # Add start command based on project type
        ;;
    "test")
        echo "Running tests..."
        # Add test command
        ;;
    "lint")
        echo "Running linter..."
        # Add lint command
        ;;
    "build")
        echo "Building project..."
        # Add build command
        ;;
    "clean")
        echo "Cleaning build artifacts..."
        # Add clean command
        ;;
    "deploy")
        echo "Deploying project..."
        # Add deploy command
        ;;
    "help"|*)
        echo "Available commands: start, test, lint, build, clean, deploy"
        ;;
esac
EOF
    chmod +x "$PROJECT_ROOT/scripts/dev.sh"

    log_success "Development scripts created"
}

# Create development environment
create_dev_environment() {
    log_step "Creating development environment..."

    # Create .vscode settings
    mkdir -p "$PROJECT_ROOT/.vscode"
    cat > "$PROJECT_ROOT/.vscode/settings.json" << 'EOF'
{
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.fixAll": true
    },
    "files.exclude": {
        "**/node_modules": true,
        "**/target": true,
        "**/__pycache__": true,
        "**/.pytest_cache": true
    },
    "python.defaultInterpreterPath": "./venv/bin/python",
    "typescript.preferences.importModuleSpecifier": "relative"
}
EOF

    # Create .vscode extensions
    cat > "$PROJECT_ROOT/.vscode/extensions.json" << 'EOF'
{
    "recommendations": [
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "ms-python.python",
        "golang.go",
        "rust-lang.rust-analyzer",
        "ms-vscode.vscode-json"
    ]
}
EOF

    log_success "VS Code configuration created"
}

# Main setup function
setup_project() {
    local project_type
    project_type=$(detect_project_type)

    log_info "Detected project type: $project_type"

    case "$project_type" in
        "node")
            setup_node_project
            ;;
        "python")
            setup_python_project
            ;;
        "go")
            setup_go_project
            ;;
        "rust")
            setup_rust_project
            ;;
        "unknown")
            log_warn "Unknown project type, performing generic setup..."
            ;;
    esac

    create_dev_scripts
    create_dev_environment
}

# Show status
show_status() {
    log_info "Development environment status:"

    # Check Git status
    if git rev-parse --git-dir >/dev/null 2>&1; then
        echo "  ✅ Git repository initialized"
        local git_status=$(git status --porcelain | wc -l)
        if [[ $git_status -eq 0 ]]; then
            echo "  ✅ Working directory clean"
        else
            echo "  ⚠️  $git_status uncommitted changes"
        fi
    else
        echo "  ❌ Not a Git repository"
    fi

    # Check project type
    local project_type
    project_type=$(detect_project_type)
    echo "  📦 Project type: $project_type"

    # Check dependencies
    case "$project_type" in
        "node")
            if [[ -d "node_modules" ]]; then
                echo "  ✅ Node dependencies installed"
            else
                echo "  ❌ Node dependencies not installed"
            fi
            ;;
        "python")
            if [[ -d "venv" ]]; then
                echo "  ✅ Python virtual environment exists"
            else
                echo "  ❌ Python virtual environment not found"
            fi
            ;;
        "go")
            if [[ -f "go.sum" ]]; then
                echo "  ✅ Go modules downloaded"
            else
                echo "  ❌ Go modules not downloaded"
            fi
            ;;
        "rust")
            if [[ -d "target" ]]; then
                echo "  ✅ Rust project built"
            else
                echo "  ⚠️  Rust project not built yet"
            fi
            ;;
    esac

    # Check tools
    echo "  🛠️  Available tools:"
    for tool in git npm pip go cargo; do
        if command_exists "$tool"; then
            echo "    ✅ $tool"
        else
            echo "    ❌ $tool"
        fi
    done
}

# Usage
show_usage() {
    cat << EOF
Speccy Kit - Development Helper

USAGE:
    $0 [COMMAND]

COMMANDS:
    setup       Set up development environment
    status      Show current environment status
    install     Install additional tools
    help        Show this help

EXAMPLES:
    $0 setup     # Set up everything
    $0 status    # Check current status

EOF
}

# Main execution
main() {
    case "${1:-setup}" in
        "setup")
            setup_project
            log_success "Development environment setup complete!"
            log_info "Run './scripts/dev.sh help' to see available commands"
            ;;
        "status")
            show_status
            ;;
        "install")
            shift
            if [[ $# -eq 0 ]]; then
                log_error "Please specify a tool to install"
                exit 1
            fi
            ensure_tool "$1"
            ;;
        "help"|*)
            show_usage
            ;;
    esac
}

# Execute main function
main "$@"