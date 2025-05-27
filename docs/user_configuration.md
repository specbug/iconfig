# User Configuration Implementation

This document outlines the implementation of user-configurable sync settings for the Mac Sync Wizard.

## Configuration Schema

The user configuration is stored in a JSON file at `~/.mac-sync-wizard/config/sync_config.json` with the following structure:

```json
{
  "repository": {
    "url": "https://github.com/username/mac-sync.git",
    "branch": "main",
    "auth_type": "ssh"
  },
  "sync": {
    "frequency": 21600,
    "auto_commit": true,
    "commit_message_template": "Auto-sync: {date} - {changes}"
  },
  "notifications": {
    "level": "errors_only",
    "method": "terminal-notifier"
  },
  "utilities": {
    "cursor": {
      "enabled": true,
      "paths": [
        "~/Library/Application Support/Cursor/User/keybindings.json",
        "~/Library/Application Support/Cursor/User/settings.json"
      ],
      "exclude_patterns": ["*.log", "Cache/*"]
    },
    // Additional utilities...
  }
}
```

## Configuration Module Implementation

```python
#!/usr/bin/env python3

import os
import json
import logging
from pathlib import Path
from typing import Dict, Any, List, Optional

class ConfigManager:
    """
    Manages user configuration for Mac Sync Wizard.
    Handles loading, saving, and validating configuration.
    """
    
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
        "utilities": {}
    }
    
    # Predefined utility configurations
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
    
    # Frequency presets in seconds
    FREQUENCY_PRESETS = {
        "15 minutes": 900,
        "30 minutes": 1800,
        "1 hour": 3600,
        "2 hours": 7200,
        "4 hours": 14400,
        "6 hours": 21600,
        "12 hours": 43200,
        "Daily": 86400,
        "Weekly": 604800
    }
    
    # Notification level options
    NOTIFICATION_LEVELS = ["all", "errors_only", "none"]
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize the configuration manager.
        
        Args:
            config_path: Path to the configuration file. If None, uses default path.
        """
        self.home_dir = os.path.expanduser("~")
        self.app_dir = os.path.join(self.home_dir, ".mac-sync-wizard")
        
        # Default config path if not provided
        if not config_path:
            config_path = os.path.join(self.app_dir, "config", "sync_config.json")
        
        self.config_path = config_path
        self.config = self._load_config()
        self.logger = self._setup_logger()
    
    def _setup_logger(self) -> logging.Logger:
        """Configure logging for the configuration manager"""
        logger = logging.getLogger('mac-sync-wizard.config')
        logger.setLevel(logging.INFO)
        
        # Create logs directory if it doesn't exist
        log_dir = os.path.join(self.app_dir, "logs")
        os.makedirs(log_dir, exist_ok=True)
        
        # Create file handler
        log_file = os.path.join(log_dir, "config.log")
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.INFO)
        
        # Create formatter and add it to the handler
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        file_handler.setFormatter(formatter)
        
        # Add handler to logger
        logger.addHandler(file_handler)
        
        return logger
    
    def _load_config(self) -> Dict[str, Any]:
        """
        Load configuration from file or create default if not exists.
        
        Returns:
            Dict containing configuration
        """
        try:
            if os.path.exists(self.config_path):
                with open(self.config_path, 'r') as f:
                    config = json.load(f)
                
                # Merge with default config to ensure all fields exist
                merged_config = self.DEFAULT_CONFIG.copy()
                self._deep_update(merged_config, config)
                return merged_config
            else:
                # Create default configuration
                return self._create_default_config()
        except Exception as e:
            print(f"Error loading config: {str(e)}")
            return self.DEFAULT_CONFIG.copy()
    
    def _deep_update(self, d: Dict[str, Any], u: Dict[str, Any]) -> None:
        """
        Recursively update a dictionary with another dictionary.
        
        Args:
            d: Dictionary to update
            u: Dictionary with updates
        """
        for k, v in u.items():
            if isinstance(v, dict) and k in d and isinstance(d[k], dict):
                self._deep_update(d[k], v)
            else:
                d[k] = v
    
    def _create_default_config(self) -> Dict[str, Any]:
        """
        Create default configuration with predefined utility settings.
        
        Returns:
            Dict containing default configuration
        """
        config = self.DEFAULT_CONFIG.copy()
        config["utilities"] = self.UTILITY_CONFIGS.copy()
        
        # Create config directory if it doesn't exist
        os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
        
        # Save default config
        with open(self.config_path, 'w') as f:
            json.dump(config, f, indent=2)
        
        return config
    
    def save_config(self) -> bool:
        """
        Save configuration to file.
        
        Returns:
            Boolean indicating success
        """
        try:
            os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
            with open(self.config_path, 'w') as f:
                json.dump(self.config, f, indent=2)
            self.logger.info("Configuration saved successfully")
            return True
        except Exception as e:
            self.logger.error(f"Failed to save config: {str(e)}")
            return False
    
    def get_config(self) -> Dict[str, Any]:
        """
        Get the current configuration.
        
        Returns:
            Dict containing configuration
        """
        return self.config
    
    def set_repository_url(self, url: str) -> bool:
        """
        Set the repository URL.
        
        Args:
            url: Repository URL
        
        Returns:
            Boolean indicating success
        """
        self.config["repository"]["url"] = url
        return self.save_config()
    
    def set_repository_branch(self, branch: str) -> bool:
        """
        Set the repository branch.
        
        Args:
            branch: Repository branch
        
        Returns:
            Boolean indicating success
        """
        self.config["repository"]["branch"] = branch
        return self.save_config()
    
    def set_repository_auth_type(self, auth_type: str) -> bool:
        """
        Set the repository authentication type.
        
        Args:
            auth_type: Authentication type (ssh or https)
        
        Returns:
            Boolean indicating success
        """
        if auth_type not in ["ssh", "https"]:
            self.logger.error(f"Invalid auth type: {auth_type}")
            return False
        
        self.config["repository"]["auth_type"] = auth_type
        return self.save_config()
    
    def set_sync_frequency(self, frequency: int) -> bool:
        """
        Set the sync frequency in seconds.
        
        Args:
            frequency: Sync frequency in seconds
        
        Returns:
            Boolean indicating success
        """
        self.config["sync"]["frequency"] = frequency
        return self.save_config()
    
    def set_sync_frequency_preset(self, preset: str) -> bool:
        """
        Set the sync frequency using a preset.
        
        Args:
            preset: Frequency preset name
        
        Returns:
            Boolean indicating success
        """
        if preset not in self.FREQUENCY_PRESETS:
            self.logger.error(f"Invalid frequency preset: {preset}")
            return False
        
        return self.set_sync_frequency(self.FREQUENCY_PRESETS[preset])
    
    def set_auto_commit(self, enabled: bool) -> bool:
        """
        Set whether to automatically commit changes.
        
        Args:
            enabled: Whether auto-commit is enabled
        
        Returns:
            Boolean indicating success
        """
        self.config["sync"]["auto_commit"] = enabled
        return self.save_config()
    
    def set_commit_message_template(self, template: str) -> bool:
        """
        Set the commit message template.
        
        Args:
            template: Commit message template
        
        Returns:
            Boolean indicating success
        """
        self.config["sync"]["commit_message_template"] = template
        return self.save_config()
    
    def set_notification_level(self, level: str) -> bool:
        """
        Set the notification level.
        
        Args:
            level: Notification level (all, errors_only, none)
        
        Returns:
            Boolean indicating success
        """
        if level not in self.NOTIFICATION_LEVELS:
            self.logger.error(f"Invalid notification level: {level}")
            return False
        
        self.config["notifications"]["level"] = level
        return self.save_config()
    
    def set_notification_method(self, method: str) -> bool:
        """
        Set the notification method.
        
        Args:
            method: Notification method (terminal-notifier, applescript)
        
        Returns:
            Boolean indicating success
        """
        if method not in ["terminal-notifier", "applescript"]:
            self.logger.error(f"Invalid notification method: {method}")
            return False
        
        self.config["notifications"]["method"] = method
        return self.save_config()
    
    def enable_utility(self, utility: str, enabled: bool = True) -> bool:
        """
        Enable or disable a utility.
        
        Args:
            utility: Utility name
            enabled: Whether the utility is enabled
        
        Returns:
            Boolean indicating success
        """
        if utility not in self.config["utilities"]:
            # Check if it's a predefined utility
            if utility in self.UTILITY_CONFIGS:
                # Add the utility with predefined config
                self.config["utilities"][utility] = self.UTILITY_CONFIGS[utility].copy()
            else:
                self.logger.error(f"Unknown utility: {utility}")
                return False
        
        self.config["utilities"][utility]["enabled"] = enabled
        return self.save_config()
    
    def add_utility_path(self, utility: str, path: str) -> bool:
        """
        Add a path to a utility's configuration.
        
        Args:
            utility: Utility name
            path: Path to add
        
        Returns:
            Boolean indicating success
        """
        if utility not in self.config["utilities"]:
            self.logger.error(f"Unknown utility: {utility}")
            return False
        
        if "paths" not in self.config["utilities"][utility]:
            self.config["utilities"][utility]["paths"] = []
        
        if path not in self.config["utilities"][utility]["paths"]:
            self.config["utilities"][utility]["paths"].append(path)
            return self.save_config()
        
        return True  # Path already exists
    
    def remove_utility_path(self, utility: str, path: str) -> bool:
        """
        Remove a path from a utility's configuration.
        
        Args:
            utility: Utility name
            path: Path to remove
        
        Returns:
            Boolean indicating success
        """
        if utility not in self.config["utilities"]:
            self.logger.error(f"Unknown utility: {utility}")
            return False
        
        if "paths" not in self.config["utilities"][utility]:
            return True  # No paths to remove
        
        if path in self.config["utilities"][utility]["paths"]:
            self.config["utilities"][utility]["paths"].remove(path)
            return self.save_config()
        
        return True  # Path doesn't exist
    
    def add_utility_exclude_pattern(self, utility: str, pattern: str) -> bool:
        """
        Add an exclude pattern to a utility's configuration.
        
        Args:
            utility: Utility name
            pattern: Pattern to add
        
        Returns:
            Boolean indicating success
        """
        if utility not in self.config["utilities"]:
            self.logger.error(f"Unknown utility: {utility}")
            return False
        
        if "exclude_patterns" not in self.config["utilities"][utility]:
            self.config["utilities"][utility]["exclude_patterns"] = []
        
        if pattern not in self.config["utilities"][utility]["exclude_patterns"]:
            self.config["utilities"][utility]["exclude_patterns"].append(pattern)
            return self.save_config()
        
        return True  # Pattern already exists
    
    def remove_utility_exclude_pattern(self, utility: str, pattern: str) -> bool:
        """
        Remove an exclude pattern from a utility's configuration.
        
        Args:
            utility: Utility name
            pattern: Pattern to remove
        
        Returns:
            Boolean indicating success
        """
        if utility not in self.config["utilities"]:
            self.logger.error(f"Unknown utility: {utility}")
            return False
        
        if "exclude_patterns" not in self.config["utilities"][utility]:
            return True  # No patterns to remove
        
        if pattern in self.config["utilities"][utility]["exclude_patterns"]:
            self.config["utilities"][utility]["exclude_patterns"].remove(pattern)
            return self.save_config()
        
        return True  # Pattern doesn't exist
    
    def get_enabled_utilities(self) -> List[str]:
        """
        Get a list of enabled utilities.
        
        Returns:
            List of enabled utility names
        """
        return [
            utility for utility, config in self.config["utilities"].items()
            if config.get("enabled", False)
        ]
    
    def get_utility_config(self, utility: str) -> Optional[Dict[str, Any]]:
        """
        Get a utility's configuration.
        
        Args:
            utility: Utility name
        
        Returns:
            Dict containing utility configuration or None if not found
        """
        return self.config["utilities"].get(utility)
    
    def get_sync_frequency(self) -> int:
        """
        Get the sync frequency in seconds.
        
        Returns:
            Sync frequency in seconds
        """
        return self.config["sync"].get("frequency", 21600)
    
    def get_sync_frequency_preset(self) -> Optional[str]:
        """
        Get the sync frequency preset name.
        
        Returns:
            Frequency preset name or None if not a preset
        """
        frequency = self.get_sync_frequency()
        
        for preset, value in self.FREQUENCY_PRESETS.items():
            if value == frequency:
                return preset
        
        return None
    
    def get_notification_level(self) -> str:
        """
        Get the notification level.
        
        Returns:
            Notification level
        """
        return self.config["notifications"].get("level", "errors_only")
    
    def detect_installed_utilities(self) -> List[str]:
        """
        Detect which predefined utilities are installed on the system.
        
        Returns:
            List of installed utility names
        """
        installed = []
        
        for utility, config in self.UTILITY_CONFIGS.items():
            # Check if any of the paths exist
            for path_pattern in config["paths"]:
                expanded_path = os.path.expanduser(path_pattern)
                
                # Handle glob patterns
                if '*' in expanded_path:
                    # Check if any matching files exist
                    matches = list(Path(os.path.dirname(expanded_path)).glob(os.path.basename(expanded_path)))
                    if matches:
                        installed.append(utility)
                        break
                else:
                    # Check if the exact path exists
                    if os.path.exists(expanded_path):
                        installed.append(utility)
                        break
        
        return installed
    
    def reset_to_defaults(self) -> bool:
        """
        Reset configuration to defaults.
        
        Returns:
            Boolean indicating success
        """
        self.config = self._create_default_config()
        return True
```

