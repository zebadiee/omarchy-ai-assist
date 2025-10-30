#!/usr/bin/env bash
# Speccy Kit - Project Initializer
# Creates new projects with best practices and scaffolding

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging
log_info() { echo -e "${BLUE}[SPECCY]${NC} $1"; }
log_success() { echo -e "${GREEN}[SPECCY]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[SPECCY]${NC} $1"; }
log_error() { echo -e "${RED}[SPECCY]${NC} $1"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")/templates"
PROMPTS_DIR="$(dirname "$SCRIPT_DIR")/prompts"

# Available templates
declare -A TEMPLATES=(
    ["web-app"]="Modern web application with React/Vue"
    ["api-rest"]="RESTful API with Node.js/Python"
    ["cli-tool"]="Command-line tool with Go/Rust"
    ["mobile-app"]="Mobile app with React Native/Flutter"
    ["desktop-app"]="Desktop app with Electron/Tauri"
    ["library"]="Reusable library with TypeScript/Rust"
    ["microservice"]="Microservice with Docker/Kubernetes"
    ["data-pipeline"]="Data pipeline with Airflow/Prefect"
    ["ml-project"]="Machine learning project with Python"
    ["game-dev"]="Game development with Godot/Unity"
)

# Available languages
declare -A LANGUAGES=(
    ["typescript"]="TypeScript - Type-safe JavaScript"
    ["javascript"]="JavaScript - Web development"
    ["python"]="Python - General purpose"
    ["go"]="Go - Systems programming"
    ["rust"]="Rust - Safe systems programming"
    ["java"]="Java - Enterprise development"
    ["csharp"]="C# - .NET development"
    ["cpp"]="C++ - Systems programming"
    ["php"]="PHP - Web development"
    ["ruby"]="Ruby - Web development"
)

# Usage
show_usage() {
    cat << EOF
Speccy Kit - Project Initializer

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -n, --name NAME          Project name (required)
    -t, --template TEMPLATE  Project template (see list below)
    -l, --language LANGUAGE   Primary programming language
    -d, --directory DIR      Output directory (default: ./)
    -a, --author AUTHOR       Author name
    -e, --email EMAIL         Author email
    -g, --git-repo REPO       Git repository URL
    -l, --license LICENSE     License type (mit, apache, bsd, gpl)
    -h, --help               Show this help

TEMPLATES:
EOF
    for template in "${!TEMPLATES[@]}"; do
        echo "    $template - ${TEMPLATES[$template]}"
    done
    cat << EOF

LANGUAGES:
EOF
    for lang in "${!LANGUAGES[@]}"; do
        echo "    $lang - ${LANGUAGES[$lang]}"
    done
    cat << EOF

EXAMPLES:
    $0 -n my-web-app -t web-app -l typescript -a "Your Name"
    $0 -n my-api -t api-rest -l python -d ~/projects
    $0 -n my-cli -t cli-tool -l go -g https://github.com/user/repo

EOF
}

# Parse arguments
NAME=""
TEMPLATE=""
LANGUAGE=""
DIRECTORY="./"
AUTHOR=""
EMAIL=""
GIT_REPO=""
LICENSE="mit"

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            NAME="$2"
            shift 2
            ;;
        -t|--template)
            TEMPLATE="$2"
            shift 2
            ;;
        -l|--language)
            LANGUAGE="$2"
            shift 2
            ;;
        -d|--directory)
            DIRECTORY="$2"
            shift 2
            ;;
        -a|--author)
            AUTHOR="$2"
            shift 2
            ;;
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        -g|--git-repo)
            GIT_REPO="$2"
            shift 2
            ;;
        --license)
            LICENSE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$NAME" ]]; then
    log_error "Project name is required (-n/--name)"
    exit 1
fi

# Set defaults
if [[ -z "$TEMPLATE" ]]; then
    TEMPLATE="web-app"
    log_warn "No template specified, using default: $TEMPLATE"
fi

if [[ -z "$LANGUAGE" ]]; then
    case "$TEMPLATE" in
        "web-app"|"mobile-app")
            LANGUAGE="typescript"
            ;;
        "api-rest"|"ml-project")
            LANGUAGE="python"
            ;;
        "cli-tool"|"microservice")
            LANGUAGE="go"
            ;;
        "desktop-app")
            LANGUAGE="typescript"
            ;;
        "library")
            LANGUAGE="rust"
            ;;
        "data-pipeline")
            LANGUAGE="python"
            ;;
        "game-dev")
            LANGUAGE="typescript"
            ;;
        *)
            LANGUAGE="javascript"
            ;;
    esac
    log_warn "No language specified, using default for $TEMPLATE: $LANGUAGE"
fi

