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
            s
(Content truncated due to size limit. Use line ranges to read in chunks)