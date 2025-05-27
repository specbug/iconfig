#!/bin/bash

# Mac Sync Wizard Simple Installation Script
# This script installs the Mac Sync Wizard as a single file with no module dependencies

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
    
    # Check for Python 3
    if ! command_exists python3; then
        missing_deps+=("python3")
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
    mkdir -p "$APP_DIR/config"
    mkdir -p "$APP_DIR/logs"
    mkdir -p "$APP_DIR/repo"
    
    print_success "Application directory structure created at $APP_DIR"
}

# Function to install the all-in-one script
install_script() {
    print_step "Installing Mac Sync Wizard script..."
    
    # Check if the script exists in the current directory
    if [ -f "mac-sync-wizard-all-in-one.py" ]; then
        cp "mac-sync-wizard-all-in-one.py" "$APP_DIR/mac-sync-wizard.py"
    # Check if the script exists in the src directory
    elif [ -f "src/mac-sync-wizard-all-in-one.py" ]; then
        cp "src/mac-sync-wizard-all-in-one.py" "$APP_DIR/mac-sync-wizard.py"
    # Check if the script exists in the Downloads directory
    elif [ -f "$HOME/Downloads/mac-sync-wizard-all-in-one.py" ]; then
        cp "$HOME/Downloads/mac-sync-wizard-all-in-one.py" "$APP_DIR/mac-sync-wizard.py"
    else
        print_error "Could not find mac-sync-wizard-all-in-one.py in current directory, src directory, or Downloads folder"
        exit 1
    fi
    
    # Make the script executable
    chmod +x "$APP_DIR/mac-sync-wizard.py"
    
    print_success "Mac Sync Wizard script installed"
}

# Function to create the launcher script
create_launcher() {
    print_step "Creating launcher script..."
    
    # Create the launcher script
    cat > "$APP_DIR/launcher.sh" << EOF
#!/bin/bash
# Mac Sync Wizard Launcher
# This script runs the all-in-one Python script

# Run the application
python3 "$APP_DIR/mac-sync-wizard.py" "\$@"

# Exit with the same status as the application
exit \$?
EOF
    
    # Make it executable
    chmod +x "$APP_DIR/launcher.sh"
    
    print_success "Launcher script created"
}

# Function to create the executable symlink
create_executable_symlink() {
    print_step "Creating executable symlink..."
    
    # Create ~/.local/bin directory if it doesn't exist
    mkdir -p "$HOME/.local/bin"
    
    # Create symlink
    ln -sf "$APP_DIR/launcher.sh" "$HOME/.local/bin/mac-sync-wizard"
    
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
            
            # Add to current PATH for immediate use
            export PATH="$HOME/.local/bin:$PATH"
        else
            print_warning "Could not find shell configuration file"
            print_warning "Please add ~/.local/bin to your PATH manually"
        fi
    fi
    
    print_success "Executable symlink created at ~/.local/bin/mac-sync-wizard"
}

# Function to verify the installation
verify_installation() {
    print_step "Verifying installation..."
    
    # Check if the script exists
    if [ ! -f "$APP_DIR/mac-sync-wizard.py" ]; then
        print_error "Mac Sync Wizard script not found"
        return 1
    fi
    
    # Check if the launcher exists
    if [ ! -f "$APP_DIR/launcher.sh" ]; then
        print_error "Launcher script not found"
        return 1
    fi
    
    # Check if the symlink exists
    if [ ! -L "$HOME/.local/bin/mac-sync-wizard" ]; then
        print_error "Executable symlink not found"
        return 1
    fi
    
    # Try to run the script with --help
    if ! "$HOME/.local/bin/mac-sync-wizard" help > /dev/null 2>&1; then
        print_error "Failed to run Mac Sync Wizard"
        return 1
    fi
    
    print_success "Installation verified successfully"
    return 0
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
    
    # Install the script
    install_script
    
    # Create the launcher script
    create_launcher
    
    # Create the executable symlink
    create_executable_symlink
    
    # Verify the installation
    verify_installation
    if [ $? -ne 0 ]; then
        print_error "Installation verification failed"
        exit 1
    fi
    
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
