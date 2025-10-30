#!/usr/bin/env bash
# One-click SafeOps kit installer
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[SAFEOPS]${NC} $1"; }
log_success() { echo -e "${GREEN}[SAFEOPS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[SAFEOPS]${NC} $1"; }
log_error() { echo -e "${RED}[SAFEOPS]${NC} $1"; }

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  log_error "Not in a git repository. SafeOps requires git."
  exit 1
fi

log_info "Installing SafeOps kit..."

# Create directories if they don't exist
mkdir -p .githooks tools

# Make sure all scripts are executable
chmod +x tools/*.sh .githooks/*

# Enable git hooks
git config core.hooksPath .githooks

log_success "Git hooks enabled"

# Add secrets to .gitignore if not already present
if ! grep -q "**/\*.key" .gitignore 2>/dev/null; then
  cat >> .gitignore << 'EOF'

# SafeOps - Secret patterns
**/*.key
**/id_*
**/*.pem
**/.ssh/*
!**/.ssh/config

# Environment files with secrets
*.env
*.env.local
*.env.production
.env.staging
EOF
  log_success "Updated .gitignore with secret patterns"
fi

# Test the pre-commit hook
log_info "Testing pre-commit hook..."
echo "# Test file for secret scanning" > test-secret.tmp
echo "BEGIN RSA PRIVATE KEY" >> test-secret.tmp
git add test-secret.tmp 2>/dev/null || true

if git commit -m "test: secret detection" 2>/dev/null; then
  log_warn "Pre-commit hook may not be working properly"
  git reset HEAD test-secret.tmp 2>/dev/null || true
else
  log_success "Pre-commit hook working (blocked secret commit)"
fi
rm -f test-secret.tmp

# Create a test script to verify safe_run.sh
cat > test_safe.sh << 'EOF'
#!/bin/bash
echo "Test script - checking safe patterns"
# This should pass
echo "chmod -R 755 /opt/myapp"
EOF
chmod +x test_safe.sh

log_info "Testing safe_run.sh..."

if ./tools/safe_run.sh ./test_safe.sh 2>/dev/null; then
  log_success "safe_run.sh working correctly"
else
  log_warn "safe_run.sh may need additional dependencies"
fi

rm -f test_safe.sh

# Create a sample dangerous script to test blocking
cat > test_dangerous.sh << 'EOF'
#!/bin/bash
# This should be blocked
echo "rm -rf /"
EOF
chmod +x test_dangerous.sh

log_info "Testing dangerous pattern detection..."

if ./tools/safe_run.sh ./test_dangerous.sh 2>/dev/null; then
  log_error "Dangerous pattern detection failed!"
else
  log_success "Dangerous patterns correctly blocked"
fi

rm -f test_dangerous.sh

# Test systemd unit renderer
log_info "Testing systemd unit renderer..."
if ./tools/render_unit.sh "Test Service" "nobody" "nogroup" "/opt/test" "/usr/bin/echo" "hello world" "/opt/test/data" > /dev/null; then
  log_success "Systemd unit renderer working"
else
  log_error "Systemd unit renderer failed"
fi

# Test common header
log_info "Testing common header..."
if source ./tools/common_header.sh; then
  log_success "Common header loaded successfully"
else
  log_error "Common header failed to load"
fi

# Create README if not exists
if [[ ! -f README.md ]]; then
  cat > README.md << 'EOF'
# SafeOps Project

This project uses SafeOps for secure development workflows.

## SafeOps Tools

- `tools/safe_run.sh` - Safe script execution with sandboxing
- `tools/render_unit.sh` - Generate hardened systemd units
- `tools/common_header.sh` - Safety header for scripts
- `.githooks/pre-commit` - Secret scanning and security checks

## Usage

```bash
# Run Claude's script safely
./tools/safe_run.sh ./claude_proposed_script.sh

# Generate hardened systemd service
./tools/render_unit.sh "My App" "myuser" "mygroup" "/opt/myapp" "/opt/myapp/app.sh" "--serve" "/opt/myapp/data" > myapp.service

# Include safety header in scripts
#!/bin/bash
source ./tools/common_header.sh
# Your script here...
```

## Guardrails

- No direct `/etc/sudoers` edits
- No recursive chmod 777 outside allowlisted paths
- All risky operations require sandbox testing
- Secret scanning prevents committing credentials
- Systemd units are automatically hardened

See [SAFEOPS.md](SAFEOPS.md) for complete documentation.
EOF
  log_success "Created README.md"
fi

log_success "SafeOps kit installation complete!"
log_info ""
log_info "Quick start:"
log_info "  ./tools/safe_run.sh ./your_script.sh"
log_info "  ./tools/render_unit.sh 'My Service' user group /opt/app /opt/app/app.sh '' /opt/app/data > service.service"
log_info ""
log_info "Read SAFEOPS.md for complete documentation."