# Git Sync Implementation Design

This document outlines the implementation details for the Git synchronization functionality of the Mac Sync Wizard.

## Core Components

### 1. Repository Management
- Initialize new repository
- Connect to existing repository
- Handle authentication (SSH keys, personal access tokens)
- Manage remote operations (push, pull, fetch)

### 2. File Synchronization
- Detect changes in configuration files
- Handle file conflicts
- Implement selective sync for large files
- Manage file permissions

### 3. Background Sync Service
- Run as a launchd service on macOS
- Implement configurable sync frequency
- Handle network interruptions
- Provide non-disruptive operation

## Implementation Details

### Repository Structure
```
mac-sync/
├── config/
│   └── sync_config.json       # User configuration
├── backups/                   # Organized by utility
│   ├── cursor/
│   ├── pycharm/
│   ├── sublime/
│   ├── trackpad/
│   ├── git/
│   ├── arc/
│   ├── warp/
│   ├── fonts/
│   ├── anki/
│   ├── logi/
│   ├── 1password/
│   ├── stretchly/
│   └── maccy/
├── scripts/                   # Setup and utility scripts
│   ├── setup.sh
│   ├── backup.sh
│   ├── restore.sh
│   └── utils/
│       ├── cursor.sh
│       ├── pycharm.sh
│       └── ...
└── logs/                      # Sync and error logs
```

### Sync Configuration (sync_config.json)
```json
{
  "repository": {
    "url": "https://github.com/username/mac-sync.git",
    "branch": "main",
    "auth_type": "ssh"
  },
  "sync": {
    "frequency": 21600,  // seconds (6 hours)
    "auto_commit": true,
    "commit_message_template": "Auto-sync: {date} - {changes}"
  },
  "notifications": {
    "level": "errors_only",  // all, errors_only, none
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
    "pycharm": {
      "enabled": true,
      "paths": [
        "~/Library/Preferences/PyCharm*/keymaps/",
        "~/Library/Preferences/PyCharm*/options/"
      ],
      "exclude_patterns": ["*.log", "Cache/*"]
    },
    // Additional utilities configuration...
  }
}
```

### Git Operations Module

```python
class GitSync:
    def __init__(self, config_path):
        self.config = self._load_config(config_path)
        self.repo_path = os.path.expanduser("~/.mac-sync-repo")
    
    def _load_config(self, config_path):
        with open(config_path, 'r') as f:
            return json.load(f)
    
    def init_repository(self):
        """Initialize a new repository or connect to existing one"""
        if os.path.exists(self.repo_path):
            return self._connect_existing_repo()
        else:
            return self._create_new_repo()
    
    def _create_new_repo(self):
        """Create a new repository and set remote"""
        os.makedirs(self.repo_path, exist_ok=True)
        subprocess.run(['git', 'init'], cwd=self.repo_path)
        subprocess.run(['git', 'remote', 'add', 'origin', self.config['repository']['url']], 
                      cwd=self.repo_path)
        # Create initial structure
        for dir_name in ['backups', 'config', 'scripts', 'logs']:
            os.makedirs(os.path.join(self.repo_path, dir_name), exist_ok=True)
        # Create initial commit
        subprocess.run(['git', 'add', '.'], cwd=self.repo_path)
        subprocess.run(['git', 'commit', '-m', 'Initial commit'], cwd=self.repo_path)
        return True
    
    def _connect_existing_repo(self):
        """Connect to existing repository"""
        try:
            subprocess.run(['git', 'fetch'], cwd=self.repo_path)
            return True
        except Exception as e:
            return False
    
    def backup_utility(self, utility_name):
        """Backup a specific utility's configuration"""
        utility_config = self.config['utilities'].get(utility_name)
        if not utility_config or not utility_config.get('enabled'):
            return False
        
        backup_path = os.path.join(self.repo_path, 'backups', utility_name)
        os.makedirs(backup_path, exist_ok=True)
        
        # Copy files to backup directory
        for path in utility_config['paths']:
            expanded_path = os.path.expanduser(path)
            if os.path.exists(expanded_path):
                if os.path.isdir(expanded_path):
                    # Copy directory contents
                    dest_dir = os.path.join(backup_path, os.path.basename(expanded_path))
                    shutil.copytree(expanded_path, dest_dir, dirs_exist_ok=True)
                else:
                    # Copy file
                    shutil.copy2(expanded_path, backup_path)
        
        return True
    
    def restore_utility(self, utility_name):
        """Restore a specific utility's configuration"""
        utility_config = self.config['utilities'].get(utility_name)
        if not utility_config or not utility_config.get('enabled'):
            return False
        
        backup_path = os.path.join(self.repo_path, 'backups', utility_name)
        if not os.path.exists(backup_path):
            return False
        
        # For each path in the utility config, restore from backup
        for path in utility_config['paths']:
            expanded_path = os.path.expanduser(path)
            source_path = os.path.join(backup_path, os.path.basename(path))
            
            if os.path.exists(source_path):
                # Create parent directory if it doesn't exist
                os.makedirs(os.path.dirname(expanded_path), exist_ok=True)
                
                if os.path.isdir(source_path):
                    # Copy directory contents
                    shutil.copytree(source_path, expanded_path, dirs_exist_ok=True)
                else:
                    # Copy file
                    shutil.copy2(source_path, expanded_path)
        
        return True
    
    def commit_changes(self, message=None):
        """Commit changes to the repository"""
        if not message:
            template = self.config['sync']['commit_message_template']
            message = template.format(
                date=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                changes="Automated sync"
            )
        
        try:
            # Add all changes
            subprocess.run(['git', 'add', '.'], cwd=self.repo_path)
            # Check if there are changes to commit
            result = subprocess.run(['git', 'status', '--porcelain'], 
                                   cwd=self.repo_path, capture_output=True, text=True)
            if result.stdout.strip():
                # Commit changes
                subprocess.run(['git', 'commit', '-m', message], cwd=self.repo_path)
                return True
            return False  # No changes to commit
        except Exception as e:
            return False
    
    def push_changes(self):
        """Push changes to remote repository"""
        try:
            subprocess.run(['git', 'push', 'origin', self.config['repository']['branch']], 
                          cwd=self.repo_path)
            return True
        except Exception as e:
            return False
    
    def pull_changes(self):
        """Pull changes from remote repository"""
        try:
            subprocess.run(['git', 'pull', 'origin', self.config['repository']['branch']], 
                          cwd=self.repo_path)
            return True
        except Exception as e:
            return False
```

