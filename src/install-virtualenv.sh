#!/bin/bash

# Mac Sync Wizard Installation Script (Virtual Environment Version)
# This script installs the Mac Sync Wizard in a virtual environment for non-disruptive operation

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print a styled header
print_header() {
    echo -e "\n${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo -e "┃                                                                          ┃"
    echo -e "┃  🔄 Mac Sync Wizard Installation                                         ┃"
    echo -e "┃  ${NC}$1${BLUE}                                                         "
    echo -e "┃                                                                          ┃"
    echo -e "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
}

# Function to print a success message
print_success() {
    echo -e "\n${GREEN}✅ $1${NC}\n"
}

# Function to print an error message
print_error() {
    echo -e "\n${RED}❌ $1${NC}\n"
}

# Function to print a warning message
print_warning() {
    echo -e "\n${YELLOW}⚠️  $1${NC}\n"
}

# Function to print a step message
print_step() {
    echo -e "\n${CYAN}➡️  $1${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        print_error "This script must be run on macOS"
        exit 1
    fi
}

# Function to check for required dependencies
check_dependencies() {
    print_step "Checking dependencies..."
    
    local missing_deps=()
    
    # Check for Git
    if ! command_exists git; then
        missing_deps+=("git")
    fi
    
    # Check for Python 3
    if ! command_exists python3; then
        missing_deps+=("python3")
    fi
    
    # Check for venv module
    if ! python3 -c "import venv" &>/dev/null; then
        missing_deps+=("python3-venv")
    fi
    
    # If there are missing dependencies, try to install them
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_warning "The following dependencies are missing: ${missing_deps[*]}"
        
        # Check if Homebrew is installed
        if command_exists brew; then
            print_step "Installing missing dependencies with Homebrew..."
            
            for dep in "${missing_deps[@]}"; do
                echo "Installing $dep..."
                brew install "$dep"
                
                # Check if installation was successful
                if [[ "$dep" == "python3" ]] && ! command_exists python3; then
                    print_error "Failed to install $dep"
                    exit 1
                elif [[ "$dep" == "git" ]] && ! command_exists git; then
                    print_error "Failed to install $dep"
                    exit 1
                fi
            done
        else
            print_warning "Homebrew is not installed. Please install the following dependencies manually: ${missing_deps[*]}"
            print_warning "You can install Homebrew by running: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            
            read -p "Would you like to install Homebrew now? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                
                # Check if Homebrew was installed successfully
                if command_exists brew; then
                    print_success "Homebrew installed successfully"
                    
                    # Try to install dependencies again
                    for dep in "${missing_deps[@]}"; do
                        echo "Installing $dep..."
                        brew install "$dep"
                        
                        # Check if installation was successful
                        if [[ "$dep" == "python3" ]] && ! command_exists python3; then
                            print_error "Failed to install $dep"
                            exit 1
                        elif [[ "$dep" == "git" ]] && ! command_exists git; then
                            print_error "Failed to install $dep"
                            exit 1
                        fi
                    done
                else
                    print_error "Failed to install Homebrew"
                    exit 1
                fi
            else
                print_error "Cannot continue without required dependencies"
                exit 1
            fi
        fi
    else
        print_success "All dependencies are installed"
    fi
}

# Function to create the application directory structure
create_app_structure() {
    print_step "Creating application directory structure..."
    
    # Create the application directory
    APP_DIR="$HOME/.mac-sync-wizard"
    mkdir -p "$APP_DIR"
    mkdir -p "$APP_DIR/bin"
    mkdir -p "$APP_DIR/config"
    mkdir -p "$APP_DIR/logs"
    mkdir -p "$APP_DIR/repo"
    
    print_success "Application directory structure created at $APP_DIR"
}

# Function to create and setup virtual environment
setup_virtual_environment() {
    print_step "Setting up virtual environment..."
    
    # Create virtual environment
    python3 -m venv "$APP_DIR/venv"
    
    # Check if virtual environment was created successfully
    if [ ! -d "$APP_DIR/venv" ]; then
        print_error "Failed to create virtual environment"
        exit 1
    fi
    
    # Activate virtual environment
    source "$APP_DIR/venv/bin/activate"
    
    # Install required packages
    print_step "Installing required packages in virtual environment..."
    
    # Create a temporary requirements file
    cat > /tmp/mac-sync-requirements.txt << EOF
rich>=12.0.0
pyyaml>=6.0
gitpython>=3.1.0
schedule>=1.1.0
EOF
    
    # Install dependencies
    pip install -r /tmp/mac-sync-requirements.txt
    
    # Check if installation was successful
    if [ $? -ne 0 ]; then
        print_error "Failed to install Python dependencies in virtual environment"
        exit 1
    fi
    
    # Clean up
    rm /tmp/mac-sync-requirements.txt
    
    # Deactivate virtual environment
    deactivate
    
    print_success "Virtual environment setup completed"
}

# Function to download the application files
download_app_files() {
    print_step "Downloading application files..."
    
    # Create a temporary directory
    TMP_DIR=$(mktemp -d)
    
    # Download the latest release
    curl -L https://github.com/username/mac-sync-wizard/archive/main.tar.gz -o "$TMP_DIR/mac-sync-wizard.tar.gz"
    
    # Extract the archive
    tar -xzf "$TMP_DIR/mac-sync-wizard.tar.gz" -C "$TMP_DIR"
    
    # Copy the files to the application directory
    cp -R "$TMP_DIR/mac-sync-wizard-main/src/"* "$APP_DIR/bin/"
    
    # Make the main script executable
    chmod +x "$APP_DIR/bin/mac-sync-wizard.py"
    
    # Clean up
    rm -rf "$TMP_DIR"
    
    print_success "Application files downloaded and installed"
}

