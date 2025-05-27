#!/bin/bash

# iconfig Web Installer
# This script downloads and installs iconfig from GitHub
# 
# Usage:
#   curl -O https://raw.githubusercontent.com/specbug/iconfig/main/web_installer.sh
#   chmod +x web_installer.sh
#   ./web_installer.sh

set -e

# Request sudo upfront if needed (for potential app installations)
# This keeps sudo alive for the duration of the script
if [ "$EUID" -ne 0 ]; then
    echo "This script may need administrator privileges for some operations."
    echo "Please enter your password if prompted."
    sudo -v
    
    # Keep sudo alive in the background
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_PID=$!
    
    # Cleanup function to kill the sudo keepalive
    cleanup() {
        if [ ! -z "$SUDO_PID" ]; then
            kill $SUDO_PID 2>/dev/null || true
        fi
    }
    trap cleanup EXIT
fi

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
    
        # Clone the repository first
    echo -e "${BLUE}Cloning your configurations repository...${NC}"
    REPO_DIR="$HOME/.mac-sync-wizard/repo"
    
    # Remove existing repo directory if it exists
    if [ -d "$REPO_DIR" ]; then
        echo -e "${YELLOW}Removing existing repository directory...${NC}"
        rm -rf "$REPO_DIR"
    fi
    
    # Clone the repository
    if git clone "$REPO_URL" "$REPO_DIR"; then
        echo -e "${GREEN}✓ Repository cloned successfully${NC}"
    else
        echo -e "${RED}Failed to clone repository${NC}"
        echo -e "${YELLOW}Please check your repository URL and credentials${NC}"
        exit 1
    fi
    
    # Create config with all syncable utilities enabled
    echo -e "${BLUE}Creating configuration...${NC}"
    CONFIG_DIR="$HOME/.mac-sync-wizard/config"
    mkdir -p "$CONFIG_DIR"
    
    # Create config that enables all syncable utilities
    python3 -c "
import json
import os

# Default utilities that should be synced
UTILITY_CONFIGS = {
    'cursor': {'enabled': True, 'paths': ['~/Library/Application Support/Cursor/User/keybindings.json', '~/Library/Application Support/Cursor/User/settings.json', '~/Library/Application Support/Cursor/User/extensions/'], 'exclude_patterns': ['*.log', 'Cache/*']},
    'pycharm': {'enabled': True, 'paths': ['~/Library/Application Support/JetBrains/PyCharm*/options/', '~/Library/Application Support/JetBrains/PyCharm*/keymaps/', '~/Library/Application Support/JetBrains/PyCharm*/codestyles/', '~/Library/Application Support/JetBrains/PyCharm*/templates/', '~/Library/Application Support/JetBrains/PyCharm*/colors/', '~/Library/Application Support/JetBrains/PyCharm*/fileTemplates/', '~/Library/Application Support/JetBrains/PyCharm*/inspection/', '~/Library/Application Support/JetBrains/PyCharm*/tools/', '~/Library/Application Support/JetBrains/PyCharm*/shelf/'], 'exclude_patterns': ['*.log', 'Cache/*', 'workspace/', 'tasks/', 'scratches/', 'jdbc-drivers/', 'ssl/', 'port', 'plugins/updatedPlugins.xml', 'marketplace/', '*.hprof', '*.snapshot', 'eval/', 'repair/', '*/.DS_Store']},
    'sublime': {'enabled': True, 'paths': ['~/Library/Application Support/Sublime Text/Packages/User/'], 'exclude_patterns': ['*.log', 'Cache/*']},
    'trackpad': {'enabled': True, 'paths': ['~/Library/Preferences/com.apple.driver.AppleBluetoothMultitouch.trackpad.plist', '~/Library/Preferences/com.apple.AppleMultitouchTrackpad.plist'], 'exclude_patterns': []},
    'git': {'enabled': True, 'paths': ['~/.gitconfig', '~/.config/git/'], 'exclude_patterns': []},
    'warp': {'enabled': True, 'paths': ['~/.warp/themes/', '~/.warp/launch_configurations/', '~/.warp/user_scripts/', '~/.warp/settings.yaml', '~/.warp/keybindings.json'], 'exclude_patterns': ['Cache/*', '*.log', '*.pyc', '__pycache__', '*.sock', '*.pid']},
    'fonts': {'enabled': True, 'paths': ['~/Library/Fonts/'], 'exclude_patterns': [], 'include_patterns': [], 'custom_fonts': []},
    'anki': {'enabled': True, 'paths': ['~/Library/Application Support/Anki2/addons21/', '~/Library/Application Support/Anki2/prefs21.db'], 'exclude_patterns': ['*.log']},
    'stretchly': {'enabled': True, 'paths': ['~/Library/Application Support/stretchly/'], 'exclude_patterns': ['*.log']},
    'maccy': {'enabled': True, 'paths': ['~/Library/Containers/org.p0deje.Maccy/Data/Library/Preferences/org.p0deje.Maccy.plist'], 'exclude_patterns': []},
    'shell': {'enabled': True, 'paths': ['~/.iconfig/shell/'], 'exclude_patterns': []},
    'arc': {'enabled': False, 'paths': ['~/Library/Application Support/Arc/', '~/Library/Preferences/company.thebrowser.Arc.plist'], 'exclude_patterns': ['Cache/*', '*.log']},
    'logi': {'enabled': False, 'paths': ['~/Library/Preferences/com.logi.optionsplus.plist', '~/Library/Application Support/LogiOptionsPlus/config.json', '~/Library/Application Support/LogiOptionsPlus/settings.db', '~/Library/Application Support/LogiOptionsPlus/macros.db', '~/Library/Application Support/LogiOptionsPlus/permissions.json', '~/Library/Application Support/LogiOptionsPlus/cc_config.json'], 'exclude_patterns': []},
    '1password': {'enabled': False, 'paths': ['~/Library/Application Support/1Password/', '~/Library/Preferences/com.1password.1password.plist'], 'exclude_patterns': ['*.log', 'Cache/*']}
}