# Validate template
if [[ -z "${TEMPLATES[$TEMPLATE]:-}" ]]; then
    log_error "Unknown template: $TEMPLATE"
    echo "Available templates:"
    for template in "${!TEMPLATES[@]}"; do
        echo "  $template - ${TEMPLATES[$template]}"
    done
    exit 1
fi

# Validate language
if [[ -z "${LANGUAGES[$LANGUAGE]:-}" ]]; then
    log_error "Unknown language: $LANGUAGE"
    echo "Available languages:"
    for lang in "${!LANGUAGES[@]}"; do
        echo "  $lang - ${LANGUAGES[$lang]}"
    done
    exit 1
fi

# Get author info if not provided
if [[ -z "$AUTHOR" ]]; then
    AUTHOR="$(git config user.name 2>/dev/null || echo "Your Name")"
fi

if [[ -z "$EMAIL" ]]; then
    EMAIL="$(git config user.email 2>/dev/null || echo "your.email@example.com")"
fi

# Create project directory
PROJECT_DIR="$DIRECTORY/$NAME"
if [[ -d "$PROJECT_DIR" ]]; then
    log_error "Directory already exists: $PROJECT_DIR"
    exit 1
fi

log_info "Creating project: $NAME"
log_info "Template: $TEMPLATE - ${TEMPLATES[$TEMPLATE]}"
log_info "Language: $LANGUAGE - ${LANGUAGES[$LANGUAGE]}"
log_info "Location: $PROJECT_DIR"

# Create directory structure
mkdir -p "$PROJECT_DIR"/{src,docs,tests,scripts,.github/workflows}
mkdir -p "$PROJECT_DIR"/{config,build,dist,tools}

# Create package.json if Node.js/TypeScript
if [[ "$LANGUAGE" =~ ^(typescript|javascript)$ ]]; then
    cat > "$PROJECT_DIR/package.json" << EOF
{
  "name": "$NAME",
  "version": "0.1.0",
  "description": "$NAME - ${TEMPLATES[$TEMPLATE]}",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "node --watch src/index.js",
    "build": "npm run build:prod",
    "test": "jest",
    "lint": "eslint src --ext .js,.ts",
    "format": "prettier --write \"src/**/*.{js,ts,css,md}\""
  },
  "keywords": [],
  "author": "$AUTHOR <$EMAIL>",
  "license": "$LICENSE",
  "devDependencies": {
    "eslint": "^8.0.0",
    "jest": "^29.0.0",
    "prettier": "^3.0.0"
  },
  "dependencies": {}
}
EOF
fi

# Create pyproject.toml if Python
if [[ "$LANGUAGE" == "python" ]]; then
    cat > "$PROJECT_DIR/pyproject.toml" << EOF
[build-system]
requires = ["setuptools>=45", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "$NAME"
version = "0.1.0"
description = "$NAME - ${TEMPLATES[$TEMPLATE]}"
authors = [{name = "$AUTHOR", email = "$EMAIL"}]
license = {text = "$LICENSE"}
readme = "README.md"
requires-python = ">=3.8"
classifiers = [
    "Development Status :: 3 - Alpha",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.8",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
]
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "black>=22.0.0",
    "flake8>=5.0.0",
    "mypy>=1.0.0",
]

[project.urls]
Homepage = "$GIT_REPO"
Repository = "$GIT_REPO"
Issues = "$GIT_REPO/issues"

[tool.setuptools.packages.find]
where = ["src"]

[tool.black]
line-length = 88
target-version = ['py38']

[tool.mypy]
python_version = "3.8"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
EOF
fi

# Create go.mod if Go
if [[ "$LANGUAGE" == "go" ]]; then
    cd "$PROJECT_DIR"
    go mod init "$NAME"
    cat > "$PROJECT_DIR/go.sum" << EOF
# This file is generated by Go modules and should not be edited manually.
EOF
    cd - > /dev/null
fi

# Create Cargo.toml if Rust
if [[ "$LANGUAGE" == "rust" ]]; then
    cat > "$PROJECT_DIR/Cargo.toml" << EOF
[package]
name = "$NAME"
version = "0.1.0"
edition = "2021"
authors = ["$AUTHOR <$EMAIL>"]
description = "$NAME - ${TEMPLATES[$TEMPLATE]}"
license = "$LICENSE"
repository = "$GIT_REPO"

[dependencies]

[dev-dependencies]
tokio-test = "0.4"
EOF
fi

# Create README.md
cat > "$PROJECT_DIR/README.md" << EOF
# $NAME

$NAME - ${TEMPLATES[$TEMPLATE]}

## Getting Started

### Prerequisites