# Function to extract files from local zip
extract_local_files() {
    print_step "Extracting files from local package..."
    
    # Check if the zip file exists in the current directory
    if [ -f "mac-sync-wizard.zip" ]; then
        ZIP_PATH="mac-sync-wizard.zip"
    # Check if the zip file exists in the Downloads directory
    elif [ -f "$HOME/Downloads/mac-sync-wizard.zip" ]; then
        ZIP_PATH="$HOME/Downloads/mac-sync-wizard.zip"
    else
        print_error "Could not find mac-sync-wizard.zip in current directory or Downloads folder"
        exit 1
    fi
    
    # Create a temporary directory
    TMP_DIR=$(mktemp -d)
    
    # Extract the archive
    unzip -q "$ZIP_PATH" -d "$TMP_DIR"
    
    # Copy the files to the application directory
    cp -R "$TMP_DIR/src/"* "$APP_DIR/bin/"
    
    # Make the main script executable
    chmod +x "$APP_DIR/bin/mac-sync-wizard.py"
    
    # Clean up
    rm -rf "$TMP_DIR"
    
    print_success "Application files extracted and installed"
}

# Function to create the launcher script
create_launcher() {
    print_step "Creating launcher script..."
    
    # Create the launcher script
    cat > "$APP_DIR/bin/launcher.sh" << EOF
#!/bin/bash
# Mac Sync Wizard Launcher
# This script activates the virtual environment and runs the application

# Activate virtual environment
source "$APP_DIR/venv/bin/activate"

# Run the application
python "$APP_DIR/bin/mac-sync-wizard.py" "\$@"

# Exit with the same status as the application
exit \$?
EOF
    
    # Make it executable
    chmod +x "$APP_DIR/bin/launcher.sh"
    
    print_success "Launcher script created"
}

# Function to create the executable symlink
create_executable_symlink() {
    print_step "Creating executable symlink..."
    
    # Create ~/.local/bin directory if it doesn't exist
    mkdir -p "$HOME/.local/bin"
    
    # Create symlink
    ln -sf "$APP_DIR/bin/launcher.sh" "$HOME/.local/bin/mac-sync-wizard"
    
    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        print_warning "~/.local/bin is not in your PATH"
        
        # Determine which shell configuration file to use
        SHELL_CONFIG=""
        if [ -f "$HOME/.zshrc" ]; then
            SHELL_CONFIG="$HOME/.zshrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            SHELL_CONFIG="$HOME/.bash_profile"
        elif [ -f "$HOME/.bashrc" ]; then
            SHELL_CONFIG="$HOME/.bashrc"
        fi
        
        if [ -n "$SHELL_CONFIG" ]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_CONFIG"
            print_warning "Added ~/.local/bin to your PATH in $SHELL_CONFIG"
            print_warning "Please restart your terminal or run: export PATH=\"$HOME/.local/bin:\$PATH\""
        else
            print_warning "Could not find shell configuration file"
            print_warning "Please add ~/.local/bin to your PATH manually"
        fi
    fi
    
    print_success "Executable symlink created at ~/.local/bin/mac-sync-wizard"
}

# Function to run the initial setup
run_initial_setup() {
    print_step "Running initial setup..."
    
    # Run the setup wizard
    "$HOME/.local/bin/mac-sync-wizard" setup
    
    # Check if setup was successful
    if [ $? -ne 0 ]; then
        print_warning "Initial setup encountered some issues. You can run it again with: mac-sync-wizard setup"
    else
        print_success "Initial setup completed successfully"
    fi
}

# Main installation function
install_mac_sync_wizard() {
    print_header "Installing Mac Sync Wizard..."
    
    # Check if running on macOS
    check_macos
    
    # Check for required dependencies
    check_dependencies
    
    # Create the application directory structure
    create_app_structure
    
    # Setup virtual environment
    setup_virtual_environment
    
    # Extract files from local zip or download them
    if [ -f "mac-sync-wizard.zip" ] || [ -f "$HOME/Downloads/mac-sync-wizard.zip" ]; then
        extract_local_files
    else
        download_app_files
    fi
    
    # Create the launcher script
    create_launcher
    
    # Create the executable symlink
    create_executable_symlink
    
    # Ask if the user wants to run the initial setup
    read -p "Would you like to run the initial setup now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_initial_setup
    else
        print_step "You can run the setup later with: mac-sync-wizard setup"
    fi
    
    print_header "Installation Complete!"
    echo -e "\n${GREEN}Mac Sync Wizard has been successfully installed.${NC}"
    echo -e "\n${CYAN}Usage:${NC}"
    echo -e "  mac-sync-wizard setup     - Run the setup wizard"
    echo -e "  mac-sync-wizard sync      - Perform a manual sync"
    echo -e "  mac-sync-wizard config    - Configure sync settings"
    echo -e "  mac-sync-wizard status    - Check sync status"
    echo -e "  mac-sync-wizard help      - Show help information"
    echo -e "\n${YELLOW}Note: If mac-sync-wizard command is not found, you may need to restart your terminal${NC}"
    echo -e "${YELLOW}or run: export PATH=\"$HOME/.local/bin:\$PATH\"${NC}\n"
}

# Run the installation
install_mac_sync_wizard