config = {
    'repository': {
        'url': '$REPO_URL',
        'branch': 'main',
        'auth_type': 'ssh'
    },
    'sync': {
        'frequency': 21600,
        'auto_commit': True,
        'commit_message_template': 'Auto-sync: {date} - {changes}',
        'pull_strategy': 'rebase'
    },
    'notifications': {
        'level': 'errors_only',
        'method': 'terminal-notifier'
    },
    'utilities': UTILITY_CONFIGS
}

config_path = os.path.expanduser('$CONFIG_DIR/sync_config.json')
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print('✓ Configuration created with all syncable utilities enabled')
"
    
    echo -e "${GREEN}✓ Configuration complete${NC}"
    
    # Create Brewfile with existence checks
    BREWFILE_PATH="$HOME/.iconfig/Brewfile"
    mkdir -p "$HOME/.iconfig"
    
    echo -e "${BLUE}Checking installed applications...${NC}"
    
    # Function to check if a cask is installed
    check_cask_installed() {
        brew list --cask "$1" &>/dev/null
    }
    
    # Function to check if a formula is installed
    check_formula_installed() {
        brew list --formula "$1" &>/dev/null
    }
    
    # Start creating Brewfile
    cat > "$BREWFILE_PATH" << 'EOF'
# iconfig Recommended Applications
# Install with: brew bundle --file ~/.iconfig/Brewfile
# This file only includes applications that are not already installed

tap 'homebrew/cask'
tap 'homebrew/cask-fonts'

