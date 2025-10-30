#!/usr/bin/env bash
# Speccy Kit - Code Review Assistant
# Automated code review and quality checks

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Logging
log_info() { echo -e "${BLUE}[SPECCY]${NC} $1"; }
log_success() { echo -e "${GREEN}[SPECCY]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[SPECCY]${NC} $1"; }
log_error() { echo -e "${RED}[SPECCY]${NC} $1"; }
log_step() { echo -e "${CYAN}[SPECCY]${NC} $1"; }
log_review() { echo -e "${MAGENTA}[REVIEW]${NC} $1"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"
AUTO_FIX="${AUTO_FIX:-false}"
SEVERITY="${SEVERITY:-medium}" # low, medium, high

# Output formatting
format_output() {
    local type="$1"
    local message="$2"
    local file="$3"
    local line="${4:-}"
    local code="${5:-}"

    case "$OUTPUT_FORMAT" in
        "json")
            echo "{\"type\":\"$type\",\"message\":\"$message\",\"file\":\"$file\",\"line\":$line,\"code\":\"$code\"}"
            ;;
        "markdown")
            case "$type" in
                "error")
                    echo "❌ **Error**: $message"
                    ;;
                "warning")
                    echo "⚠️ **Warning**: $message"
                    ;;
                "info")
                    echo "ℹ️ **Info**: $message"
                    ;;
                "success")
                    echo "✅ **Success**: $message"
                    ;;
            esac
            if [[ -n "$file" ]]; then
                echo "  📄 \`$file\`${line:+:$line}"
            fi
            ;;
        "text"|*)
            case "$type" in
                "error")
                    echo -e "${RED}❌ ERROR: $message${NC}"
                    ;;
                "warning")
                    echo -e "${YELLOW}⚠️  WARNING: $message${NC}"
                    ;;
                "info")
                    echo -e "${BLUE}ℹ️  INFO: $message${NC}"
                    ;;
                "success")
                    echo -e "${GREEN}✅ SUCCESS: $message${NC}"
                    ;;
            esac
            if [[ -n "$file" ]]; then
                echo -e "   📄 $file${line:+:$line}"
            fi
            ;;
    esac
}

# Check if file exists
check_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        format_output "error" "File not found: $file" "$file"
        return 1
    fi
    return 0
}

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
    else
        echo "unknown"
    fi
}

# Generic file checks
check_file_basics() {
    local file="$1"
    local issues=0

    # Check file size
    local size
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
    if [[ $size -gt 1048576 ]]; then # 1MB
        format_output "warning" "Large file detected ($(echo "scale=1; $size/1024/1024" | bc)MB)" "$file"
        ((issues++))
    fi

    # Check for TODO/FIXME comments
    if grep -q -i "TODO\|FIXME\|HACK\|XXX" "$file"; then
        format_output "warning" "Contains TODO/FIXME comments" "$file"
        ((issues++))
    fi

    # Check for debug statements
    if grep -q -i "console\.log\|print\|debug\|alert\|console\.warn" "$file"; then
        format_output "warning" "Contains debug statements" "$file"
        ((issues++))
    fi

    # Check for sensitive data patterns
    if grep -q -i "password\|secret\|token\|key\|api[_-]*key" "$file"; then
        format_output "warning" "Potentially sensitive data patterns" "$file"
        ((issues++))
    fi

    return $issues
}

# Language-specific checks
check_javascript() {
    local file="$1"
    local issues=0

    # Check for var declarations
    if grep -q "\bvar\b" "$file"; then
        format_output "warning" "Use let/const instead of var" "$file"
        ((issues++))
    fi

    # Check for == vs ===
    if grep -q "==[^=]" "$file"; then
        format_output "warning" "Use === instead of ==" "$file"
        ((issues++))
    fi

    # Check for missing semicolons
    if grep -q -E "^[^/].*[^;]$" "$file"; then
        format_output "info" "Missing semicolon detected" "$file"
        ((issues++))
    fi

    # Check for eval()
    if grep -q "\beval(" "$file"; then
        format_output "error" "Avoid using eval()" "$file"
        ((issues++))
    fi

    return $issues
}