- $(${LANGUAGES[$LANGUAGE]%% *} - ${LANGUAGES[$LANGUAGE]##* })

### Installation

\`\`\`bash
# Clone the repository
git clone $GIT_REPO
cd $NAME

# Install dependencies
$([[ "$LANGUAGE" =~ ^(typescript|javascript)$ ]] && echo "npm install")
$([[ "$LANGUAGE" == "python" ]] && echo "pip install -e .[dev]")
$([[ "$LANGUAGE" == "go" ]] && echo "go mod download")
$([[ "$LANGUAGE" == "rust" ]] && echo "cargo build")
\`\`\`

### Usage

\`\`\`bash
$([[ "$LANGUAGE" =~ ^(typescript|javascript)$ ]] && echo "npm start")
$([[ "$LANGUAGE" == "python" ]] && echo "python -m $NAME")
$([[ "$LANGUAGE" == "go" ]] && echo "go run .")
$([[ "$LANGUAGE" == "rust" ]] && echo "cargo run")
\`\`\`

## Development

### Running Tests

\`\`\`bash
$([[ "$LANGUAGE" =~ ^(typescript|javascript)$ ]] && echo "npm test")
$([[ "$LANGUAGE" == "python" ]] && echo "pytest")
$([[ "$LANGUAGE" == "go" ]] && echo "go test ./...")
$([[ "$LANGUAGE" == "rust" ]] && echo "cargo test")
\`\`\`

### Code Formatting

\`\`\`bash
$([[ "$LANGUAGE" =~ ^(typescript|javascript)$ ]] && echo "npm run format")
$([[ "$LANGUAGE" == "python" ]] && echo "black .")
$([[ "$LANGUAGE" == "go" ]] && echo "gofmt -s -w .")
$([[ "$LANGUAGE" == "rust" ]] && echo "cargo fmt")
\`\`\`

## License

This project is licensed under the $LICENSE License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
EOF

# Create .gitignore
cat > "$PROJECT_DIR/.gitignore" << EOF
# Dependencies
node_modules/
__pycache__/
*.py[cod]
*\$py.class
target/
Cargo.lock

# Build outputs
dist/
build/
*.egg-info/

# Environment variables
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Coverage reports
coverage/
.coverage
.nyc_output

# Temporary files
*.tmp
*.temp
EOF

# Create GitHub Actions workflow
mkdir -p "$PROJECT_DIR/.github/workflows"
cat > "$PROJECT_DIR/.github/workflows/ci.yml" << EOF
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
$([[ "$LANGUAGE" == "python" ]] && echo "        python-version: [3.8, 3.9, '3.10', '3.11']")
$([[ "$LANGUAGE" == "node" ]] && echo "        node-version: [16, 18, 20]")
$([[ "$LANGUAGE" == "go" ]] && echo "        go-version: [1.19, 1.20, 1.21]")
$([[ "$LANGUAGE" == "rust" ]] && echo "        rust: [stable, beta]")

    steps:
    - uses: actions/checkout@v3

$([[ "$LANGUAGE" == "python" ]] && cat << 'PYTHON_EOF'
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: \${{ matrix.python-version }}

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -e .[dev]

    - name: Run tests
      run: pytest

    - name: Run linting
      run: |
        black --check .
        flake8 .
        mypy src
PYTHON_EOF
)

$([[ "$LANGUAGE" =~ ^(typescript|javascript)$ ]] && cat << 'NODE_EOF'
    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: \${{ matrix.node-version }}
        cache: 'npm'

    - name: Install dependencies
      run: npm ci

    - name: Run tests
      run: npm test

    - name: Run linting
      run: npm run lint
NODE_EOF
)

$([[ "$LANGUAGE" == "go" ]] && cat << 'GO_EOF'
    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: \${{ matrix.go-version }}

    - name: Install dependencies
      run: go mod download

    - name: Run tests
      run: go test ./...

    - name: Run linting
      run: |
        go fmt -s -w .
        go vet ./...
GO_EOF
)

$([[ "$LANGUAGE" == "rust" ]] && cat << 'RUST_EOF'
    - name: Set up Rust
      uses: dtolnay/rust-toolchain@stable
      with:
        toolchain: \${{ matrix.rust }}

    - name: Run tests
      run: cargo test

    - name: Run linting
      run: cargo fmt --all -- --check
      run: cargo clippy --all-targets --all-features -- -D warnings
RUST_EOF
)
EOF

# Initialize git repository
cd "$PROJECT_DIR"
git init
git add .
git commit -m "Initial commit: ${TEMPLATES[$TEMPLATE]} with $LANGUAGE"

cd - > /dev/null

log_success "Project created successfully!"
log_info "Project location: $PROJECT_DIR"
log_info "Next steps:"
echo "  1. cd $PROJECT_DIR"
echo "  2. Review and customize the configuration"
echo "  3. Install dependencies"
echo "  4. Start development!"

log_info "Speccy Kit tools available in your project:"
echo "  ./speccy-tools/dev-helper.sh"
echo "  ./speccy-tools/code-review.sh"
echo "  ./speccy-tools/docs-gen.sh"