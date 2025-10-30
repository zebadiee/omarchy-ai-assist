#!/usr/bin/env bash
# Common safety header for scripts - include with: source ./tools/common_header.sh

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }

# Dependency checker
need(){
  if ! command -v "$1" >/dev/null 2>&1; then
    log_error "Missing required dependency: $1"
    exit 1
  fi
}

# Optional dependency checker
opt_need(){
  if ! command -v "$1" >/dev/null 2>&1; then
    log_warn "Optional dependency missing: $1 (some features may not work)"
    return 1
  fi
}

# GPU awareness
gpu_vendor() {
  if lspci | grep -qi 'NVIDIA'; then
    echo "nvidia"
  elif lspci | grep -qi 'AMD'; then
    echo "amd"
  elif lspci | grep -qi 'Intel'; then
    echo "intel"
  else
    echo "unknown"
  fi
}

# GPU-specific checks
check_gpu_tools() {
  case "$(gpu_vendor)" in
    nvidia)
      if ! opt_need nvidia-smi; then
        log_warn "NVIDIA GPU detected but nvidia-smi not found"
      fi
      ;;
    amd)
      if ! opt_need radeontop; then
        log_info "AMD GPU detected (radeontop optional)"
      fi
      ;;
    intel)
      if ! opt_need intel_gpu_top; then
        log_info "Intel GPU detected (intel_gpu_top optional)"
      fi
      ;;
    unknown)
      log_info "GPU vendor unknown or no GPU detected"
      ;;
  esac
}

# System info
SYSTEM_INFO=$(uname -s)
log_info "Running on: $SYSTEM_INFO"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
  log_warn "Running as root - consider using user-level services where possible"
fi

# Check if in interactive terminal
if [[ -t 0 ]]; then
  log_info "Running in interactive terminal"
else
  log_info "Running in non-interactive mode"
fi

# Load GPU tools
check_gpu_tools

# Common dependencies
need jq
need awk

# Optional but common dependencies
opt_need bc
opt_need gawk
opt_need playerctl

# Safety checks
log_info "Common header loaded successfully"
log_info "GPU vendor: $(gpu_vendor)"

# Export functions for use in other scripts
export -f log_info log_warn log_error log_success need opt_need gpu_vendor check_gpu_tools