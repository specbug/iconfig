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

# Check if this is likely a new machine setup
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
    
    # Install prerequisites
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    # Check prerequisites
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
    
    # If prerequisites are missing, show instructions
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
    
    # Ensure PATH is updated
    export PATH="$HOME/.local/bin:$PATH"
    
    # Ask for repository URL
    echo ""
    echo -e "${BLUE}Enter your existing iconfig repository URL:${NC}"
    echo -e "${YELLOW}(e.g., https://github.com/specbug/my-mac-configs.git or git@github.com:specbug/my-mac-configs.git)${NC}"
    read -p "Repository URL: " REPO_URL
    
    if [ -n "$REPO_URL" ]; then
        # Create a simple config for setup
        CONFIG_DIR="$HOME/.mac-sync-wizard/config"
        mkdir -p "$CONFIG_DIR"
        
        # Run setup with the repository URL
        echo -e "${BLUE}Configuring iconfig with your repository...${NC}"
        mac-sync-wizard setup --repo "$REPO_URL" --auto-restore
        
        # Ask about installing applications
        echo ""
        echo -e "${BLUE}Would you like to install recommended applications?${NC}"
        echo -e "${YELLOW}This includes: Cursor, PyCharm, Sublime Text, Warp, and development tools${NC}"
        read -p "Install applications now? [y/N]: " -r INSTALL_APPS
        
        if [[ "$INSTALL_APPS" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Installing applications via Homebrew...${NC}"
            
            # Create temporary Brewfile
            TEMP_BREWFILE=$(mktemp)
            cat > "$TEMP_BREWFILE" << 'EOF'
# iconfig Applications and Tools

tap 'homebrew/cask'

# Development Tools
cask 'cursor'
cask 'pycharm-ce'      # Community Edition
cask 'sublime-text'
cask 'visual-studio-code'

# Terminal & Shell
cask 'warp'
cask 'iterm2'

# Productivity
cask 'anki'
cask 'stretchly'

# Utilities
cask 'maccy'           # Clipboard manager
cask 'arc'             # Browser

# Version Control (if not already installed)
brew 'git'
brew 'git-lfs'
brew 'gh'              # GitHub CLI

# Development Languages
brew 'python@3.11'
brew 'node'
brew 'go'
brew 'ruby'

# CLI Tools
brew 'wget'
brew 'jq'
brew 'ripgrep'
brew 'fd'
brew 'bat'
brew 'eza'
brew 'fzf'

# Fonts
tap 'homebrew/cask-fonts'
cask 'font-jetbrains-mono'
cask 'font-fira-code'
EOF
            
            # Run brew bundle
            echo -e "${YELLOW}Running brew bundle (this may take a while)...${NC}"
            if brew bundle --file="$TEMP_BREWFILE"; then
                echo -e "${GREEN}✓ Applications installed successfully${NC}"
            else
                echo -e "${YELLOW}Some applications may have failed to install (they might already be installed)${NC}"
            fi
            
            # Clean up
            rm -f "$TEMP_BREWFILE"
            
            # Also save a copy for future reference
            BREWFILE_PATH="$HOME/.iconfig/Brewfile"
            mkdir -p "$HOME/.iconfig"
            cat > "$BREWFILE_PATH" << 'EOF'
# iconfig Recommended Applications
# Re-run with: brew bundle --file ~/.iconfig/Brewfile

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

# Add more apps as needed...
EOF
            echo -e "${GREEN}✓ Saved Brewfile to $BREWFILE_PATH for future use${NC}"
        else
            # Just create the Brewfile for later
            BREWFILE_PATH="$HOME/.iconfig/Brewfile"
            mkdir -p "$HOME/.iconfig"
            cat > "$BREWFILE_PATH" << 'EOF'
# iconfig Recommended Applications
# Install with: brew bundle --file ~/.iconfig/Brewfile

tap 'homebrew/cask'

# Development Tools
cask 'cursor'
cask 'pycharm-ce'      # Community Edition
cask 'sublime-text'
cask 'visual-studio-code'

# Terminal & Shell
cask 'warp'
cask 'iterm2'

# Productivity
cask 'anki'
cask 'stretchly'

# Utilities
cask 'maccy'           # Clipboard manager
cask 'arc'             # Browser

# Version Control
brew 'git'
brew 'git-lfs'
brew 'gh'              # GitHub CLI

# Development Languages
brew 'python@3.11'
brew 'node'
brew 'go'
brew 'ruby'

# CLI Tools
brew 'wget'
brew 'jq'
brew 'ripgrep'
brew 'fd'
brew 'bat'
brew 'eza'
brew 'fzf'

# Fonts
tap 'homebrew/cask-fonts'
cask 'font-jetbrains-mono'
cask 'font-fira-code'
EOF
            
            echo -e "${GREEN}✓ Created Brewfile at $BREWFILE_PATH${NC}"
            echo -e "${YELLOW}To install applications later, run:${NC}"
            echo -e "${BLUE}brew bundle --file ~/.iconfig/Brewfile${NC}"
        fi
        
        echo ""
        echo -e "${GREEN}✨ New machine setup complete!${NC}"
        echo -e "${YELLOW}Your configurations have been restored.${NC}"
        echo -e "${YELLOW}Installed applications are configured with your synced settings.${NC}"
        echo -e "${YELLOW}Restart your terminal to load shell aliases and configurations.${NC}"
    else
        echo -e "${RED}No repository URL provided.${NC}"
        echo -e "${YELLOW}Run 'mac-sync-wizard setup' later to configure.${NC}"
    fi
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