check_python() {
    local file="$1"
    local issues=0

    # Check for bare except
    if grep -q "except:" "$file"; then
        format_output "warning" "Bare except clause detected" "$file"
        ((issues++))
    fi

    # Check for wildcard imports
    if grep -q "from .* import \*" "$file"; then
        format_output "warning" "Wildcard import detected" "$file"
        ((issues++))
    fi

    # Check for global variables
    if grep -q "^global " "$file"; then
        format_output "warning" "Global variable detected" "$file"
        ((issues++))
    fi

    # Check for exec/eval
    if grep -q "\bexec\(" "$file" || grep -q "\beval(" "$file"; then
        format_output "error" "Avoid using exec/eval" "$file"
        ((issues++))
    fi

    return $issues
}

check_go() {
    local file="$1"
    local issues=0

    # Check for error handling
    if ! grep -q "if err != nil" "$file" && ! grep -q "if.*err.*!=" "$file"; then
        # Only warn if there are function calls that could return errors
        if grep -q "\.([A-Z][a-z]*(" "$file"; then
            format_output "info" "Potential missing error handling" "$file"
            ((issues++))
        fi
    fi

    # Check for TODO/FIXME in Go comments
    if grep -q "// TODO\|// FIXME\|// XXX" "$file"; then
        format_output "warning" "Contains TODO/FIXME comments" "$file"
        ((issues++))
    fi

    # Check for golint issues
    # This would require golint to be installed
    if command_exists "golint"; then
        if golint "$file" 2>/dev/null | grep -q .; then
            format_output "warning" "golint issues detected" "$file"
            ((issues++))
        fi
    fi

    return $issues
}

check_rust() {
    local file="$1"
    local issues=0

    # Check for unwrap()
    if grep -q "\.unwrap()" "$file"; then
        format_output "warning" "unwrap() detected - consider proper error handling" "$file"
        ((issues++))
    fi

    # Check for panic!
    if grep -q "panic!" "$file"; then
        format_output "warning" "panic! detected - use proper error handling" "$file"
        ((issues++))
    fi

    # Check for unsafe blocks
    if grep -q "unsafe {" "$file"; then
        format_output "warning" "unsafe block detected" "$file"
        ((issues++))
    fi

    # Check for TODO/FIXME
    if grep -q "// TODO\|// FIXME\|// XXX" "$file"; then
        format_output "warning" "Contains TODO/FIXME comments" "$file"
        ((issues++))
    fi

    return $issues
}

# Auto-fix issues
auto_fix_issues() {
    local file="$1"
    local project_type
    project_type=$(detect_project_type)

    log_step "Auto-fixing issues in $file..."

    case "$project_type" in
        "node")
            # Fix var -> let/const
            sed -i.bak 's/\bvar\b/let/g' "$file"
            rm -f "$file.bak"
            format_output "success" "Auto-fixed: var -> let" "$file"

            # Fix == -> ===
            sed -i.bak 's/\([^=]\)==\([^=]\)/\1===\2/g' "$file"
            rm -f "$file.bak"
            format_output "success" "Auto-fixed: == -> ===" "$file"
            ;;
        "python")
            # Fix bare except -> except Exception
            sed -i.bak 's/except:/except Exception:/g' "$file"
            rm -f "$file.bak"
            format_output "success" "Auto-fixed: bare except -> except Exception" "$file"
            ;;
    esac
}

