#!/bin/bash

# iconfig Web Installer
# This script downloads and installs iconfig from GitHub
# 
# Usage:
#   curl -O https://raw.githubusercontent.com/specbug/iconfig/main/web_installer.sh
#   chmod +x web_installer.sh
#   ./web_installer.sh

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

# Download the repository as a zip file
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

if command -v unzip &> /dev/null; then
    unzip -q -o iconfig.zip
    rm iconfig.zip
    
    # Move files from extracted directory to current directory
    mv "$REPO_NAME-$BRANCH"/* . 2>/dev/null || true
    mv "$REPO_NAME-$BRANCH"/.[^.]* . 2>/dev/null || true
    rmdir "$REPO_NAME-$BRANCH"
else
    echo -e "${RED}Error: unzip not found. Please install it with: brew install unzip${NC}"
    exit 1
fi

# Verify required files exist
if [ ! -f "iconfig.py" ]; then
    echo -e "${RED}Error: iconfig.py not found${NC}"
    exit 1
fi

if [ ! -f "install.sh" ]; then
    echo -e "${RED}Error: install.sh not found${NC}"
    exit 1
fi

# Make install script executable
chmod +x install.sh

# Run install.sh (answer 'n' to avoid setup prompt)
echo -e "${BLUE}Installing iconfig...${NC}"
echo "n" | ./install.sh

# Clean up
cd "$HOME"
rm -rf "$INSTALL_DIR"

# Ensure PATH is updated
export PATH="$HOME/.local/bin:$PATH"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}   Installation Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Ask if this is a new machine setup
echo -e "${BLUE}Is this a new machine where you want to restore existing configurations?${NC}"
echo -e "${YELLOW}(If yes, we'll help you set up prerequisites and restore your configs)${NC}"
echo ""
read -p "Is this a new machine setup? [Y/n]: " -r NEW_MACHINE
echo ""

if [[ -z "$NEW_MACHINE" || "$NEW_MACHINE" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Starting new machine setup...${NC}"
    
    # Check prerequisites FIRST
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    MISSING_PREREQS=()
    
    # Check for Homebrew
    if ! command -v brew &> /dev/null; then
        MISSING_PREREQS+=("Homebrew (install from https://brew.sh)")
    fi
    
    # Check for Git
    if ! command -v git &> /dev/null; then
        MISSING_PREREQS+=("Git (run: brew install git)")
    fi
    
    # Check for Git LFS
    if ! command -v git-lfs &> /dev/null; then
        MISSING_PREREQS+=("Git LFS (run: brew install git-lfs && git lfs install)")
    fi
    
    # If prerequisites are missing, show instructions and exit
    if [ ${#MISSING_PREREQS[@]} -gt 0 ]; then
        echo -e "${RED}Missing prerequisites:${NC}"
        for prereq in "${MISSING_PREREQS[@]}"; do
            echo -e "  - $prereq"
        done
        echo ""
        echo -e "${YELLOW}Please install the missing prerequisites and run this installer again.${NC}"
        echo -e "${YELLOW}Quick install commands:${NC}"
        echo -e "${BLUE}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
        echo -e "${BLUE}brew install git git-lfs${NC}"
        echo -e "${BLUE}git lfs install${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All prerequisites installed${NC}"
    
    # Get the configurations repository (always required for new machine setup)
    echo ""
    echo -e "${BLUE}Enter your Mac configurations repository URL:${NC}"
    echo -e "${YELLOW}This is the repository from your existing Mac where all your settings are stored${NC}"
    echo -e "${YELLOW}(e.g., https://github.com/yourusername/my-mac-configs.git or git@github.com:yourusername/my-mac-configs.git)${NC}"
    read -p "Repository URL: " REPO_URL
    
    # Repository URL is required
    if [ -z "$REPO_URL" ]; then
        echo -e "${RED}Error: Repository URL is required for new machine setup${NC}"
        echo -e "${YELLOW}You need an existing repository with your Mac configurations to restore from.${NC}"
        exit 1
    fi
    
    # Now run setup with the repository URL
    echo -e "${BLUE}Configuring iconfig with your repository...${NC}"
    mac-sync-wizard setup --repo "$REPO_URL" --auto-restore
        
        # Create Brewfile
        BREWFILE_PATH="$HOME/.iconfig/Brewfile"
        mkdir -p "$HOME/.iconfig"
        cat > "$BREWFILE_PATH" << 'EOF'
# iconfig Recommended Applications
# Install with: brew bundle --file ~/.iconfig/Brewfile

tap 'homebrew/cask'

# Development Tools
cask 'cursor'
cask 'pycharm-ce'
cask 'sublime-text'
cask 'visual-studio-code'

# Terminal & Shell
cask 'warp'
cask 'iterm2'

# Productivity
cask 'anki'
cask 'stretchly'

# Utilities
cask 'maccy'
cask 'arc'

# Version Control
brew 'git'
brew 'git-lfs'
brew 'gh'

# Development Languages
brew 'python@3.11'
brew 'node'

# CLI Tools
brew 'wget'
brew 'jq'
brew 'ripgrep'
brew 'fd'
brew 'bat'
brew 'fzf'

# Fonts
tap 'homebrew/cask-fonts'
cask 'font-jetbrains-mono'
cask 'font-fira-code'
EOF
        
        echo -e "${GREEN}✓ Created Brewfile at $BREWFILE_PATH${NC}"
        
        # Ask about installing applications
        echo ""
        echo -e "${BLUE}Would you like to install recommended applications?${NC}"
        echo -e "${YELLOW}This includes: Cursor, PyCharm, Sublime Text, Warp, and development tools${NC}"
        read -p "Install applications now? [y/N]: " -r INSTALL_APPS
        
        if [[ "$INSTALL_APPS" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Installing applications via Homebrew...${NC}"
            if brew bundle --file="$BREWFILE_PATH"; then
                echo -e "${GREEN}✓ Applications installed successfully${NC}"
            else
                echo -e "${YELLOW}Some applications may have failed to install${NC}"
            fi
        else
            echo -e "${YELLOW}To install applications later, run:${NC}"
            echo -e "${BLUE}brew bundle --file ~/.iconfig/Brewfile${NC}"
        fi
        
    echo ""
    echo -e "${GREEN}✨ New machine setup complete!${NC}"
    echo -e "${YELLOW}Your configurations have been restored.${NC}"
    echo -e "${YELLOW}Restart your terminal to load shell aliases and configurations.${NC}"
else
    # Regular setup for existing machine
    echo -e "${YELLOW}For existing machine setup:${NC}"
    echo -e "1. Run: ${BLUE}mac-sync-wizard setup${NC} to configure sync"
    echo -e "2. Run: ${BLUE}mac-sync-wizard sync${NC} to sync your configurations"
    echo ""
    echo -e "${YELLOW}Note: You may need to restart your terminal or run:${NC}"
    echo -e "${BLUE}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
fi

echo "" 