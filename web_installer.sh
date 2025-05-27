#!/bin/bash

# iconfig Web Installer
# This script downloads and installs iconfig from GitHub
# Usage: curl -fsSL https://raw.githubusercontent.com/specbug/iconfig/main/web_installer.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_OWNER="specbug"
REPO_NAME="iconfig"
BRANCH="main"
INSTALL_DIR="$HOME/.iconfig-installer"
FINAL_DIR="$HOME/.local/bin"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}   iconfig Web Installer${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check for required commands
for cmd in git curl; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: $cmd is not installed${NC}"
        echo -e "${YELLOW}Please install $cmd and try again${NC}"
        exit 1
    fi
done

# Create temporary directory for installation
echo -e "${BLUE}Creating temporary installation directory...${NC}"

# Clean up any existing installation directory to avoid conflicts
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Removing existing temporary directory...${NC}"
    rm -rf "$INSTALL_DIR"
fi

# Create fresh directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Double-check we're in an empty directory
if [ "$(ls -A)" ]; then
    echo -e "${RED}Warning: Installation directory is not empty!${NC}"
    echo -e "${YELLOW}Contents:${NC}"
    ls -la
    echo -e "${YELLOW}Cleaning up...${NC}"
    rm -rf ./* ./.[^.]* 2>/dev/null || true
fi

# Download the repository as a zip file (no git clone needed initially)
echo -e "${BLUE}Downloading iconfig...${NC}"
DOWNLOAD_URL="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/$BRANCH.zip"

if curl -fsSL "$DOWNLOAD_URL" -o iconfig.zip; then
    echo -e "${GREEN}✓ Download complete${NC}"
else
    echo -e "${RED}Failed to download iconfig${NC}"
    exit 1
fi

# Extract the zip file
echo -e "${BLUE}Extracting files...${NC}"

# Clean up any existing extracted directories first
echo -e "${YELLOW}Cleaning up any previous extraction attempts...${NC}"
rm -rf "$REPO_NAME"-* 2>/dev/null || true

if command -v unzip &> /dev/null; then
    # Extract quietly and overwrite if needed
    unzip -q -o iconfig.zip
    rm iconfig.zip
    
    # Find the extracted directory (GitHub adds -main or -master suffix)
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "$REPO_NAME-*" | head -1)
    
    if [ -n "$EXTRACTED_DIR" ]; then
        echo -e "${YELLOW}Found extracted directory: $EXTRACTED_DIR${NC}"
        # Use cp instead of mv to avoid issues, then remove
        cp -R "$EXTRACTED_DIR"/* . 2>/dev/null || true
        cp -R "$EXTRACTED_DIR"/.[^.]* . 2>/dev/null || true
        # Force remove the directory
        rm -rf "$EXTRACTED_DIR"
    else
        echo -e "${RED}Warning: Could not find extracted directory${NC}"
    fi
elif command -v tar &> /dev/null; then
    # Some systems might not have unzip but have tar
    echo -e "${YELLOW}unzip not found, trying alternative method...${NC}"
    # Download as tar.gz instead
    rm iconfig.zip
    curl -fsSL "https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/$BRANCH.tar.gz" -o iconfig.tar.gz
    tar -xzf iconfig.tar.gz
    rm iconfig.tar.gz
    
    # Find the extracted directory
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "$REPO_NAME-*" | head -1)
    
    if [ -n "$EXTRACTED_DIR" ]; then
        echo -e "${YELLOW}Found extracted directory: $EXTRACTED_DIR${NC}"
        # Use cp instead of mv to avoid issues, then remove
        cp -R "$EXTRACTED_DIR"/* . 2>/dev/null || true
        cp -R "$EXTRACTED_DIR"/.[^.]* . 2>/dev/null || true
        # Force remove the directory
        rm -rf "$EXTRACTED_DIR"
    else
        echo -e "${RED}Warning: Could not find extracted directory${NC}"
    fi
else
    echo -e "${RED}Error: Neither unzip nor tar found. Please install one of them.${NC}"
    exit 1
fi

# Verify required files exist
if [ ! -f "iconfig.py" ]; then
    echo -e "${RED}Error: iconfig.py not found in extracted files${NC}"
    ls -la
    exit 1
fi

if [ ! -f "install.sh" ]; then
    echo -e "${RED}Error: install.sh not found in extracted files${NC}"
    ls -la
    exit 1
fi

# Make install script executable
chmod +x install.sh

# Run the install script from the correct directory
echo -e "${BLUE}Running installer...${NC}"
echo -e "${YELLOW}Current directory: $(pwd)${NC}"
echo -e "${YELLOW}Files in directory:${NC}"
ls -la

# Run install.sh which will find iconfig.py in the current directory
./install.sh

# Clean up
echo -e "${BLUE}Cleaning up temporary files...${NC}"
# Make sure we're not in the directory we're about to delete
cd "$HOME"
rm -rf "$INSTALL_DIR"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}   Installation Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Run: ${BLUE}mac-sync-wizard setup${NC}"
echo -e "2. Follow the setup wizard to configure your repository"
echo -e "3. Start syncing your Mac configurations!"
echo ""
echo -e "${YELLOW}Note: You may need to restart your terminal or run:${NC}"
echo -e "${BLUE}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
echo "" 