# Review single file
review_file() {
    local file="$1"
    local total_issues=0

    if ! check_file_exists "$file"; then
        return 1
    fi

    log_review "Reviewing: $file"

    # Basic file checks
    local basic_issues
    basic_issues=$(check_file_basics "$file")
    total_issues=$((total_issues + basic_issues))

    # Language-specific checks
    local project_type
    project_type=$(detect_project_type)

    case "$project_type" in
        "node")
            if [[ "$file" =~ \.(js|ts|jsx|tsx)$ ]]; then
                local js_issues
                js_issues=$(check_javascript "$file")
                total_issues=$((total_issues + js_issues))
            fi
            ;;
        "python")
            if [[ "$file" =~ \.py$ ]]; then
                local py_issues
                py_issues=$(check_python "$file")
                total_issues=$((total_issues + py_issues))
            fi
            ;;
        "go")
            if [[ "$file" =~ \.go$ ]]; then
                local go_issues
                go_issues=$(check_go "$file")
                total_issues=$((total_issues + go_issues))
            fi
            ;;
        "rust")
            if [[ "$file" =~ \.rs$ ]]; then
                local rust_issues
                rust_issues=$(check_rust "$file")
                total_issues=$((total_issues + rust_issues))
            fi
            ;;
    esac

    # Auto-fix if requested
    if [[ "$AUTO_FIX" == "true" && $total_issues -gt 0 ]]; then
        auto_fix_issues "$file"
    fi

    return $total_issues
}

# Review all files
review_all_files() {
    local total_issues=0
    local files_reviewed=0

    log_step "Starting code review..."

    # Get list of files to review
    local files
    case "$(detect_project_type)" in
        "node")
            files=$(find . -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | grep -v node_modules)
            ;;
        "python")
            files=$(find . -name "*.py" | grep -v venv)
            ;;
        "go")
            files=$(find . -name "*.go")
            ;;
        "rust")
            files=$(find . -name "*.rs")
            ;;
        *)
            files=$(find . -type f -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.rs")
            ;;
    esac

    for file in $files; do
        local issues
        issues=$(review_file "$file")
        total_issues=$((total_issues + issues))
        ((files_reviewed++))
    done

    log_step "Review complete: $files_reviewed files reviewed, $total_issues issues found"

    return $total_issues
}

# Security scan
security_scan() {
    log_step "Running security scan..."

    local security_issues=0

    # Check for secrets in code
    local secret_files
    secret_files=$(grep -r -l -i "password\|secret\|token\|key\|api[_-]*key" . --exclude-dir=node_modules --exclude-dir=venv --exclude-dir=target 2>/dev/null || true)

    for file in $secret_files; do
        format_output "error" "Potential secrets found in code" "$file"
        ((security_issues++))
    done

    # Check for eval statements
    local eval_files
    eval_files=$(grep -r -l "\beval\(" . --exclude-dir=node_modules --exclude-dir=venv --exclude-dir=target 2>/dev/null || true)

    for file in $eval_files; do
        format_output "error" "eval() usage detected" "$file"
        ((security_issues++))
    done

    # Check for shell command execution
    local shell_files
    shell_files=$(grep -r -l "system\|exec\|spawn" . --exclude-dir=node_modules --exclude-dir=venv --exclude-dir=target 2>/dev/null || true)

    for file in $shell_files; do
        format_output "warning" "Shell command execution detected" "$file"
        ((security_issues++))
    done

    log_step "Security scan complete: $security_issues security issues found"

    return $security_issues
}

# Performance analysis
performance_analysis() {
    log_step "Running performance analysis..."

    local perf_issues=0

    # Check for large files
    local large_files
    large_files=$(find . -type f -size +1M -not -path "./node_modules/*" -not -path "./venv/*" -not -path "./target/*" 2>/dev/null || true)

    for file in $large_files; do
        local size
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        format_output "warning" "Large file detected ($(echo "scale=1; $size/1024/1024" | bc)MB)" "$file"
        ((perf_issues++))
    done

    # Check for potential performance anti-patterns
    case "$(detect_project_type)" in
        "node")
            # Check for synchronous operations
            local sync_files
            sync_files=$(grep -r -l "fs\.readFileSync\|fs\.writeFileSync" . --exclude-dir=node_modules 2>/dev/null || true)
            for file in $sync_files; do
                format_output "warning" "Synchronous file operations detected" "$file"
                ((perf_issues++))
            done
            ;;
        "python")
            # Check for inefficient loops
            local loop_files
            loop_files=$(grep -r -l "for .* in.*range.*len(" . --exclude-dir=venv 2>/dev/null || true)
            for file in $loop_files; do
                format_output "warning" "Inefficient range(len()) pattern detected" "$file"
                ((perf_issues++))
            done
            ;;
    esac

    log_step "Performance analysis complete: $perf_issues performance issues found"

    return $perf_issues
}

