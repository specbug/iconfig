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
            "~/Library/Preferences/PyCharm*/keymaps/",
            "~/Library/Preferences/PyCharm*/options/",
            "~/Library/Application Support/JetBrains/PyCharm*/plugins/"
        ],
        "exclude_patterns": ["*.log", "Cache/*"]
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
        "enabled": True,
        "paths": [
            "~/Library/Application Support/Arc/",
            "~/Library/Preferences/company.thebrowser.Arc.plist"
        ],
        "exclude_patterns": ["Cache/*", "*.log"]
    },
    "warp": {
        "enabled": True,
        "paths": [
            "~/.warp/",
            "~/Library/Application Support/dev.warp.Warp-Stable/"
        ],
        "exclude_patterns": ["Cache/*", "*.log"]
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
        "enabled": True,
        "paths": [
            "~/Library/Preferences/com.logi.optionsplus.plist",
            "~/Library/Application Support/Logitech/"
        ],
        "exclude_patterns": ["Cache/*"]
    },
    "1password": {
        "enabled": True,
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
            text=True
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

def init_repository(url: str, branch: str = "main") -> bool:
    """Initialize a new repository or connect to existing one."""
    logger.info(f"Initializing repository: {url} ({branch})")
    
    if os.path.exists(os.path.join(REPO_DIR, ".git")):
        return connect_existing_repo(url, branch)
    else:
        return create_new_repo(url, branch)

def create_new_repo(url: str, branch: str) -> bool:
    """Create a new repository and set remote."""
    try:
        # Create repository directory
        os.makedirs(REPO_DIR, exist_ok=True)
        
        # Initialize Git repository
        exit_code, _, _ = run_command(["git", "init"], cwd=REPO_DIR)
        if exit_code != 0:
            return False
        
        # Set remote
        exit_code, _, _ = run_command(["git", "remote", "add", "origin", url], cwd=REPO_DIR)
        if exit_code != 0:
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
        exit_code, _, _ = run_command(["git", "commit", "-m", "Initial commit"], cwd=REPO_DIR)
        if exit_code != 0:
            return False
        
        # Create branch if not main
        if branch != "main":
            exit_code, _, _ = run_command(["git", "checkout", "-b", branch], cwd=REPO_DIR)
            if exit_code != 0:
                return False
        
        logger.info(f"Repository created successfully: {url} ({branch})")
        return True
        
    except Exception as e:
        logger.error(f"Unexpected error creating repository: {str(e)}")
        return False

def connect_existing_repo(url: str, branch: str) -> bool:
    """Connect to existing repository."""
    try:
        # Update remote URL
        exit_code, _, _ = run_command(["git", "remote", "set-url", "origin", url], cwd=REPO_DIR)
        if exit_code != 0:
            return False
        
        # Fetch
        exit_code, _, _ = run_command(["git", "fetch"], cwd=REPO_DIR)
        if exit_code != 0:
            return False
        
        # Check if branch exists
        exit_code, stdout, _ = run_command(["git", "branch", "-a"], cwd=REPO_DIR)
        if exit_code != 0:
            return False
        
        if f"remotes/origin/{branch}" in stdout:
            # Checkout branch
            exit_code, _, _ = run_command(["git", "checkout", branch], cwd=REPO_DIR)
            if exit_code != 0:
                return False
        else:
            # Create branch
            exit_code, _, _ = run_command(["git", "checkout", "-b", branch], cwd=REPO_DIR)
            if exit_code != 0:
                return False
        
        logger.info(f"Connected to repository: {url} ({branch})")
        return True
        
    except Exception as e:
        logger.error(f"Unexpected error connecting to repository: {str(e)}")
        return False

def backup_utility(utility_name: str, source_paths: list, exclude_patterns: list = None) -> bool:
    """Backup a specific utility's configuration."""
    logger.info(f"Backing up {utility_name}")
    
    backup_path = os.path.join(REPO_DIR, "backups", utility_name)
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
                if os.path.exists(dest_dir):
                    shutil.rmtree(dest_dir)
                
                # Use rsync if available for better exclude pattern support
                if command_exists("rsync") and exclude_patterns:
                    exclude_args = []
                    for pattern in exclude_patterns:
                        exclude_args.extend(["--exclude", pattern])
                    
                    exit_code, _, _ = run_command(
                        ["rsync", "-a"] + exclude_args + [expanded_path + "/", dest_dir]
                    )
                    if exit_code != 0:
                        success = False
                else:
                    # Fallback to shutil
                    shutil.copytree(expanded_path, dest_dir)
            else:
                # Copy file
                shutil.copy2(expanded_path, backup_path)
            
            files_copied += 1
            logger.debug(f"Copied {expanded_path} to backup")
            
        except Exception as e:
            logger.error(f"Failed to backup {expanded_path}: {str(e)}")
            success = False
    
    if files_copied == 0:
        logger.warning(f"No files were copied for {utility_name}")
    else:
        logger.info(f"Backed up {files_copied} files for {utility_name}")
    
    return success

def restore_utility(utility_name: str, dest_paths: list) -> bool:
    """Restore a specific utility's configuration."""
    logger.info(f"Restoring {utility_name}")
    
    backup_path = os.path.join(REPO_DIR, "backups", utility_name)
    if not os.path.exists(backup_path):
        logger.warning(f"No backup found for {utility_name}")
        return False
    
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
    
    # Pull latest changes from repository
    if not pull_changes(config["repository"]["branch"]):
        logger.error("Failed to pull changes from repository")
        return False
    
    # Backup all enabled utilities
    enabled_utilities = get_enabled_utilities(config)
    for utility in enabled_utilities:
        utility_config = config["utilities"].get(utility)
        if not utility_config:
            logger.warning(f"No configuration found for utility: {utility}")
            continue
        
        backup_utility(
            utility,
            utility_config["paths"],
            utility_config.get("exclude_patterns", [])
        )
    
    # Commit and push changes
    if config["sync"]["auto_commit"]:
        commit_message = config["sync"]["commit_message_template"].format(
            date=datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            changes=f"{len(enabled_utilities)} utilities"
        )
        if not commit_changes(commit_message):
            logger.error("Failed to commit changes")
            return False
        
        if not push_changes(config["repository"]["branch"]):
            logger.error("Failed to push changes")
            return False
    
    # Update last sync time
    update_last_sync_time()
    
    logger.info("Sync operation completed successfully")
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

def run_setup_wizard() -> bool:
    """Run the setup wizard."""
    print_header("Mac Sync Wizard Setup")
    
    print("Welcome to Mac Sync Wizard! This wizard will guide you through the setup process.")
    print("Let's get started by configuring your Git repository for syncing.")
    
    # Load or create config
    config = load_config()
    
    # Repository setup
    repo_options = [
        ("new", "Create a new repository"),
        ("existing", "Connect to an existing repository"),
        ("skip", "Skip repository setup for now")
    ]
    
    repo_choice = get_menu_choice(repo_options, "Repository Setup")
    
    if repo_choice == "new":
        setup_new_repository(config)
    elif repo_choice == "existing":
        connect_existing_repository(config)
    else:
        print_warning("Repository setup skipped. You can configure it later with: mac-sync-wizard config")
    
    # Utility selection
    select_utilities(config)
    
    # Sync configuration
    configure_sync(config)
    
    # Notification preferences
    configure_notifications(config)
    
    # Save config
    save_config(config)
    
    # Setup complete
    print_header("Setup Complete!")
    
    print("Mac Sync Wizard has been successfully set up on this machine.")
    print("You can now use the following commands:")
    print("  mac-sync-wizard sync    - Perform a manual sync")
    print("  mac-sync-wizard config  - Configure sync settings")
    print("  mac-sync-wizard status  - Check sync status")
    
    # Ask if user wants to install the LaunchAgent
    if get_yes_no("Would you like to install the background sync service?"):
        if install_launch_agent():
            print_success("Background sync service installed successfully")
        else:
            print_error("Failed to install background sync service")
    
    return True

def setup_new_repository(config: Dict[str, Any]) -> bool:
    """Set up a new Git repository."""
    print_header("New Repository Setup")
    
    # Get repository URL
    repo_url = get_input(
        "Enter the URL for your new repository (e.g., https://github.com/username/mac-sync.git)"
    )
    
    # Get branch name
    branch = get_input("Enter the branch name", "main")
    
    # Get authentication type
    auth_type = get_choice(
        "Select authentication type",
        ["ssh", "https"],
        "ssh"
    )
    
    # Save repository configuration
    config["repository"]["url"] = repo_url
    config["repository"]["branch"] = branch
    config["repository"]["auth_type"] = auth_type
    
    # Initialize repository
    if init_repository(repo_url, branch):
        print_success(f"Repository configuration saved: {repo_url} ({branch}) using {auth_type}")
        return True
    else:
        print_error(f"Failed to initialize repository: {repo_url}")
        return False

def connect_existing_repository(config: Dict[str, Any]) -> bool:
    """Connect to an existing Git repository."""
    print_header("Connect to Existing Repository")
    
    # Get repository URL
    repo_url = get_input("Enter the URL of your existing repository")
    
    # Get branch name
    branch = get_input("Enter the branch name", "main")
    
    # Get authentication type
    auth_type = get_choice(
        "Select authentication type",
        ["ssh", "https"],
        "ssh"
    )
    
    # Save repository configuration
    config["repository"]["url"] = repo_url
    config["repository"]["branch"] = branch
    config["repository"]["auth_type"] = auth_type
    
    # Initialize repository
    if init_repository(repo_url, branch):
        print_success(f"Connected to repository: {repo_url} ({branch}) using {auth_type}")
        return True
    else:
        print_error(f"Failed to connect to repository: {repo_url}")
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
    
    if args.daemon:
        logger.info("Running in daemon mode")
        # In a real implementation, this would start a daemon process
        # For now, just run a single sync
        success = sync_once(config)
    else:
        success = sync_once(config)
        
        if success:
            logger.info("Sync completed successfully")
            print_success("Sync completed successfully")
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
    print("  config    - Configure sync settings")
    print("  status    - Check sync status")
    print("  install   - Install or uninstall the background service")
    print("  help      - Show this help information")
    print("\nFor more information, see the README.md file or visit:")
    print("https://github.com/username/mac-sync-wizard")

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
