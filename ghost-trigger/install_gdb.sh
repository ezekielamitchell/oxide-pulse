#!/bin/bash
# ESP32 GDB Installation Script
# Installs xtensa-esp32-elf-gdb for JTAG debugging on macOS

set -e  # Exit on error

echo "=========================================="
echo "ESP32 JTAG Debugging - GDB Installation"
echo "=========================================="
echo ""

# Detect architecture
ARCH=$(uname -m)
OS=$(uname -s)

if [ "$OS" != "Darwin" ]; then
    echo "ERROR: This script is for macOS only"
    exit 1
fi

# Check if xtensa-esp32-elf-gdb is already installed
if command -v xtensa-esp32-elf-gdb &> /dev/null; then
    echo "✅ xtensa-esp32-elf-gdb is already installed"
    xtensa-esp32-elf-gdb --version | head -1
    echo ""
    read -p "Do you want to reinstall? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo "Detected architecture: $ARCH"
echo ""

# Method 1: Try Homebrew first
echo "Attempting installation via Homebrew..."
if command -v brew &> /dev/null; then
    echo "✓ Homebrew found"

    # Check if tap exists
    if brew tap | grep -q "espressif/homebrew-esp"; then
        echo "✓ Espressif tap already added"
    else
        echo "Adding Espressif tap..."
        brew tap espressif/homebrew-esp
    fi

    echo "Installing esp32-elf-gdb..."
    if brew install esp32-elf-gdb; then
        echo ""
        echo "✅ Successfully installed via Homebrew!"
        xtensa-esp32-elf-gdb --version | head -1
        exit 0
    else
        echo "⚠️  Homebrew installation failed, trying manual installation..."
    fi
else
    echo "⚠️  Homebrew not found, trying manual installation..."
fi

# Method 2: Manual installation
echo ""
echo "=========================================="
echo "Manual Installation"
echo "=========================================="

GDB_VERSION="esp-gdb-v13.2_20240530"
INSTALL_DIR="$HOME/.espressif/tools/xtensa-esp-elf-gdb"

# Determine download URL based on architecture
if [ "$ARCH" = "arm64" ]; then
    DOWNLOAD_URL="https://github.com/espressif/binutils-gdb/releases/download/${GDB_VERSION}/xtensa-esp-elf-gdb-13.2_20240530-aarch64-apple-darwin.tar.xz"
    ARCHIVE_NAME="xtensa-esp-elf-gdb-13.2_20240530-aarch64-apple-darwin.tar.xz"
elif [ "$ARCH" = "x86_64" ]; then
    DOWNLOAD_URL="https://github.com/espressif/binutils-gdb/releases/download/${GDB_VERSION}/xtensa-esp-elf-gdb-13.2_20240530-x86_64-apple-darwin.tar.xz"
    ARCHIVE_NAME="xtensa-esp-elf-gdb-13.2_20240530-x86_64-apple-darwin.tar.xz"
else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
fi

echo "Download URL: $DOWNLOAD_URL"
echo "Install directory: $INSTALL_DIR"
echo ""

# Create installation directory
mkdir -p "$INSTALL_DIR"
cd /tmp

# Download
if [ ! -f "$ARCHIVE_NAME" ]; then
    echo "Downloading GDB..."
    if command -v wget &> /dev/null; then
        wget "$DOWNLOAD_URL"
    elif command -v curl &> /dev/null; then
        curl -L -O "$DOWNLOAD_URL"
    else
        echo "❌ Neither wget nor curl found. Please install one of them."
        exit 1
    fi
else
    echo "Archive already downloaded, skipping..."
fi

# Extract
echo "Extracting..."
tar -xf "$ARCHIVE_NAME" -C "$INSTALL_DIR" --strip-components=1

# Cleanup
echo "Cleaning up..."
rm -f "$ARCHIVE_NAME"

# Check installation
if [ -f "$INSTALL_DIR/bin/xtensa-esp32-elf-gdb" ]; then
    echo ""
    echo "✅ Installation successful!"
    echo ""
    echo "=========================================="
    echo "Post-Installation Steps"
    echo "=========================================="
    echo ""
    echo "Add the following to your shell profile:"
    echo ""

    # Detect shell
    SHELL_NAME=$(basename "$SHELL")
    if [ "$SHELL_NAME" = "zsh" ]; then
        PROFILE="$HOME/.zshrc"
    elif [ "$SHELL_NAME" = "bash" ]; then
        PROFILE="$HOME/.bash_profile"
    else
        PROFILE="$HOME/.profile"
    fi

    echo "  export PATH=\"\$HOME/.espressif/tools/xtensa-esp-elf-gdb/bin:\$PATH\""
    echo ""
    echo "To add it automatically, run:"
    echo "  echo 'export PATH=\"\$HOME/.espressif/tools/xtensa-esp-elf-gdb/bin:\$PATH\"' >> $PROFILE"
    echo "  source $PROFILE"
    echo ""
    echo "Then verify with:"
    echo "  xtensa-esp32-elf-gdb --version"
    echo ""

    # Offer to add to PATH automatically
    read -p "Add to PATH in $PROFILE now? (Y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        if ! grep -q "xtensa-esp-elf-gdb" "$PROFILE" 2>/dev/null; then
            echo "" >> "$PROFILE"
            echo "# ESP32 JTAG Debugging - GDB" >> "$PROFILE"
            echo "export PATH=\"\$HOME/.espressif/tools/xtensa-esp-elf-gdb/bin:\$PATH\"" >> "$PROFILE"
            echo "✅ Added to $PROFILE"
            echo ""
            echo "Run this to reload your shell:"
            echo "  source $PROFILE"
        else
            echo "⚠️  PATH entry already exists in $PROFILE"
        fi
    fi
else
    echo "❌ Installation failed - GDB binary not found"
    exit 1
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
