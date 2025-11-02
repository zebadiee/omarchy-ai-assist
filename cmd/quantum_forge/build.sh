#!/bin/bash

# Quantum-Forge Build Script
set -e

echo "🔷 Building Quantum-Forge CLI tool..."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go 1.22.5 or later."
    exit 1
fi

# Check Go version
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
REQUIRED_VERSION="1.22.5"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Go version $GO_VERSION is too old. Required: $REQUIRED_VERSION or later"
    exit 1
fi

echo "✅ Go version check passed: $GO_VERSION"

# Build the binary
echo "🔨 Building quantum-forge..."
go build -o ../../quantum-forge -ldflags="-s -w" .

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📦 Binary created: ../../quantum-forge"

    # Make it executable
    chmod +x ../../quantum-forge
    echo "🔐 Made binary executable"

    # Show usage
    echo ""
    echo "🚀 Usage:"
    echo "   ./quantum-forge -backend stdout    # Show prompt (default)"
    echo "   ./quantum-forge -backend file      # Save to file"
    echo "   ./quantum-forge -list              # List blueprints"
    echo "   ./quantum-forge -show-prompt       # Show prompt only"
    echo "   ./quantum-forge -save-only         # Save without injection"
    echo "   ./quantum-forge -open-tasks 5      # Override task count"

else
    echo "❌ Build failed!"
    exit 1
fi