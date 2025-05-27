#!/usr/bin/env python3
"""
Mac Sync Wizard - All-in-One Version

This is a single-file version of Mac Sync Wizard that contains all functionality
without requiring any external module imports. This ensures the tool works reliably
on any Mac without import or module structure issues.
"""

import os
import sys
import json
import time
import shutil
import logging
import argparse
import subprocess
import datetime
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple, Union

# -----------------------------------------------------------------------------
# Constants and Global Variables
# -----------------------------------------------------------------------------

HOME_DIR = os.path.expanduser("~")
APP_DIR = os.path.join(HOME_DIR, ".mac-sync-wizard")
CONFIG_DIR = os.path.join(APP_DIR, "config")
LOGS_DIR = os.path.join(APP_DIR, "logs")
REPO_DIR = os.path.join(APP_DIR, "repo")
CONFIG_PATH = os.path.join(CONFIG_DIR, "sync_config.json")
LAST_SYNC_FILE = os.path.join(APP_DIR, "last_sync")
LOCK_FILE = os.path.join(APP_DIR, "sync.lock")

# Setup logging
os.makedirs(LOGS_DIR, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(os.path.join(LOGS_DIR, "mac-sync-wizard.log")),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('mac-sync-wizard')

# -----------------------------------------------------------------------------
# Terminal UI Utilities
# -----------------------------------------------------------------------------

class TerminalColors:
    """ANSI color codes for terminal output."""
    RESET = '\033[0m'
    BOLD = '\033[1m'
    RED = '\033[31m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
    MAGENTA = '\033[35m'
    CYAN = '\033[36m'
    WHITE = '\033[37m'
    BG_RED = '\033[41m'
    BG_GREEN = '\033[42m'
    BG_YELLOW = '\033[43m'
    BG_BLUE = '\033[44m'

def clear_screen():
    """Clear the terminal screen."""
    os.system('cls' if os.name == 'nt' else 'clear')

def print_header(title: str):
    """Print a styled header."""
    width = 80
    print()
    print(f"{TerminalColors.BLUE}┏{'━' * (width - 2)}┓{TerminalColors.RESET}")
    print(f"{TerminalColors.BLUE}┃{' ' * (width - 2)}┃{TerminalColors.RESET}")
    print(f"{TerminalColors.BLUE}┃  🔄 {TerminalColors.BOLD}{title}{TerminalColors.RESET}{TerminalColors.BLUE}{' ' * (width - len(title) - 6)}┃{TerminalColors.RESET}")
    print(f"{TerminalColors.BLUE}┃{' ' * (width - 2)}┃{TerminalColors.RESET}")
    print(f"{TerminalColors.BLUE}┗{'━' * (width - 2)}┛{TerminalColors.RESET}")
    print()

def print_success(message: str):
    """Print a success message."""
    print(f"\n{TerminalColors.GREEN}✅ {message}{TerminalColors.RESET}\n")

def print_error(message: str):
    """Print an error message."""
    print(f"\n{TerminalColors.RED}❌ {message}{TerminalColors.RESET}\n")

def print_warning(message: str):
    """Print a warning message."""
    print(f"\n{TerminalColors.YELLOW}⚠️  {message}{TerminalColors.RESET}\n")

def print_step(message: str):
    """Print a step message."""
    print(f"\n{TerminalColors.CYAN}➡️  {message}{TerminalColors.RESET}")

def print_menu(options: List[Tuple[str, str]], title: str = "Please select an option"):
    """Print a menu with options."""
    print(f"{TerminalColors.BLUE}┏{'━' * 78}┓{TerminalColors.RESET}")
    print(f"{TerminalColors.BLUE}┃ {title}{' ' * (77 - len(title))}┃{TerminalColors.RESET}")
    print(f"{TerminalColors.BLUE}┣{'━' * 78}┫{TerminalColors.RESET}")
    
    for key, description in options:
        print(f"{TerminalColors.BLUE}┃ {TerminalColors.CYAN}[{key}]{TerminalColors.RESET} {description}{' ' * (71 - len(description) - len(key))}┃{TerminalColors.RESET}")
    
    print(f"{TerminalColors.BLUE}┗{'━' * 78}┛{TerminalColors.RESET}")

def print_info(message: str):
    """Print an informational message."""
    print(f"\n{TerminalColors.BLUE}ℹ️  {message}{TerminalColors.RESET}\n")

def get_input(prompt: str, default: str = None) -> str:
    """Get user input with an optional default value."""
    if default:
        result = input(f"{prompt} [{default}]: ").strip()
        return result if result else default
    return input(f"{prompt}: ").strip()

def get_choice(prompt: str, options: List[str], default: str = None) -> str:
    """Get a choice from a list of options."""
    while True:
        if default:
            result = input(f"{prompt} [{'/'.join(options)}] (default: {default}): ").strip().lower()
            if not result:
                return default
        else:
            result = input(f"{prompt} [{'/'.join(options)}]: ").strip().lower()
        
        if result in options:
            return result
        print_error(f"Invalid choice. Please enter one of: {', '.join(options)}")

def get_yes_no(prompt: str, default: bool = True) -> bool:
    """Get a yes/no response from the user."""
    default_str = "Y/n" if default else "y/N"
    while True:
        result = input(f"{prompt} [{default_str}]: ").strip().lower()
        if not result:
            return default
        if result in ['y', 'yes']:
            return True
        if result in ['n', 'no']:
            return False
        print_error("Invalid choice. Please enter Y or N.")

def get_menu_choice(options: List[Tuple[str, str]], title: str = "Please select an option") -> str:
    """Display a menu and get user choice."""
    print_menu(options, title)
    
    valid_keys = [key for key, _ in options]
    while True:
        choice = input("Enter your choice: ").strip()
        if choice in valid_keys:
            return choice
        print_error(f"Invalid choice. Please enter one of: {', '.join(valid_keys)}")

# -----------------------------------------------------------------------------
# Configuration Manager
# -----------------------------------------------------------------------------

# Default utility configurations
UTILITY_CONFIGS = {
    # Syncable utilities (enabled by default)
    "cursor": {
        "enabled": True,
        "paths": [
            "~/Library/Application Support/Cursor/User/keybindings.json",
            "~/Library/Application Support/Cursor/User/settings.json",
            "~/Library/Application Support/Cursor/User/extensions/"
        ],
        "exclude_patterns": ["*.log", "Cache/*"]
    },
    "pycharm": {
        "enabled": True,
        "paths": [
            "~/Library/Application Support/JetBrains/PyCharm*/options/",
            "~/Library/Application Support/JetBrains/PyCharm*/keymaps/",
            "~/Library/Application Support/JetBrains/PyCharm*/codestyles/",
            "~/Library/Application Support/JetBrains/PyCharm*/templates/",
            "~/Library/Application Support/JetBrains/PyCharm*/colors/",
            "~/Library/Application Support/JetBrains/PyCharm*/fileTemplates/",
            "~/Library/Application Support/JetBrains/PyCharm*/inspection/",
            "~/Library/Application Support/JetBrains/PyCharm*/tools/",
            "~/Library/Application Support/JetBrains/PyCharm*/shelf/"
        ],
        "exclude_patterns": [
            "*.log", "Cache/*", "workspace/", "tasks/", "scratches/",
            "jdbc-drivers/", "ssl/", "port", "plugins/updatedPlugins.xml",
            "marketplace/", "*.hprof", "*.snapshot", "eval/", "repair/",
            "*/.DS_Store"
        ]
    },
    "sublime": {
        "enabled": True,
        "paths": [
            "~/Library/Application Support/Sublime Text/Packages/User/"
        ],
        "exclude_patterns": ["*.log", "Cache/*"]
    },
    "trackpad": {
        "enabled": True,
        "paths": [
            "~/Library/Preferences/com.apple.driver.AppleBluetoothMultitouch.trackpad.plist",
            "~/Library/Preferences/com.apple.AppleMultitouchTrackpad.plist"
        ],
        "exclude_patterns": []
    },
    "git": {
        "enabled": True,
        "paths": [
            "~/.gitconfig",
            "~/.config/git/"
        ],
        "exclude_patterns": []
    },
    "warp": {
        "enabled": True,
        "paths": [
            "~/.warp/themes/",
            "~/.warp/launch_configurations/",
            "~/.warp/user_scripts/",
            "~/.warp/settings.yaml",
            "~/.warp/keybindings.json"
        ],
        "exclude_patterns": [
            "Cache/*", "*.log", "*.pyc", "__pycache__",
            "*.sock", "*.pid"
        ]
    },
    "fonts": {
        "enabled": True,
        "paths": [
            "~/Library/Fonts/"
        ],
        "exclude_patterns": [],
        "include_patterns": [],  # If specified, only files matching these patterns will be synced
        "custom_fonts": []  # List of font family names to sync (e.g., ["Zed Plex Sans", "SF Mono"])
    },
    "anki": {
        "enabled": True,
        "paths": [
            "~/Library/Application Support/Anki2/addons21/",
            "~/Library/Application Support/Anki2/prefs21.db"
        ],
        "exclude_patterns": ["*.log"]
    },
    "stretchly": {
        "enabled": True,
        "paths": [
            "~/Library/Application Support/stretchly/"
        ],
        "exclude_patterns": ["*.log"]
    },
    "maccy": {
        "enabled": True,
        "paths": [
            "~/Library/Containers/org.p0deje.Maccy/Data/Library/Preferences/org.p0deje.Maccy.plist"
        ],
        "exclude_patterns": []
    },
    "shell": {
        "enabled": True,
        "paths": [
            "~/.iconfig/shell/"  # Custom directory for organized shell configs
        ],
        "exclude_patterns": [],
        "description": "Shell aliases, functions, and custom configurations",
        "setup_on_enable": True  # Special flag to run setup when enabled
    },
    
    # Installation-only utilities (disabled by default, not synced)
    "arc": {
        "enabled": False,  # Installation only
        "paths": [
            "~/Library/Application Support/Arc/",
            "~/Library/Preferences/company.thebrowser.Arc.plist"
        ],
        "exclude_patterns": ["Cache/*", "*.log"]
    },
    "logi": {
        "enabled": False,  # Installation only
        "paths": [
            "~/Library/Preferences/com.logi.optionsplus.plist",
            "~/Library/Application Support/LogiOptionsPlus/config.json",
            "~/Library/Application Support/LogiOptionsPlus/settings.db",
            "~/Library/Application Support/LogiOptionsPlus/macros.db",
            "~/Library/Application Support/LogiOptionsPlus/permissions.json",
            "~/Library/Application Support/LogiOptionsPlus/cc_config.json"
        ],
        "exclude_patterns": []
    },
    "1password": {
        "enabled": False,  # Installation only
        "paths": [
            "~/Library/Application Support/1Password/",
            "~/Library/Preferences/com.1password.1password.plist"
        ],
        "exclude_patterns": ["*.log", "Cache/*"]
    }
}

# Default configuration
DEFAULT_CONFIG = {
    "repository": {
        "url": "",
        "branch": "main",
        "auth_type": "ssh"
    },
    "sync": {
        "frequency": 21600,  # 6 hours in seconds
        "auto_commit": True,
        "commit_message_template": "Auto-sync: {date} - {changes}",
        "pull_strategy": "rebase"  # "rebase" or "merge"
    },
    "notifications": {
        "level": "errors_only",  # all, errors_only, none
        "method": "terminal-notifier"
    },
    "utilities": UTILITY_CONFIGS
}

def load_config() -> Dict[str, Any]:
    """Load configuration from file or create default if not exists."""
    try:
        if os.path.exists(CONFIG_PATH):
            with open(CONFIG_PATH, 'r') as f:
                config = json.load(f)
            
            # Merge with default config to ensure all fields exist
            merged_config = DEFAULT_CONFIG.copy()
            deep_update(merged_config, config)
            return merged_config
        else:
            # Create default configuration
            return create_default_config()
    except Exception as e:
        logger.error(f"Error loading config: {str(e)}")
        return DEFAULT_CONFIG.copy()

def deep_update(d: Dict[str, Any], u: Dict[str, Any]) -> None:
    """Recursively update a dictionary with another dictionary."""
    for k, v in u.items():
        if isinstance(v, dict) and k in d and isinstance(d[k], dict):
            deep_update(d[k], v)
        else:
            d[k] = v

def create_default_config() -> Dict[str, Any]:
    """Create default configuration with predefined utility settings."""
    config = DEFAULT_CONFIG.copy()
    
    # Create config directory if it doesn't exist
    os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
    
    # Save default config
    with open(CONFIG_PATH, 'w') as f:
        json.dump(config, f, indent=2)
    
    return config

def save_config(config: Dict[str, Any]) -> bool:
    """Save configuration to file."""
    try:
        os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
        with open(CONFIG_PATH, 'w') as f:
            json.dump(config, f, indent=2)
        logger.info("Configuration saved successfully")
        return True
    except Exception as e:
        logger.error(f"Failed to save config: {str(e)}")
        return False

def get_enabled_utilities(config: Dict[str, Any]) -> List[str]:
    """Get a list of enabled utilities."""
    return [
        utility for utility, util_config in config["utilities"].items()
        if util_config.get("enabled", False)
    ]

def detect_installed_utilities() -> List[str]:
    """Detect which predefined utilities are installed on the system."""
    installed = []
    
    for utility, config in UTILITY_CONFIGS.items():
        # Check if any of the paths exist
        for path_pattern in config["paths"]:
            expanded_path = os.path.expanduser(path_pattern)
            
            # Handle glob patterns
            if '*' in expanded_path:
                # Check if any matching files exist
                import glob
                matches = glob.glob(expanded_path)
                if matches:
                    installed.append(utility)
                    break
            else:
                # Check if the exact path exists
                if os.path.exists(expanded_path):
                    installed.append(utility)
                    break
    
    return installed

# -----------------------------------------------------------------------------
# Git Sync Manager
# -----------------------------------------------------------------------------

def run_command(command: List[str], cwd: str = None, check: bool = True) -> Tuple[int, str, str]:
    """Run a shell command and return exit code, stdout, and stderr."""
    try:
        process = subprocess.Popen(
            command,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=os.environ # Ensure git commands have access to user's environment (e.g. for SSH keys)
        )
        stdout, stderr = process.communicate()
        exit_code = process.returncode
        
        if check and exit_code != 0:
            logger.error(f"Command failed: {' '.join(command)}")
            logger.error(f"Exit code: {exit_code}")
            logger.error(f"Stdout: {stdout}")
            logger.error(f"Stderr: {stderr}")
        
        return exit_code, stdout, stderr
    except Exception as e:
        logger.error(f"Exception running command {' '.join(command)}: {str(e)}")
        return 1, "", str(e)

def command_exists(command: str) -> bool:
    """Check if a command exists."""
    exit_code, _, _ = run_command(["which", command], check=False)
    return exit_code == 0

def get_directory_size(path: str) -> Tuple[int, str]:
    """Get the size of a directory in bytes and human-readable format."""
    try:
        if os.path.isfile(path):
            size = os.path.getsize(path)
        else:
            # Use du command for accurate size calculation
            exit_code, stdout, _ = run_command(["du", "-sk", path], check=False)
            if exit_code == 0:
                # du -sk returns size in KB
                size = int(stdout.split()[0]) * 1024
            else:
                # Fallback to Python calculation
                size = 0
                for dirpath, dirnames, filenames in os.walk(path):
                    for filename in filenames:
                        filepath = os.path.join(dirpath, filename)
                        try:
                            size += os.path.getsize(filepath)
                        except:
                            pass
        
        # Convert to human-readable format
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size < 1024.0:
                return size, f"{size:.1f} {unit}"
            size /= 1024.0
        return size * 1024 * 1024 * 1024 * 1024, f"{size:.1f} PB"
    except Exception as e:
        logger.error(f"Failed to get size for {path}: {str(e)}")
        return 0, "0 B"

def check_disk_space(path: str, required_mb: int = 100) -> Tuple[bool, str]:
    """Check if there's enough disk space at the given path."""
    try:
        import shutil
        stat = shutil.disk_usage(path)
        available_mb = stat.free / (1024 * 1024)
        if available_mb < required_mb:
            return False, f"Insufficient disk space: {available_mb:.1f}MB available, {required_mb}MB required"
        return True, f"Sufficient disk space: {available_mb:.1f}MB available"
    except Exception as e:
        return False, f"Failed to check disk space: {str(e)}"

def check_network_connectivity() -> Tuple[bool, str]:
    """Check basic network connectivity."""
    try:
        # Try to resolve a common DNS name
        import socket
        socket.gethostbyname("github.com")
        return True, "Network connectivity verified"
    except socket.error:
        return False, "No network connectivity detected"

def check_git_credentials(repo_url: str) -> Tuple[bool, str]:
    """Check if Git credentials are properly configured for the repository."""
    if not repo_url:
        return True, "No repository configured"
    
    # For SSH URLs, check if SSH key is available
    if repo_url.startswith("git@"):
        ssh_key_path = os.path.expanduser("~/.ssh/id_rsa")
        ssh_key_ed25519 = os.path.expanduser("~/.ssh/id_ed25519")
        if not (os.path.exists(ssh_key_path) or os.path.exists(ssh_key_ed25519)):
            return False, "No SSH key found. Please set up SSH keys for Git authentication"
    
    return True, "Git credentials check passed"

def check_git_lfs() -> Tuple[bool, str]:
    """Check if Git LFS is installed."""
    if command_exists("git-lfs"):
        return True, "Git LFS is installed"
    else:
        return False, "Git LFS not installed (needed for large files)"

def perform_preflight_checks(config: Dict[str, Any]) -> bool:
    """Perform pre-flight checks before sync operations."""
    print_step("Performing pre-flight checks...")
    
    checks = [
        ("Git installation", lambda: (command_exists("git"), "Git is installed" if command_exists("git") else "Git is not installed")),
        ("Disk space", lambda: check_disk_space(APP_DIR)),
        ("Network connectivity", lambda: check_network_connectivity()),
        ("Git credentials", lambda: check_git_credentials(config.get("repository", {}).get("url", ""))),
        ("Git LFS", lambda: check_git_lfs())
    ]
    
    all_passed = True
    for check_name, check_func in checks:
        passed, message = check_func()
        if passed:
            print(f"  ✓ {check_name}: {message}")
        else:
            print_error(f"  ✗ {check_name}: {message}")
            all_passed = False
    
    return all_passed

def init_repository(url: str, branch: str = "main") -> bool:
    """Initialize a new repository or connect to existing one."""
    logger.info(f"Initializing repository: {url} ({branch})")

    # Validate URL (basic check)
    if not url.startswith(("http://", "https://", "git@")):
        logger.error(f"Invalid repository URL format: {url}")
        print_error(f"Invalid repository URL format. Please use http(s):// or git@ format.")
        return False

    git_dir = os.path.join(REPO_DIR, ".git")

    if os.path.exists(git_dir):
        # REPO_DIR exists and is a Git repository
        logger.info(f"Found existing Git repository in {REPO_DIR}")
        return connect_existing_repo_flow(url, branch)
    elif os.path.exists(REPO_DIR) and os.listdir(REPO_DIR):
        # REPO_DIR exists but is not a Git repository or is an empty .git folder
        logger.warning(f"{REPO_DIR} exists and is not empty or not a valid Git repository.")
        if get_yes_no(f"Directory {REPO_DIR} exists and is not a recognized Git repository or is not empty. Do you want to try to use it or re-initialize? (y=use, n=re-initialize)", default=False):
            # Try to initialize in existing non-empty directory, could fail if .git is corrupted / partial
            return create_new_repo_flow(url, branch, force_init_in_existing=True)
        else:
            if get_yes_no(f"Do you want to delete {REPO_DIR} and start fresh? (This is irreversible)", default=False):
                try:
                    shutil.rmtree(REPO_DIR)
                    logger.info(f"Removed existing directory: {REPO_DIR}")
                    os.makedirs(REPO_DIR, exist_ok=True) # Recreate after deletion
                    return create_new_repo_flow(url, branch)
                except Exception as e:
                    logger.error(f"Failed to remove directory {REPO_DIR}: {str(e)}")
                    print_error(f"Could not remove {REPO_DIR}. Please check permissions or remove it manually.")
                    return False
            else:
                print_warning("Repository setup aborted by user.")
                return False
    else:
        # REPO_DIR does not exist or is empty
        os.makedirs(REPO_DIR, exist_ok=True) # Ensure REPO_DIR exists
        return create_new_repo_flow(url, branch)

def create_new_repo_flow(url: str, branch: str, force_init_in_existing: bool = False) -> bool:
    """Handles the flow for creating a new repository."""
    if not force_init_in_existing:
        logger.info(f"Creating new repository in {REPO_DIR}")
    else:
        logger.info(f"Attempting to initialize Git repository in existing directory {REPO_DIR}")

    if create_new_repo(url, branch):
        print_success(f"Successfully initialized new repository and connected to {url} on branch {branch}.")
        return True
    else:
        print_error(f"Failed to create and initialize new repository at {url}.")
        # Clean up REPO_DIR if we created it and initialization failed, to allow retry
        # But only if it was truly empty before we started, to avoid deleting user data if force_init_in_existing
        if not force_init_in_existing and os.path.exists(REPO_DIR) and not os.listdir(REPO_DIR):
             try:
                shutil.rmtree(REPO_DIR)
                logger.info(f"Cleaned up {REPO_DIR} after failed initialization.")
             except Exception as e:
                logger.warning(f"Failed to clean up {REPO_DIR} after failed init: {e}")
        return False

def connect_existing_repo_flow(url: str, branch: str) -> bool:
    """Handles the flow for connecting to an existing repository."""
    logger.info(f"Attempting to connect to existing repository settings in {REPO_DIR}")
    # Verify remote URL if possible
    exit_code, remote_url, _ = run_command(["git", "config", "--get", "remote.origin.url"], cwd=REPO_DIR, check=False)
    if exit_code == 0 and remote_url.strip() != url:
        logger.warning(f"Existing repo remote URL '{remote_url.strip()}' differs from desired '{url}'.")
        if not get_yes_no(f"The existing repository is configured for {remote_url.strip()}. Do you want to update it to {url}?", default=True):
            print_warning("Repository connection aborted by user.")
            return False
    
    if connect_existing_repo(url, branch):
        print_success(f"Successfully connected to existing repository {url} on branch {branch}.")
        return True
    else:
        print_error(f"Failed to connect to existing repository {url}.")
        return False

def setup_git_lfs_for_fonts() -> bool:
    """Setup Git LFS for font files."""
    try:
        # Check if Git LFS is available
        if not command_exists("git-lfs"):
            print_warning("Git LFS is not installed. Large font files may cause issues.")
            print_info("Install with: brew install git-lfs")
            return False
        
        # Initialize Git LFS in the repository
        exit_code, _, stderr = run_command(["git", "lfs", "install"], cwd=REPO_DIR, check=False)
        if exit_code != 0:
            logger.error(f"Failed to initialize Git LFS: {stderr}")
            return False
        
        # Track font files with Git LFS
        font_patterns = ["*.ttf", "*.otf", "*.ttc", "*.woff", "*.woff2"]
        for pattern in font_patterns:
            exit_code, _, _ = run_command(["git", "lfs", "track", f"backups/fonts/{pattern}"], cwd=REPO_DIR, check=False)
        
        # Add .gitattributes to track LFS files
        exit_code, _, _ = run_command(["git", "add", ".gitattributes"], cwd=REPO_DIR, check=False)
        
        logger.info("Git LFS configured for font files")
        return True
    except Exception as e:
        logger.error(f"Failed to setup Git LFS: {str(e)}")
        return False

def create_new_repo(url: str, branch: str) -> bool:
    """Create a new repository and set remote."""
    try:
        # Create repository directory
        os.makedirs(REPO_DIR, exist_ok=True)
        
        # Initialize Git repository
        exit_code, stdout, stderr = run_command(["git", "init"], cwd=REPO_DIR, check=False)
        if exit_code != 0:
            logger.error(f"git init failed: {stderr}")
            # Check if it's because it's already a git repo, which can happen with force_init_in_existing
            if "already a git repository" not in stderr.lower() and "reinitialized existing git repository" not in stderr.lower():
                 print_error(f"Failed to initialize Git repository: {stderr}")
                 return False
            logger.info("Git repository already exists or was reinitialized.")
        
        # Setup Git LFS for fonts
        setup_git_lfs_for_fonts()

        # Set remote
        # Try removing remote origin first, in case it exists and is wrong (e.g. re-initializing)
        run_command(["git", "remote", "remove", "origin"], cwd=REPO_DIR, check=False) 
        exit_code, _, stderr = run_command(["git", "remote", "add", "origin", url], cwd=REPO_DIR, check=False)
        if exit_code != 0:
            logger.error(f"git remote add origin failed: {stderr}")
            print_error(f"Failed to set remote origin: {stderr}")
            return False
        
        # Fetch from remote to get all branches
        print_step("Fetching from remote repository...")
        exit_code, _, stderr = run_command(["git", "fetch", "origin"], cwd=REPO_DIR, check=False)
        if exit_code != 0:
            logger.warning(f"git fetch failed: {stderr}. This might be a new empty repository.")
            # Don't fail here - might be a new empty repo
        
        # Create initial structure
        for dir_name in ["backups", "config", "logs"]:
            os.makedirs(os.path.join(REPO_DIR, dir_name), exist_ok=True)
        
        # Create README
        with open(os.path.join(REPO_DIR, "README.md"), "w") as f:
            f.write(f"# Mac Sync Wizard Repository\n\nThis repository contains synchronized Mac utility settings.\n")
        
        # Add files
        exit_code, _, _ = run_command(["git", "add", "."], cwd=REPO_DIR)
        if exit_code != 0:
            return False
        
        # Initial commit
        exit_code, _, stderr = run_command(["git", "commit", "-m", "Initial commit"], cwd=REPO_DIR, check=False)
        if exit_code != 0:
            # It's okay if initial commit fails due to nothing to commit (e.g., if .gitignore exists and ignores everything)
            # Or if we are re-initializing an existing repo that already has commits.
            # We check for actual errors.
            if "nothing to commit" not in stderr.lower() and "initial commit" not in stderr.lower() and "no changes added to commit" not in stderr.lower():
                logger.error(f"Initial git commit failed: {stderr}")
                # print_error(f"Failed to make initial commit: {stderr}") # This might be too noisy if it's not a real problem
                # return False # Decided not to fail hard here, as repo might be usable
        
        # Check if branch exists on remote after fetch
        exit_code, remote_branches, _ = run_command(["git", "branch", "-r"], cwd=REPO_DIR, check=False)
        remote_branch_exists = f"origin/{branch}" in remote_branches if exit_code == 0 else False
        
        # Check if branch already exists locally
        exit_code_local_branch, local_branch_stdout, _ = run_command(["git", "branch", "--list", branch], cwd=REPO_DIR, check=False)

        current_branch_code, current_branch_name, _ = run_command(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=REPO_DIR, check=False)
        current_branch_name = current_branch_name.strip() if current_branch_code == 0 else ""

        if current_branch_name == branch:
            logger.info(f"Already on branch '{branch}'.")
            # Try to set upstream if remote branch exists
            if remote_branch_exists:
                run_command(["git", "branch", f"--set-upstream-to=origin/{branch}", branch], cwd=REPO_DIR, check=False)
        elif branch in local_branch_stdout:
            logger.info(f"Switching to existing local branch '{branch}'.")
            exit_code, _, stderr = run_command(["git", "checkout", branch], cwd=REPO_DIR, check=False)
            if exit_code != 0:
                logger.error(f"git checkout {branch} failed: {stderr}")
                print_error(f"Failed to checkout local branch {branch}: {stderr}")
                return False
            # Set upstream if remote branch exists
            if remote_branch_exists:
                run_command(["git", "branch", f"--set-upstream-to=origin/{branch}", branch], cwd=REPO_DIR, check=False)
        elif remote_branch_exists:
            logger.info(f"Remote branch 'origin/{branch}' exists. Checking it out...")
            # Create local branch from remote
            exit_code, _, stderr = run_command(["git", "checkout", "-b", branch, f"origin/{branch}"], cwd=REPO_DIR, check=False)
            if exit_code != 0:
                # Maybe branch already exists locally, try just checking it out
                exit_code, _, stderr = run_command(["git", "checkout", branch], cwd=REPO_DIR, check=False)
                if exit_code != 0:
                    logger.error(f"Failed to checkout branch {branch}: {stderr}")
                    print_error(f"Failed to checkout branch {branch}: {stderr}")
                    return False
                # Set upstream
                run_command(["git", "branch", f"--set-upstream-to=origin/{branch}", branch], cwd=REPO_DIR, check=False)
        else:
            logger.info(f"Creating new branch '{branch}'.")
            exit_code, _, stderr = run_command(["git", "checkout", "-b", branch], cwd=REPO_DIR, check=False)
            if exit_code != 0:
                logger.error(f"git checkout -b {branch} failed: {stderr}")
                print_error(f"Failed to create branch {branch}: {stderr}")
                return False
        
        # Try to push to set upstream, this also verifies credentials early
        # It's okay if this fails (e.g. new empty repo on GitHub, or branch already exists and is protected)
        # We are mainly interested in setting upstream for future pulls/pushes.
        run_command(["git", "push", "--set-upstream", "origin", branch], cwd=REPO_DIR, check=False)

        logger.info(f"Repository setup/verified: {url} (branch: {branch})")
        return True
        
    except Exception as e:
        logger.error(f"Unexpected error creating repository: {str(e)}")
        return False

def connect_existing_repo(url: str, branch: str) -> bool:
    """Connect to existing repository."""
    try:
        # Update remote URL
        exit_code, _, stderr = run_command(["git", "remote", "set-url", "origin", url], cwd=REPO_DIR, check=False)
        if exit_code != 0:
            logger.error(f"git remote set-url failed: {stderr}")
            print_error(f"Failed to set remote URL: {stderr}")
            return False
        
        # Fetch
        exit_code, _, stderr = run_command(["git", "fetch", "--all"], cwd=REPO_DIR, check=False)
        if exit_code != 0:
            logger.error(f"git fetch failed: {stderr}")
            print_error(f"Failed to fetch from remote: {stderr}. Check connection and repository URL.")
            return False
        
        # Check if branch exists on remote
        exit_code, stdout, _ = run_command(["git", "branch", "-r"], cwd=REPO_DIR, check=False) # list remote branches
        if exit_code != 0:
            logger.error("Failed to list remote branches.")
            # Don't fail here, maybe proceed and try to checkout/create locally

        remote_branch_exists = f"origin/{branch}" in stdout

        # Check if branch exists locally
        exit_code_local, local_stdout, _ = run_command(["git", "branch", "--list", branch], cwd=REPO_DIR, check=False)
        local_branch_exists = branch in local_stdout

        current_branch_code, current_branch_name, _ = run_command(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=REPO_DIR, check=False)
        current_branch_name = current_branch_name.strip() if current_branch_code == 0 else ""

        if current_branch_name == branch:
            logger.info(f"Already on branch '{branch}'. Attempting to set upstream if not set.")
            run_command(["git", "branch", f"--set-upstream-to=origin/{branch}", branch], cwd=REPO_DIR, check=False)
        elif local_branch_exists:
            logger.info(f"Checking out existing local branch '{branch}'.")
            exit_code, _, stderr = run_command(["git", "checkout", branch], cwd=REPO_DIR, check=False)
            if exit_code != 0:
                logger.error(f"git checkout {branch} failed: {stderr}")
                print_error(f"Failed to checkout local branch {branch}: {stderr}")
                return False
            # Ensure it tracks the remote if the remote branch exists
            if remote_branch_exists:
                 run_command(["git", "branch", f"--set-upstream-to=origin/{branch}", branch], cwd=REPO_DIR, check=False)
        elif remote_branch_exists:
            logger.info(f"Checking out remote branch '{branch}' and setting up tracking.")
            exit_code, _, stderr = run_command(["git", "checkout", "-t", f"origin/{branch}"], cwd=REPO_DIR, check=False)
            if exit_code != 0:
                logger.error(f"git checkout -t origin/{branch} failed: {stderr}")
                print_error(f"Failed to checkout remote branch {branch}: {stderr}")
                return False
        else:
            logger.warning(f"Branch '{branch}' not found locally or on remote 'origin'. Creating new local branch '{branch}'.")
            logger.warning("You may need to push it to the remote manually if it's intended to be a shared branch.")
            exit_code, _, stderr = run_command(["git", "checkout", "-b", branch], cwd=REPO_DIR, check=False)
            if exit_code != 0:
                logger.error(f"git checkout -b {branch} failed: {stderr}")
                print_error(f"Failed to create new local branch {branch}: {stderr}")
                return False
        
        logger.info(f"Connected to repository: {url} (branch: {branch})")
        return True
        
    except Exception as e:
        logger.error(f"Unexpected error connecting to repository: {str(e)}")
        return False

def get_font_files_for_family(font_family_name: str) -> List[str]:
    """Get all font files for a given font family name (as shown in Font Book)."""
    fonts_dir = os.path.expanduser("~/Library/Fonts/")
    matching_files = []
    
    # Common patterns for font family names to file names
    # e.g., "Zed Plex Sans" might be "ZedPlexSans-Regular.ttf", "Zed Plex Sans.ttf", etc.
    search_patterns = [
        # Exact match with spaces
        f"{font_family_name}*.ttf",
        f"{font_family_name}*.otf",
        f"{font_family_name}*.ttc",
        # Without spaces
        f"{font_family_name.replace(' ', '')}*.ttf",
        f"{font_family_name.replace(' ', '')}*.otf",
        f"{font_family_name.replace(' ', '')}*.ttc",
        # With dashes instead of spaces
        f"{font_family_name.replace(' ', '-')}*.ttf",
        f"{font_family_name.replace(' ', '-')}*.otf",
        f"{font_family_name.replace(' ', '-')}*.ttc",
        # With underscores instead of spaces
        f"{font_family_name.replace(' ', '_')}*.ttf",
        f"{font_family_name.replace(' ', '_')}*.otf",
        f"{font_family_name.replace(' ', '_')}*.ttc",
    ]
    
    import glob
    found_files = set()  # Use set to avoid duplicates
    
    for pattern in search_patterns:
        pattern_path = os.path.join(fonts_dir, pattern)
        matches = glob.glob(pattern_path, recursive=False)
        for match in matches:
            found_files.add(os.path.basename(match))
    
    # Also check case-insensitive matches
    all_font_files = []
    try:
        all_font_files = [f for f in os.listdir(fonts_dir) if os.path.isfile(os.path.join(fonts_dir, f))]
    except:
        pass
    
    # Check for files that contain the font family name (case-insensitive)
    family_lower = font_family_name.lower()
    family_no_space = font_family_name.replace(' ', '').lower()
    
    for font_file in all_font_files:
        font_file_lower = font_file.lower()
        # Check if the family name (with or without spaces) is in the filename
        if (family_lower in font_file_lower or 
            family_no_space in font_file_lower or
            family_lower.replace(' ', '-') in font_file_lower or
            family_lower.replace(' ', '_') in font_file_lower):
            found_files.add(font_file)
    
    return sorted(list(found_files))

def backup_fonts(custom_fonts: list, include_patterns: list = None, exclude_patterns: list = None, dry_run: bool = False) -> bool:
    """Backup fonts with custom selection support using font family names."""
    logger.info(f"Backing up fonts{' (DRY RUN)' if dry_run else ''}")
    
    fonts_dir = os.path.expanduser("~/Library/Fonts/")
    backup_path = os.path.join(REPO_DIR, "backups", "fonts")
    
    if not dry_run:
        os.makedirs(backup_path, exist_ok=True)
    
    success = True
    files_copied = 0
    
    if not os.path.exists(fonts_dir):
        logger.warning(f"Fonts directory does not exist: {fonts_dir}")
        return False
    
    try:
        if custom_fonts:
            # Custom fonts now contains font family names, not file names
            logger.info(f"Backing up {len(custom_fonts)} font families")
            for font_family in custom_fonts:
                # Get all files for this font family
                font_files = get_font_files_for_family(font_family)
                
                if not font_files:
                    logger.warning(f"No files found for font family: {font_family}")
                    print_warning(f"No files found for font family: {font_family}")
                    continue
                
                logger.info(f"Found {len(font_files)} files for font family '{font_family}'")
                
                for font_file in font_files:
                    font_path = os.path.join(fonts_dir, font_file)
                    if os.path.exists(font_path):
                        if dry_run:
                            logger.info(f"[DRY RUN] Would copy {font_file} (from {font_family})")
                            files_copied += 1
                        else:
                            dest_path = os.path.join(backup_path, font_file)
                            shutil.copy2(font_path, dest_path)
                            files_copied += 1
                            logger.debug(f"Copied {font_file}")
                    else:
                        logger.warning(f"Font file not found: {font_file}")
                        
        elif include_patterns:
            # Use include patterns to select fonts
            import glob
            logger.info(f"Using include patterns: {include_patterns}")
            for pattern in include_patterns:
                pattern_path = os.path.join(fonts_dir, pattern)
                matching_files = glob.glob(pattern_path)
                for font_path in matching_files:
                    font_name = os.path.basename(font_path)
                    if dry_run:
                        logger.info(f"[DRY RUN] Would copy font {font_name}")
                        files_copied += 1
                    else:
                        dest_path = os.path.join(backup_path, font_name)
                        shutil.copy2(font_path, dest_path)
                        files_copied += 1
                        logger.debug(f"Copied font {font_name}")
        else:
            # Backup all fonts (excluding patterns if specified)
            logger.warning("No custom fonts or include patterns specified - backing up ALL fonts")
            logger.warning("This may result in large backup sizes. Consider specifying custom_fonts or include_patterns.")
            
            for font_name in os.listdir(fonts_dir):
                font_path = os.path.join(fonts_dir, font_name)
                
                # Skip if matches exclude pattern
                if exclude_patterns:
                    skip = False
                    for pattern in exclude_patterns:
                        import fnmatch
                        if fnmatch.fnmatch(font_name, pattern):
                            skip = True
                            break
                    if skip:
                        continue
                
                if os.path.isfile(font_path):
                    if dry_run:
                        logger.info(f"[DRY RUN] Would copy font {font_name}")
                        files_copied += 1
                    else:
                        dest_path = os.path.join(backup_path, font_name)
                        shutil.copy2(font_path, dest_path)
                        files_copied += 1
    
    except Exception as e:
        logger.error(f"Failed to backup fonts: {str(e)}")
        success = False
    
    if files_copied == 0:
        logger.warning("No fonts were copied")
    else:
        logger.info(f"{'Would backup' if dry_run else 'Backed up'} {files_copied} font files")
    
    return success

def backup_utility(utility_name: str, source_paths: list, exclude_patterns: list = None, dry_run: bool = False) -> bool:
    """Backup a specific utility's configuration."""
    logger.info(f"Backing up {utility_name}{' (DRY RUN)' if dry_run else ''}")
    
    backup_path = os.path.join(REPO_DIR, "backups", utility_name)
    
    if not dry_run:
        os.makedirs(backup_path, exist_ok=True)
    
    success = True
    files_copied = 0
    
    # Copy files to backup directory
    for path in source_paths:
        expanded_path = os.path.expanduser(path)
        
        if not os.path.exists(expanded_path):
            logger.warning(f"Path does not exist: {expanded_path}")
            continue
        
        try:
            if os.path.isdir(expanded_path):
                # Copy directory contents
                dest_dir = os.path.join(backup_path, os.path.basename(expanded_path))
                
                if dry_run:
                    logger.info(f"[DRY RUN] Would copy directory {expanded_path} to {dest_dir}")
                    files_copied += 1
                else:
                    if os.path.exists(dest_dir):
                        shutil.rmtree(dest_dir)
                    
                    # Use rsync if available for better exclude pattern support
                    if command_exists("rsync") and exclude_patterns:
                        exclude_args = []
                        for pattern in exclude_patterns:
                            exclude_args.extend(["--exclude", pattern])
                        
                        exit_code, _, _ = run_command(
                            ["rsync", "-a", "--delete"] + exclude_args + [expanded_path + "/", dest_dir]
                        )
                        if exit_code != 0:
                            success = False
                    else:
                        # Fallback to shutil
                        shutil.copytree(expanded_path, dest_dir)
            else:
                # Copy file
                if dry_run:
                    logger.info(f"[DRY RUN] Would copy file {expanded_path} to {backup_path}")
                    files_copied += 1
                else:
                    shutil.copy2(expanded_path, backup_path)
            
            if not dry_run:
                files_copied += 1
                logger.debug(f"Copied {expanded_path} to backup")
            
        except Exception as e:
            logger.error(f"Failed to backup {expanded_path}: {str(e)}")
            success = False
    
    if files_copied == 0:
        logger.warning(f"No files were copied for {utility_name}")
    else:
        logger.info(f"{'Would backup' if dry_run else 'Backed up'} {files_copied} files for {utility_name}")
    
    return success

def create_backup_before_restore(utility_name: str, dest_paths: list) -> Optional[str]:
    """Create a backup of existing files before restoring."""
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dir = os.path.join(APP_DIR, "restore_backups", f"{utility_name}_{timestamp}")
    
    try:
        os.makedirs(backup_dir, exist_ok=True)
        
        for path in dest_paths:
            expanded_path = os.path.expanduser(path)
            if os.path.exists(expanded_path):
                # Create relative path structure in backup
                rel_path = os.path.relpath(expanded_path, HOME_DIR)
                backup_path = os.path.join(backup_dir, rel_path)
                os.makedirs(os.path.dirname(backup_path), exist_ok=True)
                
                if os.path.isdir(expanded_path):
                    shutil.copytree(expanded_path, backup_path)
                else:
                    shutil.copy2(expanded_path, backup_path)
        
        logger.info(f"Created backup for {utility_name} at {backup_dir}")
        return backup_dir
    except Exception as e:
        logger.error(f"Failed to create backup for {utility_name}: {str(e)}")
        return None

def restore_utility(utility_name: str, dest_paths: list) -> bool:
    """Restore a specific utility's configuration."""
    logger.info(f"Restoring {utility_name}")
    
    backup_path = os.path.join(REPO_DIR, "backups", utility_name)
    if not os.path.exists(backup_path):
        logger.warning(f"No backup found for {utility_name}")
        return False
    
    # Create a backup before restoring
    backup_dir = create_backup_before_restore(utility_name, dest_paths)
    if backup_dir:
        print_info(f"Created safety backup at: {backup_dir}")
    
    success = True
    files_restored = 0
    
    # For each path in the utility config, restore from backup
    for path in dest_paths:
        expanded_path = os.path.expanduser(path)
        
        # Get the base directory
        base_dir = os.path.dirname(expanded_path)
        
        # Create parent directory if it doesn't exist
        os.makedirs(base_dir, exist_ok=True)
        
        try:
            if os.path.isdir(backup_path):
                # Copy directory contents
                for item in os.listdir(backup_path):
                    item_path = os.path.join(backup_path, item)
                    dest_item_path = os.path.join(base_dir, item)
                    
                    if os.path.isdir(item_path):
                        if os.path.exists(dest_item_path):
                            shutil.rmtree(dest_item_path)
                        shutil.copytree(item_path, dest_item_path)
                    else:
                        shutil.copy2(item_path, base_dir)
                    
                    files_restored += 1
            else:
                # Copy file
                shutil.copy2(backup_path, expanded_path)
                files_restored += 1
            
            logger.debug(f"Restored to {expanded_path}")
            
        except Exception as e:
            logger.error(f"Failed to restore to {expanded_path}: {str(e)}")
            success = False
    
    if files_restored == 0:
        logger.warning(f"No files were restored for {utility_name}")
    else:
        logger.info(f"Restored {files_restored} files for {utility_name}")
    
    return success

def commit_changes(message: Optional[str] = None) -> bool:
    """Commit changes to the repository."""
    if not message:
        message = f"Auto-sync: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    
    logger.info(f"Committing changes: {message}")
    
    try:
        # Add all changes
        exit_code, _, _ = run_command(["git", "add", "."], cwd=REPO_DIR)
        if exit_code != 0:
            return False
        
        # Check if there are changes to commit
        exit_code, stdout, _ = run_command(["git", "status", "--porcelain"], cwd=REPO_DIR)
        if exit_code != 0:
            return False
        
        if not stdout.strip():
            logger.info("No changes to commit")
            return True
        
        # Commit changes
        exit_code, _, _ = run_command(["git", "commit", "-m", message], cwd=REPO_DIR)
        if exit_code != 0:
            return False
        
        logger.info("Changes committed successfully")
        return True
        
    except Exception as e:
        logger.error(f"Unexpected error committing changes: {str(e)}")
        return False

def push_changes(branch: Optional[str] = None) -> bool:
    """Push changes to remote repository."""
    if not branch:
        # Get current branch
        try:
            exit_code, stdout, _ = run_command(
                ["git", "rev-parse", "--abbrev-ref", "HEAD"],
                cwd=REPO_DIR
            )
            if exit_code != 0:
                branch = "main"
            else:
                branch = stdout.strip()
        except:
            branch = "main"
    
    logger.info(f"Pushing changes to branch: {branch}")
    
    try:
        # Push changes
        exit_code, _, _ = run_command(["git", "push", "origin", branch], cwd=REPO_DIR)
        if exit_code != 0:
            return False
        
        logger.info("Changes pushed successfully")
        return True
        
    except Exception as e:
        logger.error(f"Unexpected error pushing changes: {str(e)}")
        return False

def pull_changes(branch: Optional[str] = None, use_rebase: Optional[bool] = None) -> bool:
    """Pull changes from remote repository using rebase to maintain clean history."""
    if not branch:
        # Get current branch
        try:
            exit_code, stdout, _ = run_command(
                ["git", "rev-parse", "--abbrev-ref", "HEAD"],
                cwd=REPO_DIR
            )
            if exit_code != 0:
                branch = "main"
            else:
                branch = stdout.strip()
        except:
            branch = "main"
    
    # Determine pull strategy if not specified
    if use_rebase is None:
        config = load_config()
        pull_strategy = config.get("sync", {}).get("pull_strategy", "rebase")
        use_rebase = pull_strategy == "rebase"
    
    logger.info(f"Pulling changes from branch: {branch} (strategy: {'rebase' if use_rebase else 'merge'})")
    
    try:
        # First, check if there are uncommitted changes
        exit_code, stdout, _ = run_command(["git", "status", "--porcelain"], cwd=REPO_DIR, check=False)
        if exit_code == 0 and stdout.strip():
            logger.warning("Uncommitted changes detected. Stashing them before pull.")
            print_warning("Uncommitted changes detected. Stashing them temporarily...")
            
            # Stash changes
            exit_code, _, stderr = run_command(["git", "stash", "push", "-m", "Auto-stash before pull"], cwd=REPO_DIR, check=False)
            if exit_code != 0:
                logger.error(f"Failed to stash changes: {stderr}")
                print_error("Failed to stash uncommitted changes. Please commit or stash them manually.")
                return False
            
            stashed = True
        else:
            stashed = False
        
        # Fetch latest changes
        exit_code, _, stderr = run_command(["git", "fetch", "origin"], cwd=REPO_DIR, check=False)
        if exit_code != 0:
            logger.error(f"Failed to fetch from origin: {stderr}")
            print_error(f"Failed to fetch from remote: {stderr}")
            return False
        
        # Pull with configured strategy
        pull_args = ["git", "pull"]
        if use_rebase:
            pull_args.append("--rebase")
        pull_args.extend(["origin", branch])
        
        exit_code, stdout, stderr = run_command(pull_args, cwd=REPO_DIR, check=False)
        
        if exit_code != 0:
            if "CONFLICT" in stderr or "conflict" in stderr.lower():
                logger.error("Merge conflicts detected during rebase")
                print_error("Conflicts detected during pull. Attempting to abort rebase...")
                
                # Abort the rebase
                run_command(["git", "rebase", "--abort"], cwd=REPO_DIR, check=False)
                
                # Try a regular pull instead
                print_warning("Falling back to regular merge strategy...")
                exit_code, _, stderr = run_command(["git", "pull", "origin", branch], cwd=REPO_DIR, check=False)
                
                if exit_code != 0:
                    logger.error(f"Failed to pull changes even with merge strategy: {stderr}")
                    print_error("Failed to pull changes. Your repository may have conflicts that need manual resolution.")
                    print_info("You can try resolving this manually with: cd ~/.mac-sync-wizard/repo && git pull")
                    return False
            else:
                logger.error(f"Failed to pull changes: {stderr}")
                print_error(f"Failed to pull changes: {stderr}")
                return False
        
        # If we stashed changes, pop them back
        if stashed:
            print_info("Restoring stashed changes...")
            exit_code, _, stderr = run_command(["git", "stash", "pop"], cwd=REPO_DIR, check=False)
            if exit_code != 0:
                logger.warning(f"Failed to pop stashed changes: {stderr}")
                print_warning("Failed to restore stashed changes automatically.")
                print_info("Your changes are still saved. You can restore them manually with: cd ~/.mac-sync-wizard/repo && git stash pop")
        
        logger.info("Changes pulled successfully")
        return True
        
    except Exception as e:
        logger.error(f"Unexpected error pulling changes: {str(e)}")
        return False

# -----------------------------------------------------------------------------
# Background Syncer
# -----------------------------------------------------------------------------

def is_syncing() -> bool:
    """Check if a sync is currently in progress."""
    return os.path.exists(LOCK_FILE)

def create_lock_file() -> bool:
    """Create a lock file to indicate sync in progress."""
    try:
        with open(LOCK_FILE, 'w') as f:
            f.write(str(datetime.datetime.now().isoformat()))
        return True
    except Exception as e:
        logger.error(f"Failed to create lock file: {str(e)}")
        return False

def remove_lock_file() -> bool:
    """Remove the lock file."""
    try:
        if os.path.exists(LOCK_FILE):
            os.remove(LOCK_FILE)
        return True
    except Exception as e:
        logger.error(f"Failed to remove lock file: {str(e)}")
        return False

def update_last_sync_time() -> bool:
    """Update the last sync time file."""
    try:
        with open(LAST_SYNC_FILE, 'w') as f:
            f.write(datetime.datetime.now().isoformat())
        return True
    except Exception as e:
        logger.error(f"Failed to update last sync time: {str(e)}")
        return False

def get_last_sync_time() -> Optional[str]:
    """Get the last sync time."""
    if not os.path.exists(LAST_SYNC_FILE):
        return None
    
    try:
        with open(LAST_SYNC_FILE, 'r') as f:
            return f.read().strip()
    except Exception as e:
        logger.error(f"Failed to read last sync time: {str(e)}")
        return None

def sync_once(config: Dict[str, Any]) -> bool:
    """Perform a single sync operation."""
    if is_syncing():
        logger.warning("Sync already in progress")
        return False
    
    create_lock_file()
    try:
        return perform_sync(config)
    finally:
        remove_lock_file()

def perform_sync(config: Dict[str, Any]) -> bool:
    """Perform a complete sync operation."""
    logger.info("Starting sync operation")
    
    dry_run = config.get("dry_run", False)
    if dry_run:
        print_warning("Running in DRY RUN mode - no changes will be made")
    
    # Perform pre-flight checks
    if not perform_preflight_checks(config):
        logger.error("Pre-flight checks failed")
        print_error("Pre-flight checks failed. Please resolve the issues above before syncing.")
        return False
    
    # Check if repository is configured
    if not config.get("repository", {}).get("url"):
        logger.error("No repository configured")
        print_error("No repository configured. Please run 'mac-sync-wizard setup' first.")
        return False
    
    # Pull latest changes from repository
    if not dry_run:
        print_step("Pulling latest changes from repository...")
        if not pull_changes(config["repository"]["branch"]):
            logger.error("Failed to pull changes from repository")
            print_warning("Failed to pull changes. Continuing with local state...")
            # Don't fail completely - we can still backup local changes
    else:
        print_step("[DRY RUN] Would pull latest changes from repository")
    
    # Backup all enabled utilities
    enabled_utilities = get_enabled_utilities(config)
    if not enabled_utilities:
        logger.warning("No utilities enabled for sync")
        print_warning("No utilities are enabled for sync. Enable utilities using 'mac-sync-wizard config'.")
        return True
    
    print_step(f"Backing up {len(enabled_utilities)} enabled utilities...")
    backup_failures = []
    utility_sizes = {}
    total_size = 0
    
    for utility in enabled_utilities:
        utility_config = config["utilities"].get(utility)
        if not utility_config:
            logger.warning(f"No configuration found for utility: {utility}")
            continue
        
        # Calculate size before backup
        utility_total_size = 0
        size_info = []
        
        # Special size calculation for fonts
        if utility == "fonts":
            custom_fonts = utility_config.get("custom_fonts", [])
            include_patterns = utility_config.get("include_patterns", [])
            
            if custom_fonts or include_patterns:
                # Calculate size only for configured fonts
                fonts_dir = os.path.expanduser("~/Library/Fonts/")
                
                if custom_fonts:
                    # Calculate size for specific font families
                    for font_family in custom_fonts:
                        font_files = get_font_files_for_family(font_family)
                        family_size = 0
                        for font_file in font_files:
                            font_path = os.path.join(fonts_dir, font_file)
                            if os.path.exists(font_path):
                                file_size = os.path.getsize(font_path)
                                family_size += file_size
                        
                        if family_size > 0:
                            # Convert to human readable
                            temp_size = family_size
                            for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
                                if temp_size < 1024.0:
                                    size_human = f"{temp_size:.1f} {unit}"
                                    break
                                temp_size /= 1024.0
                            size_info.append(f"{font_family}: {size_human}")
                            utility_total_size += family_size
                
                elif include_patterns:
                    # Calculate size for pattern-matched fonts
                    import glob
                    for pattern in include_patterns:
                        pattern_path = os.path.join(fonts_dir, pattern)
                        matching_files = glob.glob(pattern_path)
                        pattern_size = 0
                        for font_path in matching_files:
                            if os.path.exists(font_path):
                                pattern_size += os.path.getsize(font_path)
                        
                        if pattern_size > 0:
                            # Convert to human readable
                            temp_size = pattern_size
                            for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
                                if temp_size < 1024.0:
                                    size_human = f"{temp_size:.1f} {unit}"
                                    break
                                temp_size /= 1024.0
                            size_info.append(f"{pattern}: {size_human}")
                            utility_total_size += pattern_size
            else:
                # No custom configuration, calculate full directory size
                for path in utility_config["paths"]:
                    expanded_path = os.path.expanduser(path)
                    if os.path.exists(expanded_path):
                        size_bytes, size_human = get_directory_size(expanded_path)
                        utility_total_size += size_bytes
                        size_info.append(f"{os.path.basename(expanded_path)}: {size_human}")
        else:
            # Regular utility size calculation
            for path in utility_config["paths"]:
                expanded_path = os.path.expanduser(path)
                if os.path.exists(expanded_path):
                    size_bytes, size_human = get_directory_size(expanded_path)
                    utility_total_size += size_bytes
                    size_info.append(f"{os.path.basename(expanded_path)}: {size_human}")
        
        utility_sizes[utility] = (utility_total_size, size_info)
        total_size += utility_total_size
        
        # Convert utility total to human readable
        _, utility_size_human = get_directory_size("dummy")  # Just to get formatting
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if utility_total_size < 1024.0:
                utility_size_human = f"{utility_total_size:.1f} {unit}"
                break
            utility_total_size /= 1024.0
        
        print(f"  • {'Would backup' if dry_run else 'Backing up'} {utility} ({utility_size_human})...")
        
        # Special handling for fonts
        if utility == "fonts":
            custom_fonts = utility_config.get("custom_fonts", [])
            include_patterns = utility_config.get("include_patterns", [])
            exclude_patterns = utility_config.get("exclude_patterns", [])
            
            if not backup_fonts(
                custom_fonts=custom_fonts,
                include_patterns=include_patterns,
                exclude_patterns=exclude_patterns,
                dry_run=dry_run
            ):
                backup_failures.append(utility)
        else:
            # Regular utility backup
            if not backup_utility(
                utility,
                utility_config["paths"],
                utility_config.get("exclude_patterns", []),
                dry_run=dry_run
            ):
                backup_failures.append(utility)
    
    if backup_failures:
        print_warning(f"Failed to backup: {', '.join(backup_failures)}")
    
    # Show size summary if verbose mode is enabled
    if config.get("verbose", False):
        print_step("Backup size summary:")
        for utility, (size_bytes, size_details) in utility_sizes.items():
            if size_details:
                print(f"  • {utility}:")
                for detail in size_details:
                    print(f"      - {detail}")
    
    # Always show total size
    temp_size = total_size
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if temp_size < 1024.0:
            total_size_human = f"{temp_size:.1f} {unit}"
            break
        temp_size /= 1024.0
    else:
        total_size_human = f"{temp_size:.1f} PB"
    
    print(f"\n  Total size to sync: {total_size_human}")
    
    # Commit and push changes
    if config["sync"]["auto_commit"] and not dry_run:
        print_step("Committing and pushing changes...")
        commit_message = config["sync"]["commit_message_template"].format(
            date=datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            changes=f"{len(enabled_utilities)} utilities"
        )
        if not commit_changes(commit_message):
            logger.error("Failed to commit changes")
            print_warning("Failed to commit changes. Your backups are saved locally.")
            return False
        
        if not push_changes(config["repository"]["branch"]):
            logger.error("Failed to push changes")
            print_warning("Failed to push changes. Your changes are committed locally.")
            print_info("You can try pushing manually later with: cd ~/.mac-sync-wizard/repo && git push")
            # Don't fail - changes are at least committed locally
    elif config["sync"]["auto_commit"] and dry_run:
        print_step("[DRY RUN] Would commit and push changes")
    
    # Update last sync time
    if not dry_run:
        update_last_sync_time()
    
    logger.info(f"Sync operation completed successfully{' (DRY RUN)' if dry_run else ''}")
    print_success(f"Successfully {'would sync' if dry_run else 'synced'} {len(enabled_utilities) - len(backup_failures)} utilities")
    return True

def get_sync_status(config: Dict[str, Any]) -> Dict[str, Any]:
    """Get the current sync status."""
    # Get last sync time
    last_sync = get_last_sync_time()
    if not last_sync:
        last_sync = "Never"
    
    # Get next sync time (placeholder)
    next_sync = "Manual sync only"
    if config["sync"]["frequency"] > 0:
        if last_sync != "Never":
            try:
                last_sync_dt = datetime.datetime.fromisoformat(last_sync)
                next_sync_dt = last_sync_dt + datetime.timedelta(seconds=config["sync"]["frequency"])
                next_sync = next_sync_dt.isoformat()
            except:
                next_sync = "Unknown"
    
    # Get repository URL
    repository = config["repository"]["url"]
    
    # Get enabled utilities
    enabled_utilities = get_enabled_utilities(config)
    
    return {
        "last_sync": last_sync,
        "next_sync": next_sync,
        "repository": repository,
        "is_syncing": is_syncing(),
        "enabled_utilities": enabled_utilities,
        "enabled_utilities_count": len(enabled_utilities),
        "total_utilities_count": len(config["utilities"])
    }

def install_launch_agent() -> bool:
    """Install the LaunchAgent for automatic startup."""
    logger.info("Installing LaunchAgent")
    
    # Create LaunchAgents directory if it doesn't exist
    launch_agents_dir = os.path.expanduser("~/Library/LaunchAgents")
    os.makedirs(launch_agents_dir, exist_ok=True)
    
    # Create plist file
    plist_path = os.path.join(launch_agents_dir, "com.mac-sync-wizard.plist")
    
    # Get the sync frequency from config
    config = load_config()
    frequency = config["sync"]["frequency"]
    
    # Create plist content
    plist_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.mac-sync-wizard</string>
    <key>ProgramArguments</key>
    <array>
        <string>{os.path.expanduser('~/.local/bin/mac-sync-wizard')}</string>
        <string>sync</string>
    </array>
    <key>StartInterval</key>
    <integer>{frequency}</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>{os.path.join(LOGS_DIR, 'daemon.log')}</string>
    <key>StandardErrorPath</key>
    <string>{os.path.join(LOGS_DIR, 'daemon_error.log')}</string>
</dict>
</plist>
"""
    
    try:
        # Write plist file
        with open(plist_path, 'w') as f:
            f.write(plist_content)
        
        # Load the LaunchAgent
        exit_code, _, _ = run_command(["launchctl", "load", plist_path])
        if exit_code != 0:
            logger.error("Failed to load LaunchAgent")
            return False
        
        logger.info("LaunchAgent installed successfully")
        return True
    except Exception as e:
        logger.error(f"Failed to install LaunchAgent: {str(e)}")
        return False

def uninstall_launch_agent() -> bool:
    """Uninstall the LaunchAgent."""
    logger.info("Uninstalling LaunchAgent")
    
    plist_path = os.path.expanduser("~/Library/LaunchAgents/com.mac-sync-wizard.plist")
    
    if not os.path.exists(plist_path):
        logger.info("LaunchAgent not installed")
        return True
    
    try:
        # Unload the LaunchAgent
        exit_code, _, _ = run_command(["launchctl", "unload", plist_path])
        if exit_code != 0:
            logger.error("Failed to unload LaunchAgent")
            return False
        
        # Remove the plist file
        os.remove(plist_path)
        
        logger.info("LaunchAgent uninstalled successfully")
        return True
    except Exception as e:
        logger.error(f"Failed to uninstall LaunchAgent: {str(e)}")
        return False

# -----------------------------------------------------------------------------
# Setup Wizard
# -----------------------------------------------------------------------------

def save_setup_progress(step: str, data: Dict[str, Any]) -> None:
    """Save setup progress to allow resuming."""
    progress_file = os.path.join(CONFIG_DIR, ".setup_progress.json")
    try:
        progress = {}
        if os.path.exists(progress_file):
            with open(progress_file, 'r') as f:
                progress = json.load(f)
        
        progress[step] = {
            "completed": True,
            "timestamp": datetime.datetime.now().isoformat(),
            "data": data
        }
        
        with open(progress_file, 'w') as f:
            json.dump(progress, f, indent=2)
    except Exception as e:
        logger.warning(f"Failed to save setup progress: {str(e)}")

def load_setup_progress() -> Dict[str, Any]:
    """Load setup progress."""
    progress_file = os.path.join(CONFIG_DIR, ".setup_progress.json")
    try:
        if os.path.exists(progress_file):
            with open(progress_file, 'r') as f:
                return json.load(f)
    except Exception as e:
        logger.warning(f"Failed to load setup progress: {str(e)}")
    return {}

def clear_setup_progress() -> None:
    """Clear setup progress after successful completion."""
    progress_file = os.path.join(CONFIG_DIR, ".setup_progress.json")
    try:
        if os.path.exists(progress_file):
            os.remove(progress_file)
    except Exception as e:
        logger.warning(f"Failed to clear setup progress: {str(e)}")

def run_setup_wizard() -> bool:
    """Run the setup wizard."""
    print_header("Mac Sync Wizard Setup")
    
    print("Welcome to Mac Sync Wizard! This wizard will guide you through the setup process.")
    print("This tool will help you synchronize your application settings and configurations using a Git repository.")
    print("Please ensure you have Git installed and configured on your system.")
    
    if not command_exists("git"):
        print_error("Git is not installed or not found in your PATH. Mac Sync Wizard requires Git to function.")
        print_error("Please install Git and ensure it's accessible from your terminal, then run the setup again.")
        return False
    
    config = load_config()
    initial_config_exists = os.path.exists(CONFIG_PATH)
    
    # Check for interrupted setup
    progress = load_setup_progress()
    if progress and not initial_config_exists:
        if get_yes_no("It looks like a previous setup was interrupted. Would you like to resume?", default=True):
            print_info("Resuming from previous setup progress...")
        else:
            clear_setup_progress()
            progress = {}

    if initial_config_exists:
        print_warning("Existing configuration found. You can modify your settings.")
    else:
        print_step("No existing configuration found. Let's set up from scratch.")

    # Repository setup
    if "repository" not in progress:
        print_step("Step 1 of 4: Repository Configuration")
        if config["repository"]["url"]:
            print(f"Current repository: {config['repository']['url']} (branch: {config['repository']['branch']})")
            if not get_yes_no("Do you want to reconfigure the repository?", default=False):
                print_info("Skipping repository reconfiguration.")
                repo_setup_success = True
            else:
                repo_setup_success = configure_repository_wizard_step(config)
        else:
            repo_setup_success = configure_repository_wizard_step(config)

        if not repo_setup_success:
            print_error("Repository setup failed or was skipped by the user and no prior valid configuration exists. Aborting setup.")
            return False
        
        save_config(config)
        save_setup_progress("repository", {"url": config["repository"]["url"], "branch": config["repository"]["branch"]})
    else:
        print_info("Repository configuration already completed in previous session.")
        repo_setup_success = True

    # Utility selection
    if "utilities" not in progress:
        print_step("Step 2 of 4: Utility Selection")
        if not select_utilities(config):
            print_error("Utility selection encountered an issue. Please review your choices.")
        
        save_config(config)
        save_setup_progress("utilities", {"enabled": get_enabled_utilities(config)})
    else:
        print_info("Utility selection already completed in previous session.")

    # Sync configuration
    if "sync" not in progress:
        print_step("Step 3 of 4: Sync Behavior")
        if not configure_sync(config):
            print_error("Sync behavior configuration failed. Using default sync settings.")
        
        save_config(config)
        save_setup_progress("sync", {"frequency": config["sync"]["frequency"], "auto_commit": config["sync"]["auto_commit"]})
    else:
        print_info("Sync configuration already completed in previous session.")

    # Notification preferences
    if "notifications" not in progress:
        print_step("Step 4 of 4: Notification Preferences")
        if not configure_notifications(config):
            print_error("Notification preference configuration failed. Using default notification settings.")
        
        save_setup_progress("notifications", {"level": config["notifications"]["level"]})
    else:
        print_info("Notification configuration already completed in previous session.")

    # Final save of all configurations
    if not save_config(config):
        print_error(f"Failed to save the final configuration. Please check permissions for {CONFIG_PATH}")
        return False
    
    # Clear setup progress on successful completion
    clear_setup_progress()

    print_header("Setup Complete!")
    
    print("Mac Sync Wizard has been successfully configured on this machine.")
    print(f"Your settings are stored in: {CONFIG_PATH}")
    print(f"Your synchronization repository is at: {REPO_DIR}")
    print("\nYou can now use the following commands:")
    print(f"  {sys.argv[0]} sync    - Perform a manual sync")
    print(f"  {sys.argv[0]} config  - Modify your configuration")
    print(f"  {sys.argv[0]} status  - Check sync status")
    
    if config["sync"]["frequency"] > 0:
        print_step("Background Sync Service (LaunchAgent)")
        if get_yes_no("Would you like to install/update the background sync service (LaunchAgent) for automatic syncing?", default=True):
            if install_launch_agent(): # install_launch_agent should be robust
                print_success("Background sync service (LaunchAgent) installed/updated successfully.")
            else:
                print_error("Failed to install/update background sync service. You can try again later using `install` command.")
        else:
            print_warning("Background sync service not installed. You will need to run syncs manually.")
    else:
        print_info("Automatic background sync is disabled (frequency set to manual). Skipping LaunchAgent setup.")
        # Check if an old one exists and offer to remove it
        plist_path = os.path.expanduser("~/Library/LaunchAgents/com.mac-sync-wizard.plist")
        if os.path.exists(plist_path):
            if get_yes_no("Found an existing background sync service LaunchAgent, but automatic sync is disabled. Would you like to remove the old LaunchAgent?", default=True):
                if uninstall_launch_agent():
                    print_success("Successfully removed old background sync service.")
                else:
                    print_error("Failed to remove old background sync service.")

    print_success("Setup process is complete. Enjoy using Mac Sync Wizard!")
    return True

def configure_repository_wizard_step(config: Dict[str, Any]) -> bool:
    """Specific part of the wizard for configuring the repository."""
    repo_options = [
        ("new", "Set up a new Git repository for sync (recommended for first time)"),
        ("existing", "Connect to an existing Git repository (if you already have one)"),
    ]
    if config["repository"]["url"]:
         repo_options.append(("skip", "Keep current repository settings and continue"))
    else:
        repo_options.append(("skip", "Skip repository setup for now (not recommended, sync will not work)"))

    repo_choice = get_menu_choice(repo_options, "Repository Setup Options")

    success = False
    if repo_choice == "new":
        success = setup_new_repository(config)
    elif repo_choice == "existing":
        success = connect_existing_repository(config)
    elif repo_choice == "skip":
        if config["repository"]["url"]:
            print_info("Keeping existing repository configuration.")
            return True # Considered success as user chose to keep existing valid config
        else:
            print_warning("Repository setup skipped. Syncing will not function until a repository is configured.")
            return False # Not a success if no repo is configured
    return success

def setup_new_repository(config: Dict[str, Any]) -> bool:
    """Set up a new Git repository."""
    print_header("New Repository Setup")
    
    repo_url = ""
    while not repo_url:
        repo_url = get_input(
            "Enter the URL for your new repository (e.g., https://github.com/user/repo.git or git@host:user/repo.git)"
        ).strip()
        if not repo_url:
            print_warning("Repository URL cannot be empty.")
        elif not (repo_url.startswith(("http://", "https://")) or repo_url.startswith("git@")):
            print_warning("Invalid URL format. It should start with http(s):// or git@")
            repo_url = "" # Reset to ask again

    branch = get_input("Enter the branch name (e.g., main, master)", "main").strip()
    if not branch:
        branch = "main" # Default if user enters empty string
        print_warning("Branch name was empty, defaulted to 'main'.")

    auth_type = get_choice(
        "Select authentication type (ssh is recommended for private repos)",
        ["ssh", "https"],
        "ssh"
    )
    
    # Save repository configuration
    config["repository"]["url"] = repo_url
    config["repository"]["branch"] = branch
    config["repository"]["auth_type"] = auth_type
    
    # Initialize repository
    if init_repository(repo_url, branch):
        # print_success(f"Repository configuration saved: {repo_url} ({branch}) using {auth_type}") # Redundant with init_repository output
        return True
    else:
        # print_error(f"Failed to initialize repository: {repo_url}") # Redundant with init_repository output
        return False

def connect_existing_repository(config: Dict[str, Any]) -> bool:
    """Connect to an existing Git repository."""
    print_header("Connect to Existing Repository")
    
    repo_url = ""
    while not repo_url:
        repo_url = get_input("Enter the URL of your existing repository").strip()
        if not repo_url:
            print_warning("Repository URL cannot be empty.")
        elif not (repo_url.startswith(("http://", "https://")) or repo_url.startswith("git@")):
            print_warning("Invalid URL format. It should start with http(s):// or git@")
            repo_url = "" # Reset to ask again

    branch = get_input("Enter the branch name", "main").strip()
    if not branch:
        branch = "main"
        print_warning("Branch name was empty, defaulted to 'main'.")

    auth_type = get_choice(
        "Select authentication type",
        ["ssh", "https"],
        "ssh"
    )
    
    # Save repository configuration
    config["repository"]["url"] = repo_url
    config["repository"]["branch"] = branch
    config["repository"]["auth_type"] = auth_type
    
    # Connect to repository
    if init_repository(repo_url, branch): # init_repository now handles both new and existing
        # print_success(f"Connected to repository: {repo_url} ({branch}) using {auth_type}") # Redundant
        return True
    else:
        # print_error(f"Failed to connect to repository: {repo_url}") # Redundant
        return False

def select_utilities(config: Dict[str, Any]) -> bool:
    """Select utilities to sync."""
    print_header("Select Utilities to Sync")
    
    # Detect installed utilities
    installed = detect_installed_utilities()
    print(f"Detected {len(installed)} installed utilities on your system.")
    
    # Separate utilities into syncable and installation-only
    syncable_utilities = []
    installation_only = []
    
    for utility, util_config in config["utilities"].items():
        # Check if this utility is meant for syncing (enabled by default in UTILITY_CONFIGS)
        default_enabled = UTILITY_CONFIGS.get(utility, {}).get("enabled", True)
        if default_enabled:
            syncable_utilities.append(utility)
        else:
            installation_only.append(utility)
    
    # Show installation-only utilities for information
    if installation_only:
        print_info(f"Installation-only utilities (not synced): {', '.join(installation_only)}")
    
    # Only ask about syncable utilities
    print_step("Configure sync settings for available utilities:")
    
    for utility in syncable_utilities:
        util_config = config["utilities"][utility]
        is_installed = utility in installed
        status = "installed" if is_installed else "not detected"
        
        # For syncable utilities, default to enabled if installed
        enabled = get_yes_no(
            f"Enable sync for {utility} ({status})?",
            default=is_installed
        )
        
        config["utilities"][utility]["enabled"] = enabled
        status = "enabled" if enabled else "disabled"
        print(f"  {utility} sync {status}")
        
        # Special configuration for fonts
        if utility == "fonts" and enabled:
            if get_yes_no("\nWould you like to configure custom font selection?", default=True):
                configure_fonts(config["utilities"]["fonts"])
        
        # Special setup for shell aliases
        if utility == "shell" and enabled:
            if get_yes_no("\nWould you like to extract and sync your existing shell aliases?", default=True):
                if setup_shell_sync():
                    print_success("Shell aliases extracted and ready to sync!")
                else:
                    print_warning("Shell setup skipped - you can manually add aliases to ~/.iconfig/shell/aliases.sh")
    
    # Keep installation-only utilities disabled
    for utility in installation_only:
        config["utilities"][utility]["enabled"] = False
    
    return True

def get_installed_font_families() -> List[Tuple[str, int]]:
    """Get a list of installed font families with file counts."""
    fonts_dir = os.path.expanduser("~/Library/Fonts/")
    font_families = {}
    
    try:
        # Analyze all font files to extract family names
        for font_file in os.listdir(fonts_dir):
            if not os.path.isfile(os.path.join(fonts_dir, font_file)):
                continue
                
            # Skip non-font files
            if not font_file.lower().endswith(('.ttf', '.otf', '.ttc')):
                continue
            
            # Extract potential family name from filename
            # Remove extension
            base_name = os.path.splitext(font_file)[0]
            
            # Common patterns to extract family name
            # Remove weight/style suffixes
            family_name = base_name
            
            # Remove common weight/style indicators
            for suffix in ['-Regular', '-Bold', '-Italic', '-Light', '-Medium', '-Thin', 
                          '-Black', '-Heavy', '-ExtraLight', '-ExtraBold', '-SemiBold',
                          '-BoldItalic', '-LightItalic', '-MediumItalic', '-ThinItalic',
                          '-Oblique', '-BoldOblique', 'Regular', 'Bold', 'Italic']:
                if family_name.endswith(suffix):
                    family_name = family_name[:-len(suffix)]
                    break
            
            # Handle camelCase to spaces (e.g., "ZedPlexSans" -> "Zed Plex Sans")
            import re
            family_name = re.sub(r'(?<!^)(?=[A-Z])', ' ', family_name).strip()
            
            # Count files per family
            if family_name:
                font_families[family_name] = font_families.get(family_name, 0) + 1
    
    except Exception as e:
        logger.error(f"Failed to analyze font families: {str(e)}")
    
    # Sort by name and return as list of tuples
    return sorted([(name, count) for name, count in font_families.items()])

def interactive_font_selector(existing_selections: List[str] = None) -> List[str]:
    """Interactive font family selector with search and multi-select."""
    if existing_selections is None:
        existing_selections = []
    
    selected_fonts = set(existing_selections)
    
    print_header("Interactive Font Selector")
    print("Loading installed fonts...")
    
    # Get all font families
    all_fonts = get_installed_font_families()
    
    if not all_fonts:
        print_error("No fonts found in ~/Library/Fonts/")
        return list(selected_fonts)
    
    print(f"\nFound {len(all_fonts)} font families")
    print("\nCommands:")
    print("  [number]     - Toggle selection of a font")
    print("  [a]ll        - Select all fonts")
    print("  [c]lear      - Clear all selections")
    print("  [s]earch     - Search for fonts")
    print("  [d]one       - Finish selection")
    print("  [q]uit       - Cancel without saving")
    
    # Display fonts in pages
    page_size = 20
    current_page = 0
    search_filter = ""
    
    while True:
        # Filter fonts based on search
        if search_filter:
            filtered_fonts = [(name, count) for name, count in all_fonts 
                            if search_filter.lower() in name.lower()]
            print(f"\n🔍 Searching for: '{search_filter}' ({len(filtered_fonts)} results)")
        else:
            filtered_fonts = all_fonts
        
        # Calculate pagination
        total_pages = (len(filtered_fonts) + page_size - 1) // page_size
        current_page = min(current_page, total_pages - 1)
        current_page = max(0, current_page)
        
        start_idx = current_page * page_size
        end_idx = min(start_idx + page_size, len(filtered_fonts))
        
        # Display current page
        print(f"\n📄 Page {current_page + 1}/{total_pages}")
        print("─" * 80)
        
        for i in range(start_idx, end_idx):
            font_name, file_count = filtered_fonts[i]
            selected = "✓" if font_name in selected_fonts else " "
            print(f"  [{selected}] {i + 1:3d}. {font_name:<40} ({file_count} files)")
        
        print("─" * 80)
        print(f"Selected: {len(selected_fonts)} fonts")
        
        # Show navigation options
        nav_options = []
        if current_page > 0:
            nav_options.append("[p]revious")
        if current_page < total_pages - 1:
            nav_options.append("[n]ext")
        if nav_options:
            print(f"Navigation: {', '.join(nav_options)}")
        
        # Get user input
        choice = input("\nYour choice: ").strip().lower()
        
        if choice == 'd' or choice == 'done':
            break
        elif choice == 'q' or choice == 'quit':
            return existing_selections  # Return original selections
        elif choice == 'a' or choice == 'all':
            selected_fonts = set(name for name, _ in filtered_fonts)
            print_success(f"Selected all {len(selected_fonts)} fonts")
        elif choice == 'c' or choice == 'clear':
            selected_fonts.clear()
            print_success("Cleared all selections")
        elif choice == 's' or choice == 'search':
            search_filter = input("Search for font (empty to clear): ").strip()
            current_page = 0  # Reset to first page
        elif choice == 'p' or choice == 'previous':
            if current_page > 0:
                current_page -= 1
        elif choice == 'n' or choice == 'next':
            if current_page < total_pages - 1:
                current_page += 1
        elif choice.isdigit():
            idx = int(choice) - 1
            if 0 <= idx < len(filtered_fonts):
                font_name = filtered_fonts[idx][0]
                if font_name in selected_fonts:
                    selected_fonts.remove(font_name)
                    print(f"  Deselected: {font_name}")
                else:
                    selected_fonts.add(font_name)
                    print(f"  Selected: {font_name}")
            else:
                print_error("Invalid number")
        else:
            print_error("Invalid choice")
    
    return sorted(list(selected_fonts))

def setup_shell_sync() -> bool:
    """Extract existing shell aliases and set up syncing."""
    print_header("Shell Alias Setup")
    
    shell_config_dir = os.path.expanduser("~/.iconfig/shell")
    os.makedirs(shell_config_dir, exist_ok=True)
    
    # Find shell configuration files
    rc_files = []
    potential_files = [
        "~/.bashrc", "~/.bash_profile", "~/.zshrc", 
        "~/.aliases", "~/.bash_aliases"
    ]
    
    for file_path in potential_files:
        expanded_path = os.path.expanduser(file_path)
        if os.path.exists(expanded_path):
            rc_files.append(expanded_path)
    
    if not rc_files:
        print_warning("No shell configuration files found!")
        return False
    
    print_info(f"Found {len(rc_files)} shell configuration files")
    
    # Extract aliases
    print_step("Extracting existing aliases...")
    aliases = []
    
    for rc_file in rc_files:
        try:
            with open(rc_file, 'r') as f:
                for line in f:
                    # Match alias definitions
                    if line.strip().startswith('alias '):
                        aliases.append(line.rstrip())
        except Exception as e:
            logger.warning(f"Failed to read {rc_file}: {str(e)}")
    
    print_success(f"Found {len(aliases)} aliases")
    
    # Create aliases file
    aliases_file = os.path.join(shell_config_dir, "aliases.sh")
    with open(aliases_file, 'w') as f:
        f.write("#!/bin/bash\n")
        f.write("# Synced shell aliases from iconfig\n")
        f.write("# This file is automatically synced across your machines\n\n")
        f.write("# ============================================\n")
        f.write("# Auto-extracted aliases from your system\n")
        f.write("# ============================================\n\n")
        
        for alias in aliases:
            f.write(f"{alias}\n")
    
    os.chmod(aliases_file, 0o755)
    
    # Create local.sh template
    local_file = os.path.join(shell_config_dir, "local.sh")
    with open(local_file, 'w') as f:
        f.write("#!/bin/bash\n")
        f.write("# Local machine-specific aliases and configurations\n")
        f.write("# This file is NOT synced - use it for machine-specific settings\n\n")
        f.write("# Example:\n")
        f.write("# alias work-vpn='sudo openconnect vpn.company.com'\n")
        f.write("# export WORK_DIR=\"/Users/me/work\"\n")
    
    # Create .gitignore
    gitignore_file = os.path.join(shell_config_dir, ".gitignore")
    with open(gitignore_file, 'w') as f:
        f.write("# Local configurations (machine-specific, not synced)\n")
        f.write("local.sh\n")
        f.write("*.local\n\n")
        f.write("# Temporary files\n")
        f.write("*.tmp\n")
        f.write("*.swp\n")
        f.write("*~\n\n")
        f.write("# OS files\n")
        f.write(".DS_Store\n")
    
    # Create loader script
    loader_file = os.path.join(shell_config_dir, "load.sh")
    with open(loader_file, 'w') as f:
        f.write("#!/bin/bash\n")
        f.write("# iconfig Shell Configuration Loader\n")
        f.write("# Source this file from your .bashrc/.zshrc\n\n")
        f.write("# Get the directory of this script\n")
        f.write("SHELL_CONFIG_DIR=\"$(dirname \"${BASH_SOURCE[0]:-$0}\")\"\n\n")
        f.write("# Load synced aliases\n")
        f.write("[ -f \"$SHELL_CONFIG_DIR/aliases.sh\" ] && source \"$SHELL_CONFIG_DIR/aliases.sh\"\n\n")
        f.write("# Load any local overrides (not synced)\n")
        f.write("[ -f \"$SHELL_CONFIG_DIR/local.sh\" ] && source \"$SHELL_CONFIG_DIR/local.sh\"\n")
    
    os.chmod(loader_file, 0o755)
    
    # Show preview
    if aliases:
        print_step("Preview of extracted aliases:")
        for i, alias in enumerate(aliases[:5]):
            print(f"  {alias}")
        if len(aliases) > 5:
            print(f"  ... and {len(aliases) - 5} more aliases")
    
    # Setup auto-loading
    current_shell = os.path.basename(os.environ.get('SHELL', ''))
    rc_file = None
    
    if current_shell == 'zsh':
        rc_file = os.path.expanduser("~/.zshrc")
    elif current_shell == 'bash':
        rc_file = os.path.expanduser("~/.bashrc")
    
    if rc_file and os.path.exists(rc_file):
        # Check if loader already exists
        loader_line = '[ -f "$HOME/.iconfig/shell/load.sh" ] && source "$HOME/.iconfig/shell/load.sh"'
        
        with open(rc_file, 'r') as f:
            content = f.read()
        
        if "iconfig/shell/load.sh" not in content:
            if get_yes_no(f"\nAdd shell alias loader to {rc_file}?", default=True):
                # Backup RC file
                backup_path = f"{rc_file}.backup.{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}"
                shutil.copy2(rc_file, backup_path)
                
                with open(rc_file, 'a') as f:
                    f.write("\n# iconfig shell configuration loader\n")
                    f.write(f"{loader_line}\n")
                
                print_success(f"Added loader to {rc_file}")
                print_info(f"Backup saved to {backup_path}")
                print_info("Run 'source ~/.zshrc' or restart your shell to load aliases")
        else:
            print_info("Shell loader already configured")
    
    return True

def configure_fonts(fonts_config: Dict[str, Any]) -> None:
    """Configure font sync settings."""
    print_header("Font Sync Configuration")
    
    print("By default, ALL fonts in ~/Library/Fonts/ will be synced (can be very large).")
    print("You can specify font families by name (as shown in Font Book) to sync only specific fonts.")
    
    options = [
        ("interactive", "Interactive font selector (recommended)"),
        ("manual", "Manually type font family names"),
        ("pattern", "Use file patterns to match fonts (e.g., 'MyCompany-*.ttf')"),
        ("exclude", "Sync all fonts except specific patterns"),
        ("all", "Sync all fonts (default, may be large)"),
        ("skip", "Skip font configuration for now")
    ]
    
    choice = get_menu_choice(options, "How would you like to configure font syncing?")
    
    if choice == "interactive":
        # Use interactive selector
        existing = fonts_config.get("custom_fonts", [])
        selected_fonts = interactive_font_selector(existing)
        
        if selected_fonts:
            fonts_config["custom_fonts"] = selected_fonts
            print_success(f"Will sync {len(selected_fonts)} font families")
            
            # Show summary of what will be synced
            total_files = 0
            total_size = 0
            large_files_warning = False
            
            for font in selected_fonts:
                files = get_font_files_for_family(font)
                total_files += len(files)
                
                # Calculate size for this font family
                fonts_dir = os.path.expanduser("~/Library/Fonts/")
                for file in files:
                    file_path = os.path.join(fonts_dir, file)
                    if os.path.exists(file_path):
                        file_size = os.path.getsize(file_path)
                        total_size += file_size
                        if file_size > 50 * 1024 * 1024:  # 50MB warning threshold
                            large_files_warning = True
                
                # Show first 5 fonts
                if len(selected_fonts) <= 5 or selected_fonts.index(font) < 5:
                    print(f"  • {font} ({len(files)} files)")
            
            if len(selected_fonts) > 5:
                print(f"  ... and {len(selected_fonts) - 5} more families")
            
            # Show total size
            size_mb = total_size / (1024 * 1024)
            print(f"\nTotal size: {size_mb:.1f} MB")
            
            # Warn about large files
            if large_files_warning:
                print_warning("Some font files are larger than 50MB!")
                if not command_exists("git-lfs"):
                    print_error("Git LFS is not installed. Large files will cause issues!")
                    print_info("Install Git LFS with: brew install git-lfs")
                    print_info("Then run: git lfs install")
                else:
                    print_success("Git LFS is installed and will handle large files")
        else:
            print_warning("No fonts selected")
    
    elif choice == "manual":
        print_info("Enter font family names as they appear in Font Book (e.g., 'Zed Plex Sans', 'SF Mono')")
        print_info("This will automatically include all weights and styles for each font family.")
        print_info("Press Enter on an empty line when done.")
        
        custom_fonts = []
        while True:
            font = input("Font family name: ").strip()
            if not font:
                break
            custom_fonts.append(font)
            
            # Show what files will be included for this font family
            font_files = get_font_files_for_family(font)
            if font_files:
                print(f"  Found {len(font_files)} files: {', '.join(font_files[:3])}" + 
                      (f" and {len(font_files) - 3} more" if len(font_files) > 3 else ""))
            else:
                print_warning(f"  No files found for '{font}' - please check the name")
        
        if custom_fonts:
            fonts_config["custom_fonts"] = custom_fonts
            print_success(f"Will sync {len(custom_fonts)} font families")
        else:
            print_warning("No font families specified")
    
    elif choice == "pattern":
        print_info("Enter file patterns to match fonts (e.g., 'MyCompany-*.ttf', 'Custom*.otf')")
        print_info("Press Enter on an empty line when done.")
        
        include_patterns = []
        while True:
            pattern = input("Pattern: ").strip()
            if not pattern:
                break
            include_patterns.append(pattern)
        
        if include_patterns:
            fonts_config["include_patterns"] = include_patterns
            print_success(f"Will sync fonts matching {len(include_patterns)} patterns")
        else:
            print_warning("No patterns specified")
    
    elif choice == "exclude":
        print_info("Enter patterns to exclude (e.g., 'System*.ttf', '*.dfont')")
        print_info("Press Enter on an empty line when done.")
        
        exclude_patterns = []
        while True:
            pattern = input("Exclude pattern: ").strip()
            if not pattern:
                break
            exclude_patterns.append(pattern)
        
        if exclude_patterns:
            fonts_config["exclude_patterns"] = exclude_patterns
            print_success(f"Will exclude fonts matching {len(exclude_patterns)} patterns")
        else:
            print_warning("No exclude patterns specified")
    
    elif choice == "all":
        # Clear any custom configuration
        fonts_config.pop("custom_fonts", None)
        fonts_config.pop("include_patterns", None)
        print_warning("Will sync ALL fonts (this may be very large!)")
    
    # Show current configuration summary
    if fonts_config.get("custom_fonts"):
        print_info(f"Font families to sync: {', '.join(fonts_config['custom_fonts'][:3])}" + 
                  (f" and {len(fonts_config['custom_fonts']) - 3} more" if len(fonts_config['custom_fonts']) > 3 else ""))
    elif fonts_config.get("include_patterns"):
        print_info(f"Include patterns: {', '.join(fonts_config['include_patterns'])}")
    elif fonts_config.get("exclude_patterns"):
        print_info(f"Exclude patterns: {', '.join(fonts_config['exclude_patterns'])}")
    else:
        print_info("Syncing all fonts")

def configure_sync(config: Dict[str, Any]) -> bool:
    """Configure sync settings."""
    print_header("Configure Sync Settings")
    
    # Sync frequency
    frequency_options = [
        ("15min", "Every 15 minutes", 900),
        ("30min", "Every 30 minutes", 1800),
        ("1hour", "Every hour", 3600),
        ("6hours", "Every 6 hours (recommended)", 21600),
        ("12hours", "Every 12 hours", 43200),
        ("daily", "Once a day", 86400),
        ("manual", "Manual sync only", 0)
    ]
    
    print("Sync Frequency:")
    for key, desc, _ in frequency_options:
        print(f"  [{key}] {desc}")
    
    frequency_key = get_choice(
        "Select sync frequency",
        [key for key, _, _ in frequency_options],
        "6hours"
    )
    
    # Find the selected frequency
    frequency_seconds = 21600  # Default to 6 hours
    for key, desc, seconds in frequency_options:
        if key == frequency_key:
            frequency_seconds = seconds
            break
    
    # Auto commit
    auto_commit = get_yes_no("Enable automatic commits?", True)
    
    # Save sync configuration
    config["sync"]["frequency"] = frequency_seconds
    config["sync"]["auto_commit"] = auto_commit
    
    # Get frequency description for display
    frequency_desc = "Manual sync only"
    for key, desc, seconds in frequency_options:
        if seconds == frequency_seconds:
            frequency_desc = desc
            break
    
    print_success(f"Sync configuration saved: {frequency_desc}, auto-commit: {'enabled' if auto_commit else 'disabled'}")
    
    return True

def configure_notifications(config: Dict[str, Any]) -> bool:
    """Configure notification preferences."""
    print_header("Configure Notifications")
    
    # Notification level
    notification_options = [
        ("all", "All notifications (sync success and errors)"),
        ("errors", "Errors only (recommended)"),
        ("none", "No notifications")
    ]
    
    print("Notification Level:")
    for key, desc in notification_options:
        print(f"  [{key}] {desc}")
    
    level = get_choice(
        "Select notification level",
        [key for key, _ in notification_options],
        "errors"
    )
    
    # Save notification configuration
    config["notifications"]["level"] = level
    
    # Get description for display
    level_desc = "Unknown"
    for key, desc in notification_options:
        if key == level:
            level_desc = desc
            break
    
    print_success(f"Notification configuration saved: {level_desc}")
    
    return True

# -----------------------------------------------------------------------------
# Configuration UI
# -----------------------------------------------------------------------------

def run_config_ui() -> bool:
    """Run the configuration UI."""
    print_header("Mac Sync Wizard Configuration")
    
    # Load config
    config = load_config()
    
    while True:
        # Display main menu
        options = [
            ("repo", "Repository Settings"),
            ("sync", "Sync Settings"),
            ("utils", "Utility Selection"),
            ("notif", "Notification Settings"),
            ("save", "Save and Exit"),
            ("exit", "Exit without Saving")
        ]
        
        choice = get_menu_choice(options, "Configuration Menu")
        
        if choice == "repo":
            configure_repository(config)
        elif choice == "sync":
            configure_sync(config)
        elif choice == "utils":
            select_utilities(config)
        elif choice == "notif":
            configure_notifications(config)
        elif choice == "save":
            save_config(config)
            print_success("Configuration saved")
            break
        elif choice == "exit":
            if get_yes_no("Are you sure you want to exit without saving?", False):
                print_warning("Exiting without saving changes")
                break
    
    return True

def configure_repository(config: Dict[str, Any]) -> bool:
    """Configure repository settings."""
    print_header("Repository Settings")
    
    # Display current settings
    print(f"Current repository URL: {config['repository']['url']}")
    print(f"Current branch: {config['repository']['branch']}")
    print(f"Current authentication type: {config['repository']['auth_type']}")
    
    # Options
    options = [
        ("url", "Change Repository URL"),
        ("branch", "Change Branch"),
        ("auth", "Change Authentication Type"),
        ("back", "Back to Main Menu")
    ]
    
    choice = get_menu_choice(options, "Repository Settings")
    
    if choice == "url":
        repo_url = get_input("Enter new repository URL", config['repository']['url'])
        config['repository']['url'] = repo_url
        print_success(f"Repository URL updated to: {repo_url}")
    elif choice == "branch":
        branch = get_input("Enter new branch name", config['repository']['branch'])
        config['repository']['branch'] = branch
        print_success(f"Branch updated to: {branch}")
    elif choice == "auth":
        auth_type = get_choice(
            "Select authentication type",
            ["ssh", "https"],
            config['repository']['auth_type']
        )
        config['repository']['auth_type'] = auth_type
        print_success(f"Authentication type updated to: {auth_type}")
    
    return True

# -----------------------------------------------------------------------------
# Command Handlers
# -----------------------------------------------------------------------------

def setup_command(args):
    """Run the setup wizard"""
    logger.info("Starting setup wizard")
    
    if hasattr(args, 'fresh') and args.fresh:
        logger.info("Fresh reinstall requested")
        print_warning("Fresh reinstall requested. This will remove all existing configuration and repository data.")
        
        if get_yes_no("Are you sure you want to perform a fresh reinstall? This cannot be undone.", default=False):
            print_step("Removing existing configuration and repository...")
            
            # Remove existing configuration
            if os.path.exists(CONFIG_PATH):
                try:
                    os.remove(CONFIG_PATH)
                    logger.info("Removed existing configuration")
                except Exception as e:
                    logger.error(f"Failed to remove configuration: {str(e)}")
                    print_error(f"Failed to remove configuration: {str(e)}")
            
            # Remove setup progress
            clear_setup_progress()
            
            # Remove repository directory
            if os.path.exists(REPO_DIR):
                try:
                    shutil.rmtree(REPO_DIR)
                    logger.info("Removed existing repository")
                except Exception as e:
                    logger.error(f"Failed to remove repository: {str(e)}")
                    print_error(f"Failed to remove repository: {str(e)}")
            
            # Remove last sync file
            if os.path.exists(LAST_SYNC_FILE):
                try:
                    os.remove(LAST_SYNC_FILE)
                    logger.info("Removed last sync file")
                except Exception as e:
                    logger.error(f"Failed to remove last sync file: {str(e)}")
            
            # Remove lock file if exists
            if os.path.exists(LOCK_FILE):
                try:
                    os.remove(LOCK_FILE)
                    logger.info("Removed lock file")
                except Exception as e:
                    logger.error(f"Failed to remove lock file: {str(e)}")
            
            # Uninstall LaunchAgent if exists
            plist_path = os.path.expanduser("~/Library/LaunchAgents/com.mac-sync-wizard.plist")
            if os.path.exists(plist_path):
                print_step("Removing existing background service...")
                uninstall_launch_agent()
            
            print_success("Fresh reinstall preparation complete. Starting setup wizard...")
        else:
            print_info("Fresh reinstall cancelled.")
            return
    
    run_setup_wizard()

def sync_command(args):
    """Run a manual sync operation"""
    logger.info("Starting manual sync")
    
    # Load config
    config = load_config()
    
    if args.dry_run:
        print_warning("DRY RUN MODE: No changes will be made")
        config["dry_run"] = True
    
    if hasattr(args, 'verbose') and args.verbose:
        config["verbose"] = True
    
    if args.daemon:
        logger.info("Running in daemon mode")
        # In a real implementation, this would start a daemon process
        # For now, just run a single sync
        success = sync_once(config)
    else:
        success = sync_once(config)
        
        if success:
            logger.info("Sync completed successfully")
            if not args.dry_run:
                print_success("Sync completed successfully")
            else:
                print_success("Dry run completed successfully (no changes were made)")
        else:
            logger.error("Sync failed")
            print_error("Sync failed. Check logs for details.")

def config_command(args):
    """Run the configuration UI"""
    logger.info("Starting configuration UI")
    
    # Load config
    config = load_config()
    
    if args.frequency:
        logger.info(f"Setting sync frequency to {args.frequency} seconds")
        config["sync"]["frequency"] = args.frequency
        save_config(config)
        print_success(f"Sync frequency set to {args.frequency} seconds")
    elif args.enable:
        logger.info(f"Enabling utility: {args.enable}")
        if args.enable in config["utilities"]:
            config["utilities"][args.enable]["enabled"] = True
            save_config(config)
            print_success(f"Utility {args.enable} enabled")
        else:
            print_error(f"Unknown utility: {args.enable}")
    elif args.disable:
        logger.info(f"Disabling utility: {args.disable}")
        if args.disable in config["utilities"]:
            config["utilities"][args.disable]["enabled"] = False
            save_config(config)
            print_success(f"Utility {args.disable} disabled")
        else:
            print_error(f"Unknown utility: {args.disable}")
    elif args.reset:
        logger.info("Resetting configuration to defaults")
        config = create_default_config()
        print_success("Configuration reset to defaults")
    elif hasattr(args, 'fonts') and args.fonts:
        logger.info("Configuring font sync settings")
        if "fonts" in config["utilities"]:
            configure_fonts(config["utilities"]["fonts"])
            save_config(config)
            print_success("Font configuration saved")
        else:
            print_error("Fonts utility not found in configuration")
    else:
        run_config_ui()

def status_command(args):
    """Show sync status"""
    logger.info("Checking sync status")
    
    # Load config
    config = load_config()
    
    # Get status
    status = get_sync_status(config)
    
    print("\n🔄 Mac Sync Wizard Status\n")
    print(f"Last sync: {status['last_sync']}")
    print(f"Next scheduled sync: {status['next_sync']}")
    print(f"Repository: {status['repository']}")
    print(f"Enabled utilities: {status['enabled_utilities_count']}/{status['total_utilities_count']}")
    
    if status['is_syncing']:
        print("\nSync is currently in progress")
    
    if args.verbose:
        print("\nEnabled utilities:")
        total_size = 0
        for utility in status['enabled_utilities']:
            utility_config = config["utilities"].get(utility, {})
            utility_size = 0
            
            # Calculate size for this utility
            for path in utility_config.get("paths", []):
                expanded_path = os.path.expanduser(path)
                if os.path.exists(expanded_path):
                    size_bytes, _ = get_directory_size(expanded_path)
                    utility_size += size_bytes
            
            total_size += utility_size
            
            # Convert to human readable
            temp_size = utility_size
            for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
                if temp_size < 1024.0:
                    size_human = f"{temp_size:.1f} {unit}"
                    break
                temp_size /= 1024.0
            
            print(f"  - {utility} ({size_human})")
        
        # Show total size
        temp_size = total_size
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if temp_size < 1024.0:
                total_size_human = f"{temp_size:.1f} {unit}"
                break
            temp_size /= 1024.0
        
        print(f"\nTotal size of enabled utilities: {total_size_human}")

def install_command(args):
    """Install or uninstall the background service"""
    logger.info(f"{'Installing' if args.install else 'Uninstalling'} background service")
    
    if args.install:
        success = install_launch_agent()
        if success:
            logger.info("Background service installed successfully")
            print_success("Background service installed successfully")
        else:
            logger.error("Failed to install background service")
            print_error("Failed to install background service")
    else:
        success = uninstall_launch_agent()
        if success:
            logger.info("Background service uninstalled successfully")
            print_success("Background service uninstalled successfully")
        else:
            logger.error("Failed to uninstall background service")
            print_error("Failed to uninstall background service")

def help_command(args):
    """Show help information"""
    print("\n🔄 Mac Sync Wizard Help\n")
    print("Mac Sync Wizard is a tool to synchronize your Mac utilities across multiple machines.")
    print("\nCommands:")
    print("  setup     - Run the setup wizard")
    print("  sync      - Perform a manual sync")
    print("  restore   - Restore configurations from repository") 
    print("  config    - Configure sync settings")
    print("  status    - Check sync status")
    print("  install   - Install or uninstall the background service")
    print("  help      - Show this help information")
    print("\nCommon workflows:")
    print("  First time setup:  mac-sync-wizard setup")
    print("  Daily sync:        mac-sync-wizard sync")
    print("  New machine:       mac-sync-wizard setup && mac-sync-wizard restore")
    print("\nFor more information, see the README.md file or visit:")
    print("https://github.com/username/mac-sync-wizard")

def restore_command(args):
    """Restore configurations from the repository"""
    logger.info("Starting restore operation")
    
    config = load_config()
    
    if not config.get("repository", {}).get("url"):
        print_error("No repository configured. Please run 'mac-sync-wizard setup' first.")
        return
    
    # Perform pre-flight checks
    if not perform_preflight_checks(config):
        print_error("Pre-flight checks failed. Please resolve the issues above before restoring.")
        return
    
    # Pull latest changes
    print_step("Pulling latest changes from repository...")
    if not pull_changes(config["repository"]["branch"]):
        print_error("Failed to pull changes from repository.")
        if not get_yes_no("Continue with local repository state?", default=False):
            return
    
    # Get list of utilities to restore
    if args.utility:
        # Restore specific utility
        if args.utility not in config["utilities"]:
            print_error(f"Unknown utility: {args.utility}")
            print_info(f"Available utilities: {', '.join(config['utilities'].keys())}")
            return
        
        utilities_to_restore = [args.utility]
    else:
        # Restore all enabled utilities
        utilities_to_restore = get_enabled_utilities(config)
        if not utilities_to_restore:
            print_warning("No utilities are enabled. Enable utilities using 'mac-sync-wizard config'.")
            return
    
    print_warning(f"This will restore configurations for: {', '.join(utilities_to_restore)}")
    print_warning("Your current configurations will be backed up before restoring.")
    
    if not get_yes_no("Do you want to continue?", default=False):
        print_info("Restore cancelled.")
        return
    
    # Restore utilities
    restore_failures = []
    for utility in utilities_to_restore:
        utility_config = config["utilities"][utility]
        print(f"  • Restoring {utility}...")
        
        if not restore_utility(utility, utility_config["paths"]):
            restore_failures.append(utility)
    
    if restore_failures:
        print_error(f"Failed to restore: {', '.join(restore_failures)}")
        print_info("Check the logs for more details.")
    else:
        print_success(f"Successfully restored {len(utilities_to_restore)} utilities")

# -----------------------------------------------------------------------------
# Main Entry Point
# -----------------------------------------------------------------------------

def main():
    """Main entry point for the application"""
    # Create application directories if they don't exist
    os.makedirs(CONFIG_DIR, exist_ok=True)
    os.makedirs(LOGS_DIR, exist_ok=True)
    os.makedirs(REPO_DIR, exist_ok=True)
    
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Mac Sync Wizard")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    # Setup command
    setup_parser = subparsers.add_parser("setup", help="Run the setup wizard")
    setup_parser.add_argument("--fresh", action="store_true", help="Perform a fresh reinstall, removing all existing configuration and data")
    
    # Sync command
    sync_parser = subparsers.add_parser("sync", help="Perform a manual sync")
    sync_parser.add_argument("--daemon", action="store_true", help="Run as daemon")
    sync_parser.add_argument("--dry-run", action="store_true", help="Show what would be done without making changes")
    sync_parser.add_argument("--verbose", "-v", action="store_true", help="Show detailed output including file sizes")
    
    # Config command
    config_parser = subparsers.add_parser("config", help="Configure sync settings")
    config_parser.add_argument("--frequency", type=int, help="Sync frequency in seconds")
    config_parser.add_argument("--enable", help="Enable a utility")
    config_parser.add_argument("--disable", help="Disable a utility")
    config_parser.add_argument("--reset", action="store_true", help="Reset to defaults")
    config_parser.add_argument("--fonts", action="store_true", help="Configure font sync settings")
    
    # Status command
    status_parser = subparsers.add_parser("status", help="Check sync status")
    status_parser.add_argument("--verbose", "-v", action="store_true", help="Show verbose output")
    
    # Install command
    install_parser = subparsers.add_parser("install", help="Install or uninstall the background service")
    install_parser.add_argument("--uninstall", action="store_false", dest="install", help="Uninstall the background service")
    
    # Help command
    help_parser = subparsers.add_parser("help", help="Show help information")
    
    # Restore command
    restore_parser = subparsers.add_parser("restore", help="Restore configurations from repository")
    restore_parser.add_argument("--utility", help="Restore specific utility only")
    
    args = parser.parse_args()
    
    # If no command is specified, show help
    if not args.command:
        parser.print_help()
        return
    
    # Run the specified command
    if args.command == "setup":
        setup_command(args)
    elif args.command == "sync":
        sync_command(args)
    elif args.command == "restore":
        restore_command(args)
    elif args.command == "config":
        config_command(args)
    elif args.command == "status":
        status_command(args)
    elif args.command == "install":
        install_command(args)
    elif args.command == "help":
        help_command(args)

if __name__ == "__main__":
    main()