EOF
    
    # Check and add casks
    echo "# Development Tools" >> "$BREWFILE_PATH"
    check_cask_installed 'cursor' || echo "cask 'cursor'" >> "$BREWFILE_PATH"
    check_cask_installed 'pycharm-ce' || echo "cask 'pycharm-ce'" >> "$BREWFILE_PATH"
    check_cask_installed 'sublime-text' || echo "cask 'sublime-text'" >> "$BREWFILE_PATH"
    check_cask_installed 'visual-studio-code' || echo "cask 'visual-studio-code'" >> "$BREWFILE_PATH"
    
    echo -e "\n# Terminal & Shell" >> "$BREWFILE_PATH"
    check_cask_installed 'warp' || echo "cask 'warp'" >> "$BREWFILE_PATH"
    check_cask_installed 'iterm2' || echo "cask 'iterm2'" >> "$BREWFILE_PATH"
    
    echo -e "\n# Productivity" >> "$BREWFILE_PATH"
    check_cask_installed 'anki' || echo "cask 'anki'" >> "$BREWFILE_PATH"
    check_cask_installed 'stretchly' || echo "cask 'stretchly'" >> "$BREWFILE_PATH"
    
    echo -e "\n# Utilities" >> "$BREWFILE_PATH"
    check_cask_installed 'maccy' || echo "cask 'maccy'" >> "$BREWFILE_PATH"
    check_cask_installed 'arc' || echo "cask 'arc'" >> "$BREWFILE_PATH"
    
    echo -e "\n# Version Control" >> "$BREWFILE_PATH"
    check_formula_installed 'git' || echo "brew 'git'" >> "$BREWFILE_PATH"
    check_formula_installed 'git-lfs' || echo "brew 'git-lfs'" >> "$BREWFILE_PATH"
    check_formula_installed 'gh' || echo "brew 'gh'" >> "$BREWFILE_PATH"
    
    echo -e "\n# Development Languages" >> "$BREWFILE_PATH"
    check_formula_installed 'python@3.11' || echo "brew 'python@3.11'" >> "$BREWFILE_PATH"
    check_formula_installed 'node' || echo "brew 'node'" >> "$BREWFILE_PATH"
    
    echo -e "\n# CLI Tools" >> "$BREWFILE_PATH"
    check_formula_installed 'wget' || echo "brew 'wget'" >> "$BREWFILE_PATH"
    check_formula_installed 'jq' || echo "brew 'jq'" >> "$BREWFILE_PATH"
    check_formula_installed 'ripgrep' || echo "brew 'ripgrep'" >> "$BREWFILE_PATH"
    check_formula_installed 'fd' || echo "brew 'fd'" >> "$BREWFILE_PATH"
    check_formula_installed 'bat' || echo "brew 'bat'" >> "$BREWFILE_PATH"
    check_formula_installed 'fzf' || echo "brew 'fzf'" >> "$BREWFILE_PATH"
    
    echo -e "\n# Fonts" >> "$BREWFILE_PATH"
    check_cask_installed 'font-jetbrains-mono' || echo "cask 'font-jetbrains-mono'" >> "$BREWFILE_PATH"
    check_cask_installed 'font-fira-code' || echo "cask 'font-fira-code'" >> "$BREWFILE_PATH"
        
        echo -e "${GREEN}✓ Created Brewfile at $BREWFILE_PATH${NC}"
        
        # Ask about installing applications
        echo ""
        echo -e "${BLUE}Would you like to install recommended applications?${NC}"
        echo -e "${YELLOW}This includes: Cursor, PyCharm, Sublime Text, Warp, and development tools${NC}"
        read -p "Install applications now? [y/N]: " -r INSTALL_APPS
        
                if [[ "$INSTALL_APPS" =~ ^[Yy]$ ]]; then
            # Count what needs to be installed
            NEW_APPS=$(grep -E "^(cask|brew) " "$BREWFILE_PATH" | wc -l | tr -d ' ')
            
            if [ "$NEW_APPS" -eq 0 ]; then
                echo -e "${GREEN}✓ All recommended applications are already installed!${NC}"
            else
                echo -e "${BLUE}Installing $NEW_APPS new applications via Homebrew...${NC}"
                echo -e "${YELLOW}This may take a while and require your password for some installations.${NC}"
                
                # Show what will be installed
                echo -e "\n${BLUE}Applications to install:${NC}"
                grep -E "^(cask|brew) " "$BREWFILE_PATH" | sed 's/^/  - /'
                echo ""
                
                # Use brew bundle with verbose output
                if brew bundle --file="$BREWFILE_PATH" --verbose; then
                    echo -e "${GREEN}✓ Applications installed successfully${NC}"
                else
                    echo -e "${YELLOW}Some applications may have failed to install${NC}"
                    echo -e "${YELLOW}You can retry with: brew bundle --file ~/.iconfig/Brewfile${NC}"
                fi
            fi
        else
            # Count what would be installed
            NEW_APPS=$(grep -E "^(cask|brew) " "$BREWFILE_PATH" | wc -l | tr -d ' ')
            if [ "$NEW_APPS" -gt 0 ]; then
                echo -e "${YELLOW}Skipping installation of $NEW_APPS applications.${NC}"
                echo -e "${YELLOW}To install them later, run:${NC}"
                echo -e "${BLUE}brew bundle --file ~/.iconfig/Brewfile${NC}"
            else
                echo -e "${GREEN}✓ All recommended applications are already installed!${NC}"
            fi
        fi
    
    # Now restore configurations after applications are potentially installed
    echo ""
    echo -e "${BLUE}Restoring your Mac configurations...${NC}"
    mac-sync-wizard restore
    
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