## Terminal UI for Configuration

```python
#!/usr/bin/env python3

import os
import sys
import time
from typing import Dict, Any, List, Optional, Tuple

# Try to import rich, install if not available
try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.text import Text
    from rich.table import Table
    from rich.prompt import Prompt, Confirm
    from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeElapsedColumn
except ImportError:
    import subprocess
    subprocess.run([sys.executable, "-m", "pip", "install", "rich"], check=True)
    from rich.console import Console
    from rich.panel import Panel
    from rich.text import Text
    from rich.table import Table
    from rich.prompt import Prompt, Confirm
    from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeElapsedColumn

from config_manager import ConfigManager

class ConfigUI:
    """
    Terminal UI for configuring Mac Sync Wizard.
    """
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize the configuration UI.
        
        Args:
            config_path: Path to the configuration file. If None, uses default path.
        """
        self.config_manager = ConfigManager(config_path)
        self.console = Console()
    
    def display_header(self, title: str) -> None:
        """
        Display a header with the given title.
        
        Args:
            title: Header title
        """
        self.console.print()
        self.console.print(Panel(
            Text(title, style="bold blue"),
            border_style="blue",
            expand=False,
            width=80
        ))
        self.console.print()
    
    def display_menu(self, options: List[Tuple[str, str]]) -> str:
        """
        Display a menu with the given options.
        
        Args:
            options: List of (key, description) tuples
        
        Returns:
            Selected option key
        """
        table = Table(show_header=False, box=None, padding=(0, 2, 0, 0))
        table.add_column("Key", style="bold cyan")
        table.add_column("Description")
        
        for key, description in options:
            table.add_row(f"[{key}]", description)
        
        self.console.print(Panel(
            table,
            title="Please select an option",
            border_style="blue",
            expand=False,
            width=80
        ))
        
        valid_keys = [key for key, _ in options]
        while True:
            choice = Prompt.ask("Enter your choice", console=self.console)
            if choice in valid_keys:
                return choice
            self.console.print(f"Invalid choice. Please enter one of: {', '.join(valid_keys)}", style="bold red")
    
    def display_config_summary(self) -> None:
        """Display a summary of the current configuration."""
        config = self.config_manager.get_config()
        
        # Repository section
        repo_table = Table(show_header=False, box=None, padding=(0, 2, 0, 0))
        repo_table.add_column("Setting", style="bold")
        repo_table.add_column("Value")
        
        repo_url = config["repository"]["url"] or "[italic]Not configured[/italic]"
        repo_table.add_row("Repository URL:", repo_url)
        repo_table.add_row("Branch:", config["repository"]["branch"])
        repo_table.add_row("Auth Type:", config["repository"]["auth_type"])
        
        # Sync section
        sync_table = Table(show_header=False, box=None, padding=(0, 2, 0, 0))
        sync_table.add_column("Setting", style="bold")
        sync_table.add_column("Value")
        
        frequency = self.config_manager.get_sync_frequency_preset() or f"{config['sync']['frequency']} seconds"
        sync_table.add_row("Sync Frequency:", frequency)
        sync_table.add_row("Auto Commit:", "Enabled" if config["sync"]["auto_commit"] else "Disabled")
        sync_table.add_row("Commit Message:", config["sync"]["commit_message_template"])
        
        # Notifications section
        notif_table = Table(show_header=False, box=None, padding=(0, 2, 0, 0))
        notif_table.add_column("Setting", style="bold")
        notif_table.add_column("Value")
        
        notif_table.add_row("Notification Level:", config["notifications"]["level"])
        notif_table.add_row("Notification Method:", config["notifications"]["method"])
        
        # Utilities section
        util_table = Table(show_header=True, box=None, padding=(0, 2, 0, 0))
        util_table.add_column("Utility", style="bold")
        util_table.add_column("Enabled")
        util_table.add_column("Paths")
        
        for utility, util_config in config["utilities"].items():
            enabled = "✓" if util_config.get("enabled", False) else "✗"
            paths = len(util_config.get("paths", []))
            util_table.add_row(utility, enabled, str(paths))
        
        # Display all sections
        self.console.print(Panel(
            repo_table,
            title="Repository Configuration",
            border_style="blue",
            expand=False,
            width=80
        ))
        
        self.console.print(Panel(
            sync_table,
            title="Sync Configuration",
            border_style="blue",
            expand=False,
            width=80
        ))
        
        self.console.print(Panel(
            notif_table,
            title="Notification Configuration",
            border_style="blue",
            expand=False,
            width=80
        ))
        
        self.console.print(Panel(
            util_table,
            title="Utilities Configuration",
            border_style="blue",
            expand=False,
            width=80
        ))
    
    def configure_repository(self) -> None:
        """Configure repository settings."""
        self.display_header("Repository Configuration")
        
        # Get current config
        config = self.config_manager.get_config()
        
        # Ask for repository URL
        current_url = config["repository"]["url"]
        new_url = Prompt.ask(
            "Repository URL",
            default=current_url,
            console=self.console
        )
        
        if new_url != current_url:
            self.config_manager.set_repository_url(new_url)
        
        # Ask for branch
        current_branch = config["repository"]["branch"]
        new_branch = Prompt.ask(
            "Branch",
            default=current_branch,
            console=self.console
        )
        
        if new_branch != current_branch:
            self.config_manager.set_repository_branch(new_branch)
        
        # Ask for auth type
        current_auth = config["repository"]["auth_type"]
        auth_options = [
            ("ssh", "SSH (recommended for private repositories)"),
            ("https", "HTTPS (easier setup, may require credentials)")
        ]
        
        self.console.print("Authentication Type:")
        for key, desc in auth_options:
            self.console.print(f"  [{key}] {desc}")
        
        new_auth = Prompt.ask(
            "Select authentication type",
            choices=["ssh", "https"],
            default=current_auth,
            console=self.console
        )
        
        if new_auth != current_auth:
            self.config_manager.set_repository_auth_type(new_auth)
        
        self.console.print("Repository configuration updated", style="bold green")
    
    def configure_sync(self) -> None:
        """Configure sync settings."""
        self.display_header("Sync Configuration")
        
        # Get current config
        config = self.config_manager.get_config()
        
        # Ask for sync frequency
        current_frequency = self.config_manager.get_sync_frequency()
        current_preset = self.config_manager.get_sync_frequency_preset()
        
        frequency_options = []
        for preset, seconds in self.config_manager.FREQUENCY_PRESETS.items():
            selected = "✓ " if seconds == current_frequency else "  "
            frequency_options.append((preset, f"{selected}{preset} ({seconds} seconds)"))
        
        frequency_options.append(("custom", "  Custom frequency"))
        
        self.console.print("Sync Frequency:")
        for key, desc in frequency_options:
            self.console.print(f"  [{key}] {desc}")
        
        frequency_choice = Prompt.ask(
            "Select sync frequency",
            choices=[key for key, _ in frequency_options],
            default=current_preset or "custom",
            console=self.console
        )
        
        if frequency_choice == "custom":
            new_frequency = int(Prompt.ask(
                "Enter frequency in seconds",
                default=str(current_frequency),
                console=self.console
            ))
            self.config_manager.set_sync_frequency(new_frequency)
        else:
            self.config_manager.set_sync_frequency_preset(frequency_choice)
        
        # Ask for auto commit
        current_auto_commit = config["sync"]["auto_commit"]
        new_auto_commit = Confirm.ask(
            "Enable automatic commits",
            default=current_auto_commit,
            console=self.console
        )
        
        if new_auto_commit != current_auto_commit:
            self.config_manager.set_auto_commit(new_auto_commit)
        
        # Ask for commit message template
        current_template = config["sync"]["commit_message_template"]
        new_template = Prompt.ask(
            "Commit message template",
            default=current_template,
            console=self.console
        )
        
        if new_template != current_template:
            self.config_manager.set_commit_message_template(new_template)
        
        self.console.print("Sync configuration updated", style="bold green")
    
    def configure_notifications(self) -> None:
        """Configure notification settings."""
        self.display_header("Notification Configuration")
        
        # Get current config
        config = self.config_manager.get_config()
        
        # Ask for notification level
        current_level = config["notifications"]["level"]
        level_options = [
            ("all", "All notifications (sync success and errors)"),
            ("errors_only", "Errors only (recommended)"),
            ("none", "No notifications")
        ]
        
        self.console.print("Notification Level:")
        for key, desc in level_options:
            selected = "✓ " if key == current_level else "  "
            self.console.print(f"  [{key}] {selected}{desc}")
        
        new_level = Prompt.ask(
            "Select notification level",
            choices=[key for key, _ in level_options],
            default=current_level,
            console=self.console
        )
        
        if new_level != current_level:
            self.config_manager.set_notification_level(new_level)
        
        # Ask for notification method
        current_method = config["notifications"]["method"]
        method_options = [
            ("terminal-notifier", "terminal-notifier (recommended)"),
            ("applescript", "AppleScript (fallback)")
        ]
        
        self.console.print("Notification Method:")
        for key, desc in method_options:
            selected = "✓ " if key == current_method else "  "
            self.console.print(f"  [{key}] {selected}{desc}")
        
        new_method = Prompt.ask(
            "Select notification method",
            choices=[key for key, _ in method_options],
            default=current_method,
            console=self.console
        )
        
        if new_method != current_method:
            self.config_manager.set_notification_method(new_method)
        
        self.console.print("Notification configuration updated", style="bold green")
    
    def configure_utilities(self) -> None:
        """Configure utility settings."""
        self.display_header("Utilities Configuration")
        
        # Get current config
        config = self.config_manager.get_config()
        
        # Display utilities table
        util_table = Table(show_header=True)
        util_table.add_column("#", style="bold")
        util_table.add_column("Utility", style="bold")
        util_table.add_column("Enabled")
        util_table.add_column("Paths")
        
        utilities = list(config["utilities"].keys())
        for i, utility in enumerate(utilities):
            util_config = config["utilities"][utility]
            enabled = "✓" if util_config.get("enabled", False) else "✗"
            paths = len(util_config.get("paths", []))
            util_table.add_row(str(i+1), utility, enabled, str(paths))
        
        self.console.print(util_table)
        
        # Options
        options = [
            ("toggle", "Toggle utility enabled/disabled"),
            ("paths", "Configure utility paths"),
            ("exclude", "Configure exclude patterns"),
            ("detect", "Detect installed utilities"),
            ("back", "Back to main menu")
        ]
        
        choice = self.display_menu(options)
        
        if choice == "toggle":
            # Toggle utility enabled/disabled
            utility_num = int(Prompt.ask(
                "Enter utility number to toggle",
                console=self.console
            ))
            
            if 1 <= utility_num <= len(utilities):
                utility = utilities[utility_num - 1]
                current_enabled = config["utilities"][utility].get("enabled", False)
                self.config_manager.enable_utility(utility, not current_enabled)
                
                status = "enabled" if not current_enabled else "disabled"
                self.console.print(f"Utility {utility} {status}", style="bold green")
            else:
                self.console.print("Invalid utility number", style="bold red")
            
            # Recurse to stay in utilities menu
            self.configure_utilities()
        
        elif choice == "paths":
            # Configure utility paths
            utility_num = int(Prompt.ask(
                "Enter utility number to configure paths",
                console=self.console
            ))
            
            if 1 <= utility_num <= len(utilities):
                utility = utilities[utility_num - 1]
                self._configure_utility_paths(utility)
            else:
                self.console.print("Invalid utility number", style="bold red")
            
            # Recurse to stay in utilities menu
            self.configure_utilities()
        
        elif choice == "exclude":
            # Configure exclude patterns
            utility_num = int(Prompt.ask(
                "Enter utility number to configure exclude patterns",
                console=self.console
            ))
            
            if 1 <= utility_num <= len(utilities):
                utility = utilities[utility_num - 1]
                self._configure_utility_exclude_patterns(utility)
            else:
                self.console.print("Invalid utility number", style="bold red")
            
            # Recurse to stay in utilities menu
            self.configure_utilities()
        
        elif choice == "detect":
            # Detect installed utilities
            with Progress(
                SpinnerColumn(),
                TextColumn("[bold blue]{task.description}"),
                BarColumn(),
                TimeElapsedColumn(),
                console=self.console
            ) as progress:
                task = progress.add_task("Detecting installed utilities...", total=1)
                
                installed = self.config_manager.detect_installed_utilities()
                
                # Enable detected utilities
                for utility in installed:
                    self.config_manager.enable_utility(utility, True)
                
                progress.update(task, completed=1)
            
            self.console.print(f"Detected and enabled {len(installed)} utilities", style="bold green")
            
            # Recurse to stay in utilities menu
            self.configure_utilities()
    
    def _configure_utility_paths(self, utility: str) -> None:
        """
        Configure paths for a specific utility.
        
        Args:
            utility: Utility name
        """
        util_config = self.config_manager.get_utility_config(utility)
        if not util_config:
            self.console.print(f"Utility {utility} not found", style="bold red")
            return
        
        self.display_header(f"Configure Paths for {utility}")
        
        # Display current paths
        paths = util_config.get("paths", [])
        
        path_table = Table(show_header=True)
        path_table.add_column("#", style="bold")
        path_table.add_column("Path", style="bold")
        
        for i, path in enumerate(paths):
            path_table.add_row(str(i+1), path)
        
        self.console.print(path_table)
        
        # Options
        options = [
            ("add", "Add a new path"),
            ("remove", "Remove a path"),
            ("back", "Back to utilities menu")
        ]
        
        choice = self.display_menu(options)
        
        if choice == "add":
            # Add a new path
            new_path = Prompt.ask(
                "Enter new path (use ~ for home directory)",
                console=self.console
            )
            
            self.config_manager.add_utility_path(utility, new_path)
            self.console.print(f"Path added to {utility}", style="bold green")
            
            # Recurse to stay in paths menu
            self._configure_utility_paths(utility)
        
        elif choice == "remove":
            # Remove a path
            if not paths:
                self.console.print("No paths to remove", style="bold yellow")
                self._configure_utility_paths(utility)
                return
            
            path_num = int(Prompt.ask(
                "Enter path number to remove",
                console=self.console
            ))
            
            if 1 <= path_num <= len(paths):
                path = paths[path_num - 1]
                self.config_manager.remove_utility_path(utility, path)
                self.console.print(f"Path removed from {utility}", style="bold green")
            else:
                self.console.print("Invalid path number", style="bold red")
            
            # Recurse to stay in paths menu
            self._configure_utility_paths(utility)
    
    def _configure_utility_exclude_patterns(self, utility: str) -> None:
        """
        Configure exclude patterns for a specific utility.
        
        Args:
            utility: Utility name
        """
        util_config = self.config_manager.get_utility_config(utility)
        if not util_config:
            self.console.print(f"Utility {utility} not found", style="bold red")
            return
        
        self.display_header(f"Configure Exclude Patterns for {utility}")
        
        # Display current patterns
        patterns = util_config.get("exclude_patterns", [])
        
        pattern_table = Table(show_header=True)
        pattern_table.add_column("#", style="bold")
        pattern_table.add_column("Pattern", style="bold")
        
        for i, pattern in enumerate(patterns):
            pattern_table.add_row(str(i+1), pattern)
        
        self.console.print(pattern_table)
        
        # Options
        options = [
            ("add", "Add a new pattern"),
            ("remove", "Remove a pattern"),
            ("back", "Back to utilities menu")
        ]
        
        choice = self.display_menu(options)
        
        if choice == "add":
            # Add a new pattern
            new_pattern = Prompt.ask(
                "Enter new exclude pattern (e.g. *.log, Cache/*)",
                console=self.console
            )
            
            self.config_manager.add_utility_exclude_pattern(utility, new_pattern)
            self.console.print(f"Pattern added to {utility}", style="bold green")
            
            # Recurse to stay in patterns menu
            self._configure_utility_exclude_patterns(utility)
        
        elif choice == "remove":
            # Remove a pattern
            if not patterns:
                self.console.print("No patterns to remove", style="bold yellow")
                self._configure_utility_exclude_patterns(utility)
                return
            
            pattern_num = int(Prompt.ask(
                "Enter pattern number to remove",
                console=self.console
            ))
            
            if 1 <= pattern_num <= len(patterns):
                pattern = patterns[pattern_num - 1]
                self.config_manager.remove_utility_exclude_pattern(utility, pattern)
                self.console.print(f"Pattern removed from {utility}", style="bold green")
            else:
                self.console.print("Invalid pattern number", style="bold red")
            
            # Recurse to stay in patterns menu
            self._configure_utility_exclude_patterns(utility)
    
    def reset_configuration(self) -> None:
        """Reset configuration to defaults."""
        confirm = Confirm.ask(
            "Are you sure you want to reset all configuration to defaults?",
            default=False,
            console=self.console
        )
        
        if confirm:
            self.config_manager.reset_to_defaults()
            self.console.print("Configuration reset to defaults", style="bold green")
    
    def main_menu(self) -> None:
        """Display the main configuration menu."""
        while True:
            self.display_header("Mac Sync Wizard Configuration")
            
            # Display current configuration summary
            self.display_config_summary()
            
            # Options
            options = [
                ("repo", "Configure repository"),
                ("sync", "Configure sync settings"),
                ("notif", "Configure notifications"),
                ("utils", "Configure utilities"),
                ("reset", "Reset to defaults"),
                ("save", "Save and exit"),
                ("exit", "Exit without saving")
            ]
            
            choice = self.display_menu(options)
            
            if choice == "repo":
                self.configure_repository()
            elif choice == "sync":
                self.configure_sync()
            elif choice == "notif":
                self.configure_notifications()
            elif choice == "utils":
                self.configure_utilities()
            elif choice == "reset":
                self.reset_configuration()
            elif choice == "save":
                self.config_manager.save_config()
                self.console.print("Configuration saved", style="bold green")
                break
            elif choice == "exit":
                confirm = Confirm.ask(
                    "Are you sure you want to exit without saving?",
                    default=False,
                    console=self.console
                )
                
                if confirm:
                    break


def main():
    """Main entry point for the configuration UI."""
    config_ui = ConfigUI()
    config_ui.main_menu()


if __name__ == "__main__":
    main()
```

