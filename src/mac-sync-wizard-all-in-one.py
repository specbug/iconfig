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
    "arc": {
        "enabled": False,
        "paths": [
            "~/Library/Application Support/Arc/",
            "~/Library/Preferences/company.thebrowser.Arc.plist"
        ],
        "exclude_patterns": ["Cache/*", "*.log"]
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
        "exclude_patterns": []
    },
    "anki": {
        "enabled": True,
        "paths": [
            "~/Library/Application Support/Anki2/addons21/",
            "~/Library/Application Support/Anki2/prefs21.db"
        ],
        "exclude_patterns": ["*.log"]
    },
    "logi": {
        "enabled": False, # Disabled as per user request
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
        "enabled": False,
        "paths": [
            "~/Library/Application Support/1Password/",
            "~/Library/Preferences/com.1password.1password.plist"
        ],
        "exclude_patterns": ["*.log", "Cache/*"]
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
        "commit_message_template": "Auto-sync: {date} - {changes}"
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

def perform_preflight_checks(config: Dict[str, Any]) -> bool:
    """Perform pre-flight checks before sync operations."""
    print_step("Performing pre-flight checks...")
    
    checks = [
        ("Git installation", lambda: (command_exists("git"), "Git is installed" if command_exists("git") else "Git is not installed")),
        ("Disk space", lambda: check_disk_space(APP_DIR)),
        ("Network connectivity", lambda: check_network_connectivity()),
        ("Git credentials", lambda: check_git_credentials(config.get("repository", {}).get("url", "")))
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

        # Set remote
        # Try removing remote origin first, in case it exists and is wrong (e.g. re-initializing)
        run_command(["git", "remote", "remove", "origin"], cwd=REPO_DIR, check=False) 
        exit_code, _, stderr = run_command(["git", "remote", "add", "origin", url], cwd=REPO_DIR, check=False)
        if exit_code != 0:
            logger.error(f"git remote add origin failed: {stderr}")
            print_error(f"Failed to set remote origin: {stderr}")
            return False
        
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
        
        # Create branch if not main, and ensure we are on it
        # Check if branch already exists locally
        exit_code_local_branch, local_branch_stdout, _ = run_command(["git", "branch", "--list", branch], cwd=REPO_DIR, check=False)
        # Check if branch already exists remotely (and we fetched it)
        exit_code_remote_branch, remote_branch_stdout, _ = run_command(["git", "ls-remote", "--heads", "origin", branch], cwd=REPO_DIR, check=False)

        current_branch_code, current_branch_name, _ = run_command(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=REPO_DIR, check=False)
        current_branch_name = current_branch_name.strip() if current_branch_code == 0 else ""

        if current_branch_name == branch:
            logger.info(f"Already on branch '{branch}'.")
        elif branch in local_branch_stdout:
            logger.info(f"Switching to existing local branch '{branch}'.")
            exit_code, _, stderr = run_command(["git", "checkout", branch], cwd=REPO_DIR, check=False)
            if exit_code != 0:
                logger.error(f"git checkout {branch} failed: {stderr}")
                print_error(f"Failed to checkout local branch {branch}: {stderr}")
                return False
        elif branch in remote_branch_stdout:
             logger.info(f"Remote branch '{branch}' exists. Checking it out and setting up for tracking.")
             exit_code, _, stderr = run_command(["git", "checkout", "-t", f"origin/{branch}"], cwd=REPO_DIR, check=False)
             if exit_code != 0:
                # Fallback: create local branch and try to push/set upstream later
                logger.warning(f"Failed to checkout remote branch '{branch}' with tracking: {stderr}. Creating local branch.")
                exit_code, _, stderr = run_command(["git", "checkout", "-b", branch], cwd=REPO_DIR, check=False)
                if exit_code != 0:
                    logger.error(f"git checkout -b {branch} failed: {stderr}")
                    print_error(f"Failed to create branch {branch}: {stderr}")
                    return False
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

def pull_changes(branch: Optional[str] = None) -> bool:
    """Pull changes from remote repository."""
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
    
    logger.info(f"Pulling changes from branch: {branch}")
    
    try:
        # Pull changes
        exit_code, _, _ = run_command(["git", "pull", "origin", branch], cwd=REPO_DIR)
        if exit_code != 0:
            return False
        
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
    
    for utility in enabled_utilities:
        utility_config = config["utilities"].get(utility)
        if not utility_config:
            logger.warning(f"No configuration found for utility: {utility}")
            continue
        
        print(f"  • {'Would backup' if dry_run else 'Backing up'} {utility}...")
        if not backup_utility(
            utility,
            utility_config["paths"],
            utility_config.get("exclude_patterns", []),
            dry_run=dry_run
        ):
            backup_failures.append(utility)
    
    if backup_failures:
        print_warning(f"Failed to backup: {', '.join(backup_failures)}")
    
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
    
    # For each utility, ask if it should be enabled
    for utility, util_config in config["utilities"].items():
        is_installed = utility in installed
        status = "installed" if is_installed else "not detected"
        
        enabled = get_yes_no(
            f"Enable sync for {utility} ({status})?",
            default=is_installed
        )
        
        config["utilities"][utility]["enabled"] = enabled
        status = "enabled" if enabled else "disabled"
        print(f"{utility} sync {status}")
    
    return True

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
    run_setup_wizard()

def sync_command(args):
    """Run a manual sync operation"""
    logger.info("Starting manual sync")
    
    # Load config
    config = load_config()
    
    if args.dry_run:
        print_warning("DRY RUN MODE: No changes will be made")
        config["dry_run"] = True
    
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
        for utility in status['enabled_utilities']:
            print(f"  - {utility}")

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
    
    # Sync command
    sync_parser = subparsers.add_parser("sync", help="Perform a manual sync")
    sync_parser.add_argument("--daemon", action="store_true", help="Run as daemon")
    sync_parser.add_argument("--dry-run", action="store_true", help="Show what would be done without making changes")
    
    # Config command
    config_parser = subparsers.add_parser("config", help="Configure sync settings")
    config_parser.add_argument("--frequency", type=int, help="Sync frequency in seconds")
    config_parser.add_argument("--enable", help="Enable a utility")
    config_parser.add_argument("--disable", help="Disable a utility")
    config_parser.add_argument("--reset", action="store_true", help="Reset to defaults")
    
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