### Background Sync Service

#### LaunchAgent Configuration (com.mac-sync-wizard.sync.plist)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.mac-sync-wizard.sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/usr/local/bin/mac-sync-wizard</string>
        <string>sync</string>
        <string>--background</string>
    </array>
    <key>StartInterval</key>
    <integer>21600</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>~/.mac-sync-wizard/logs/error.log</string>
    <key>StandardOutPath</key>
    <string>~/.mac-sync-wizard/logs/sync.log</string>
</dict>
</plist>
```

#### Background Sync Implementation
```python
class BackgroundSync:
    def __init__(self, config_path):
        self.config_path = config_path
        self.git_sync = GitSync(config_path)
        self.logger = self._setup_logger()
    
    def _setup_logger(self):
        """Configure logging"""
        logger = logging.getLogger('mac-sync-wizard')
        logger.setLevel(logging.INFO)
        
        log_dir = os.path.expanduser('~/.mac-sync-wizard/logs')
        os.makedirs(log_dir, exist_ok=True)
        
        file_handler = logging.FileHandler(os.path.join(log_dir, 'sync.log'))
        file_handler.setLevel(logging.INFO)
        
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        file_handler.setFormatter(formatter)
        
        logger.addHandler(file_handler)
        return logger
    
    def run_sync(self):
        """Run a complete sync operation"""
        self.logger.info("Starting background sync")
        
        try:
            # Pull latest changes
            if not self.git_sync.pull_changes():
                self.logger.error("Failed to pull changes from remote repository")
                self._send_notification("Sync Error", "Failed to pull changes from repository")
                return False
            
            # Backup all enabled utilities
            for utility in self.git_sync.config['utilities']:
                if self.git_sync.config['utilities'][utility]['enabled']:
                    self.logger.info(f"Backing up {utility}")
                    if not self.git_sync.backup_utility(utility):
                        self.logger.warning(f"Failed to backup {utility}")
            
            # Commit and push changes
            if self.git_sync.commit_changes():
                if not self.git_sync.push_changes():
                    self.logger.error("Failed to push changes to remote repository")
                    self._send_notification("Sync Error", "Failed to push changes to repository")
                    return False
            
            self.logger.info("Background sync completed successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Background sync failed: {str(e)}")
            self._send_notification("Sync Error", f"Background sync failed: {str(e)}")
            return False
    
    def _send_notification(self, title, message):
        """Send system notification based on configuration"""
        notification_level = self.git_sync.config['notifications']['level']
        
        if notification_level == 'none':
            return
        
        if notification_level == 'errors_only' and not title.startswith('Sync Error'):
            return
        
        # Use terminal-notifier if available
        try:
            subprocess.run([
                'terminal-notifier',
                '-title', 'Mac Sync Wizard',
                '-subtitle', title,
                '-message', message,
                '-group', 'mac-sync-wizard'
            ])
        except:
            # Fallback to applescript
            apple_script = f'display notification "{message}" with title "Mac Sync Wizard" subtitle "{title}"'
            subprocess.run(['osascript', '-e', apple_script])
    
    def update_sync_frequency(self, seconds):
        """Update the sync frequency in the LaunchAgent plist"""
        plist_path = os.path.expanduser('~/Library/LaunchAgents/com.mac-sync-wizard.sync.plist')
        
        if not os.path.exists(plist_path):
            return False
        
        try:
            # Load the plist
            with open(plist_path, 'rb') as f:
                plist = plistlib.load(f)
            
            # Update the interval
            plist['StartInterval'] = seconds
            
            # Write back the plist
            with open(plist_path, 'wb') as f:
                plistlib.dump(plist, f)
            
            # Reload the LaunchAgent
            subprocess.run(['launchctl', 'unload', plist_path])
            subprocess.run(['launchctl', 'load', plist_path])
            
            return True
        except Exception as e:
            self.logger.error(f"Failed to update sync frequency: {str(e)}")
            return False
```

## Error Handling Strategy

### Retry Mechanism
- Implement exponential backoff for network operations
- Set maximum retry attempts for critical operations
- Log all retry attempts and outcomes

### Conflict Resolution
- Detect conflicts during pull operations
- Provide options for resolving conflicts:
  - Use local version
  - Use remote version
  - Merge changes (when possible)
  - Manual resolution

### Transaction Safety
- Implement atomic operations where possible
- Create backups before destructive operations
- Provide rollback capabilities for failed operations

## Security Considerations

### Sensitive Data Handling
- Exclude sensitive files from sync (SSH keys, API tokens)
- Provide option for encrypting sensitive data
- Support for private repositories

### Authentication
- Support for SSH keys
- Support for personal access tokens
- Secure storage of credentials using macOS Keychain

## Implementation Plan

1. Implement core Git operations module
2. Create utility-specific backup/restore scripts
3. Implement background sync service
4. Create LaunchAgent configuration
5. Implement notification system
6. Add security features
7. Test with various repository configurations
8. Document API and usage