# Generate report
generate_report() {
    local review_issues="$1"
    local security_issues="$2"
    local perf_issues="$3"

    echo ""
    log_step "Code Review Report"
    echo "=================="
    echo ""

    case "$OUTPUT_FORMAT" in
        "markdown")
            echo "## 📊 Summary"
            echo ""
            echo "- 📝 **Code Issues**: $review_issues"
            echo "- 🔒 **Security Issues**: $security_issues"
            echo "- ⚡ **Performance Issues**: $perf_issues"
            echo "- 📈 **Total Issues**: $((review_issues + security_issues + perf_issues))"
            echo ""
            if [[ $((review_issues + security_issues + perf_issues)) -eq 0 ]]; then
                echo "🎉 **Excellent!** No issues found."
            else
                echo "⚠️ **Action Required**: Please address the issues above."
            fi
            ;;
        "json")
            echo "{"
            echo "  \"code_issues\": $review_issues,"
            echo "  \"security_issues\": $security_issues,"
            echo "  \"performance_issues\": $perf_issues,"
            echo "  \"total_issues\": $((review_issues + security_issues + perf_issues)),"
            echo "  \"status\": \"$(((review_issues + security_issues + perf_issues) == 0 ? "excellent" : "action_required")\""
            echo "}"
            ;;
        *)
            echo "Code Issues: $review_issues"
            echo "Security Issues: $security_issues"
            echo "Performance Issues: $perf_issues"
            echo "Total Issues: $((review_issues + security_issues + perf_issues))"
            echo ""
            if [[ $((review_issues + security_issues + perf_issues)) -eq 0 ]]; then
                log_success "Excellent! No issues found."
            else
                log_warn "Action required: Please address the issues above."
            fi
            ;;
    esac
}

# Usage
show_usage() {
    cat << EOF
Speccy Kit - Code Review Assistant

USAGE:
    $0 [OPTIONS] [FILE...]

OPTIONS:
    -f, --format FORMAT    Output format: text|markdown|json (default: text)
    -a, --auto-fix         Auto-fix fixable issues
    -s, --severity LEVEL   Minimum severity: low|medium|high (default: medium)
    --all                   Review all files
    --security-only        Run security scan only
    --performance-only     Run performance analysis only
    -h, --help             Show this help

EXAMPLES:
    $0 src/app.js                     # Review single file
    $0 --all                          # Review all files
    $0 --auto-fix --format markdown  # Auto-fix with markdown output
    $0 --security-only                # Security scan only
    $0 --performance-only             # Performance analysis only

EOF
}

# Main execution
main() {
    local review_issues=0
    local security_issues=0
    local perf_issues=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -a|--auto-fix)
                AUTO_FIX="true"
                shift
                ;;
            -s|--severity)
                SEVERITY="$2"
                shift 2
                ;;
            --all)
                review_issues=$(review_all_files)
                shift
                ;;
            --security-only)
                security_issues=$(security_scan)
                shift
                ;;
            --performance-only)
                perf_issues=$(performance_analysis)
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                # Review specific files
                for file in "$@"; do
                    local issues
                    issues=$(review_file "$file")
                    review_issues=$((review_issues + issues))
                done
                shift $#
                ;;
        esac
    done

    # If no specific mode was set, run all checks
    if [[ $review_issues -eq 0 && $security_issues -eq 0 && $perf_issues -eq 0 ]]; then
        if [[ "$#" -eq 0 ]]; then
            review_issues=$(review_all_files)
            security_issues=$(security_scan)
            perf_issues=$(performance_analysis)
        fi
    fi

    # Generate report
    generate_report "$review_issues" "$security_issues" "$perf_issues"

    # Exit with appropriate code
    if [[ $((review_issues + security_issues + perf_issues)) -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Execute main function
main "$@"