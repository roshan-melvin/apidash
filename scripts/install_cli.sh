#!/bin/bash
set -e

echo "Building APIDash native CLI..."

# Compile the pure Dart CLI
dart compile exe bin/apidash_cli.dart -o bin/apidash

echo "Compilation successful!"
echo "Installing to /usr/local/bin/apidash (requires sudo)..."

# Move to bin with sudo
sudo mv bin/apidash /usr/local/bin/apidash

echo "✅ apidash CLI installed! Run: apidash --help"

echo "--------------------------------------------------------"
echo "Manual install (no sudo):"
echo "  dart compile exe bin/apidash_cli.dart -o bin/apidash"
echo '  export PATH="$PATH:$(pwd)/bin"   # add to ~/.bashrc or ~/.zshrc'
echo "--------------------------------------------------------"