## Key Features

1. **Comprehensive Configuration Options**
   - Repository settings (URL, branch, authentication)
   - Sync frequency with presets (15 minutes to weekly)
   - Notification preferences (all, errors only, none)
   - Per-utility settings (enabled/disabled, paths, exclude patterns)

2. **User-Friendly Terminal UI**
   - Clear visual components with borders and colors
   - Intuitive navigation with keyboard shortcuts
   - Comprehensive help text
   - Visual feedback for actions

3. **Utility Management**
   - Automatic detection of installed utilities
   - Customizable paths for each utility
   - Exclude patterns to skip certain files
   - Enable/disable individual utilities

4. **Persistence**
   - Configuration stored in JSON format
   - Changes applied immediately
   - Reset to defaults option

5. **Integration with Background Sync**
   - Sync frequency changes update LaunchAgent
   - Configuration changes take effect without restart

## Usage Examples

### Accessing Configuration UI
```bash
mac-sync-wizard config
```

### Setting Sync Frequency via Command Line
```bash
mac-sync-wizard config --frequency 3600  # 1 hour
```

### Enabling/Disabling a Utility via Command Line
```bash
mac-sync-wizard config --enable cursor
mac-sync-wizard config --disable pycharm
```

### Resetting to Defaults
```bash
mac-sync-wizard config --reset
```
