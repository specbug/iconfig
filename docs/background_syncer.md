# Background Auto Syncer Implementation

This module implements the background synchronization service for Mac Sync Wizard, ensuring non-disruptive operation with robust error handling.

```python
#!/usr/bin/env python3

import os
import sys
import json
import time
import logging
import argparse
import subprocess
import shutil
import plistlib
from datetime import datetime, timedelta
import traceback
import signal
import threading
from pathlib import Path

class BackgroundSyncer:
    """
    Background synchronization service for Mac Sync Wizard.
    Handles automatic syncing of user configurations to Git repository.
    """
    
    def __init__(self, config_path=None):
        """
        Initialize the background syncer with configuration.
        
        Args:
            config_path: Path to the configuration file
        """
        self.home_dir = os.path.expanduser("~")
        self.app_dir = os.path.join(self.home_dir, ".mac-sync-wizard")
        
        # Default config path if not provided
        if not config_path:
            config_path = os.path.join(self.app_dir, "config", "sync_config.json")
        
        self.config_path = config_path
        self.config = self._load_config()
        self.repo_path = os.path.join(self.app_dir, "repo")
        self.lock_file = os.path.join(self.app_dir, "sync.lock")
        self.last_sync_file = os.path.join(self.app_dir, "last_sync")
        
        # Setup logging
        self.logger = self._setup_logger()
        
        # Initialize sync state
        self.is_syncing = False
        self.sync_thread = None
        self.stop_requested = False
        
        # Register signal handlers
        signal.signal(signal.SIGINT, self._handle_signal)
        signal.signal(signal.SIGTERM, self._handle_signal)
    
    def _setup_logger(self):
        """Configure logging for the background syncer"""
        logger = logging.getLogger('mac-sync-wizard')
        logger.setLevel(logging.INFO)
        
        # Create logs directory if it doesn't exist
        log_dir = os.path.join(self.app_dir, "logs")
        os.makedirs(log_dir, exist_ok=True)
        
        # Create file handler
        log_file = os.path.join(log_dir, "background_sync.log")
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.INFO)
        
        # Create formatter and add it to the handler
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        file_handler.setFormatter(formatter)
        
        # Add handler to logger
        logger.addHandler(file_handler)
        
        # Add console handler for debugging
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)
        
        return logger
    
    def _load_config(self):
        """Load configuration from file"""
        try:
            if os.path.exists(self.config_path):
                with open(self.config_path, 'r') as f:
                    return json.load(f)
            else:
                # Return default configuration
                return {
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
                        "level": "errors_only",
                        "method": "terminal-notifier"
                    },
                    "utilities": {}
                }
        except Exception as e:
            # If there's an error loading the config, return default
            print(f"Error loading config: {str(e)}")
            return {
                "sync": {"frequency": 21600, "auto_commit": True},
                "notifications": {"level": "errors_only"},
                "utilities": {}
            }
    
    def _save_config(self):
        """Save configuration to file"""
        try:
            os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
            with open(self.config_path, 'w') as f:
                json.dump(self.config, f, indent=2)
            return True
        except Exception as e:
            self.logger.error(f"Failed to save config: {str(e)}")
            return False
    
    def _acquire_lock(self):
        """Acquire lock to prevent multiple sync processes"""
        if os.path.exists(self.lock_file):
            # Check if the lock is stale (older than 1 hour)
            lock_time = os.path.getmtime(self.lock_file)
            if time.time() - lock_time > 3600:  # 1 hour in seconds
                self.logger.warning("Removing stale lock file")
                os.remove(self.lock_file)
            else:
                self.logger.info("Another sync process is running")
                return False
        
        # Create lock file
        try:
            with open(self.lock_file, 'w') as f:
                f.write(str(os.getpid()))
            return True
        except Exception as e:
            self.logger.error(f"Failed to create lock file: {str(e)}")
            return False
    
    def _release_lock(self):
        """Release sync lock"""
        if os.path.exists(self.lock_file):
            try:
                os.remove(self.lock_file)
                return True
            except Exception as e:
                self.logger.error(f"Failed to remove lock file: {str(e)}")
                return False
        return True
    
    def _update_last_sync_time(self):
        """Update the last sync time file"""
        try:
            with open(self.last_sync_file, 'w') as f:
                f.write(datetime.now().isoformat())
            return True
        except Exception as e:
            self.logger.error(f"Failed to update last sync time: {str(e)}")
            return False
    
    def _get_last_sync_time(self):
        """Get the last sync time"""
        if os.path.exists(self.last_sync_file):
            try:
                with open(self.last_sync_file, 'r') as f:
                    return datetime.fromisoformat(f.read().strip())
            except Exception as e:
                self.logger.error(f"Failed to read last sync time: {str(e)}")
        return None
    
    def _handle_signal(self, signum, frame):
        """Handle termination signals"""
        self.logger.info(f"Received signal {signum}, shutting down gracefully")
        self.stop_requested = True
        if self.sync_thread and self.sync_thread.is_alive():
            self.logger.info("Waiting for sync thread to complete...")
            self.sync_thread.join(timeout=30)
        self._release_lock()
        sys.exit(0)
    
    def _send_notification(self, title, message):
        """Send system notification based on configuration"""
        notification_level = self.config['notifications']['level']
        
        if notification_level == 'none':
            return
        
        if notification_level == 'errors_only' and not title.startswith('Error'):
            return
        
        self.logger.info(f"Sending notification: {title} - {message}")
        
        # Use terminal-notifier if available
        try:
            subprocess.run([
                'terminal-notifier',
                '-title', 'Mac Sync Wizard',
                '-subtitle', title,
                '-message', message,
                '-group', 'mac-sync-wizard'
            ], check=False)
        except:
            # Fallback to applescript
            try:
                apple_script = f'display notification "{message}" with title "Mac Sync Wizard" subtitle "{title}"'
                subprocess.run(['osascript', '-e', apple_script], check=False)
            except Exception as e:
                self.logger.error(f"Failed to send notification: {str(e)}")
    
    def _run_git_command(self, command, retry=3, backoff=2):
        """
        Run git command with retry logic
        
        Args:
            command: List of command arguments
            retry: Number of retry attempts
            backoff: Backoff multiplier for retry delay
        
        Returns:
            Tuple of (success, output)
        """
        attempt = 0
        delay = 1
        
        while attempt < retry:
            try:
                result = subprocess.run(
                    ['git'] + command,
                    cwd=self.repo_path,
                    capture_output=True,
                    text=True,
                    check=True
                )
                return True, result.stdout.strip()
            except subprocess.CalledProcessError as e:
                attempt += 1
                self.logger.warning(f"Git command failed (attempt {attempt}/{retry}): {e}")
                self.logger.warning(f"Error output: {e.stderr}")
                
                if attempt >= retry:
                    return False, e.stderr
                
                # Exponential backoff
                time.sleep(delay)
                delay *= backoff
            except Exception as e:
                self.logger.error(f"Unexpected error running git command: {str(e)}")
                return False, str(e)
    
    def _ensure_repository(self):
        """Ensure the Git repository exists and is properly configured"""
        # Check if repo directory exists
        if not os.path.exists(self.repo_path):
            self.logger.info("Repository directory does not exist, creating...")
            os.makedirs(self.repo_path, exist_ok=True)
            
            # Initialize new repository
            success, output = self._run_git_command(['init'])
            if not success:
                self.logger.error(f"Failed to initialize repository: {output}")
                return False
            
            # Configure repository
            if self.config['repository']['url']:
                success, output = self._run_git_command(['remote', 'add', 'origin', self.config['repository']['url']])
                if not success:
                    self.logger.error(f"Failed to add remote: {output}")
                    return False
        
        # Check if .git directory exists
        if not os.path.exists(os.path.join(self.repo_path, '.git')):
            self.logger.error("Repository is not a Git repository")
            return False
        
        # Check remote configuration
        if self.config['repository']['url']:
            success, output = self._run_git_command(['remote', 'get-url', 'origin'])
            if not success or output != self.config['repository']['url']:
                # Update remote URL
                success, output = self._run_git_command(['remote', 'set-url', 'origin', self.config['repository']['url']])
                if not success:
                    self.logger.error(f"Failed to update remote URL: {output}")
                    return False
        
        return True
    
    def _backup_utility(self, utility_name):
        """
        Backup a specific utility's configuration
        
        Args:
            utility_name: Name of the utility to backup
        
        Returns:
            Boolean indicating success
        """
        utility_config = self.config['utilities'].get(utility_name)
        if not utility_config or not utility_config.get('enabled', False):
            self.logger.info(f"Utility {utility_name} is not enabled for sync")
            return True  # Not an error, just skipped
        
        self.logger.info(f"Backing up {utility_name}")
        
        backup_path = os.path.join(self.repo_path, 'backups', utility_name)
        os.makedirs(backup_path, exist_ok=True)
        
        success = True
        files_copied = 0
        
        # Copy files to backup directory
        for path_pattern in utility_config.get('paths', []):
            expanded_path = os.path.expanduser(path_pattern)
            
            # Handle glob patterns
            for path in Path(os.path.dirname(expanded_path)).glob(os.path.basename(expanded_path)):
                if not path.exists():
                    self.logger.warning(f"Path does not exist: {path}")
                    continue
                
                # Check exclude patterns
                skip = False
                for exclude in utility_config.get('exclude_patterns', []):
                    if path.match(exclude):
                        self.logger.info(f"Skipping excluded path: {path}")
                        skip = True
                        break
                
                if skip:
                    continue
                
                try:
                    dest_path = os.path.join(backup_path, path.name)
                    
                    if path.is_dir():
                        # Copy directory contents
                        if os.path.exists(dest_path):
                            shutil.rmtree(dest_path)
                        shutil.copytree(path, dest_path)
                    else:
                        # Copy file
                        shutil.copy2(path, backup_path)
                    
                    files_copied += 1
                    self.logger.debug(f"Copied {path} to {dest_path}")
                except Exception as e:
                    self.logger.error(f"Failed to backup {path}: {str(e)}")
                    success = False
        
        if files_copied == 0:
            self.logger.warning(f"No files were copied for {utility_name}")
            return True  # Not an error, just no files found
        
        return success
    
    def _restore_utility(self, utility_name):
        """
        Restore a specific utility's configuration
        
        Args:
            utility_name: Name of the utility to restore
        
        Returns:
            Boolean indicating success
        """
        utility_config = self.config['utilities'].get(utility_name)
        if not utility_config or not utility_config.get('enabled', False):
            self.logger.info(f"Utility {utility_name} is not enabled for sync")
            return True  # Not an error, just skipped
        
        self.logger.info(f"Restoring {utility_name}")
        
        backup_path = os.path.join(self.repo_path, 'backups', utility_name)
        if not os.path.exists(backup_path):
            self.logger.warning(f"No backup found for {utility_name}")
            return False
        
        success = True
        files_restored = 0
        
        # For each path in the utility config, restore from backup
        for path_pattern in utility_config.get('paths', []):
            expanded_path = os.path.expanduser(path_pattern)
            
            # Get the base directory
            base_dir = os.path.dirname(expanded_path)
            
            # Create parent directory if it doesn't exist
            os.makedirs(base_dir, exist_ok=True)
            
            # Find matching files in backup
            for backup_file in os.listdir(backup_path):
                backup_file_path = os.path.join(backup_path, backup_file)
                
                # Determine destination path
                if '*' in path_pattern:
                    # For glob patterns, use the same name as the backup file
                    dest_path = os.path.join(base_dir, backup_file)
                else:
                    # For exact paths, use the specified path
                    dest_path = expanded_path
                
                try:
                    if os.path.isdir(backup_file_path):
                        # Copy directory contents
                        if os.path.exists(dest_path):
                            shutil.rmtree(dest_path)
                        shutil.copytree(backup_file_path, dest_path)
                    else:
                        # Copy file
                        shutil.copy2(backup_file_path, dest_path)
                    
                    files_restored += 1
                    self.logger.debug(f"Restored {backup_file_path} to {dest_path}")
                except Exception as e:
                    self.logger.error(f"Failed to restore {backup_file_path}: {str(e)}")
                    success = False
        
        if files_restored == 0:
            self.logger.warning(f"No files were restored for {utility_name}")
            return True  # Not an error, just no files found
        
        return success
    
    def _commit_changes(self):
        """Commit changes to the repository"""
        if not self.config['sync'].get('auto_commit', True):
            self.logger.info("Auto-commit is disabled, skipping commit")
            return True
        
        self.logger.info("Committing changes to repository")
        
        # Add all changes
        success, output = self._run_git_command(['add', '.'])
        if not success:
            self.logger.error(f"Failed to add changes: {output}")
            return False
        
        # Check if there are changes to commit
        success, output = self._run_git_command(['status', '--porcelain'])
        if not success:
            self.logger.error(f"Failed to check status: {output}")
            return False
        
        if not output:
            self.logger.info("No changes to commit")
            return True
        
        # Generate commit message
        template = self.config['sync'].get('commit_message_template', "Auto-sync: {date} - {changes}")
        message = template.format(
            date=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            changes=f"{len(output.splitlines())} files changed"
        )
        
        # Commit changes
        success, output = self._run_git_command(['commit', '-m', message])
        if not success:
            self.logger.error(f"Failed to commit changes: {output}")
            return False
        
        self.logger.info(f"Changes committed: {message}")
        return True
    
    def _push_changes(self):
        """Push changes to remote repository"""
        if not self.config['repository'].get('url'):
            self.logger.info("No remote repository configured, skipping push")
            return True
        
        self.logger.info("Pushing changes to remote repository")
        
        branch = self.config['repository'].get('branch', 'main')
        success, output = self._run_git_command(['push', 'origin', branch])
        if not success:
            self.logger.error(f"Failed to push changes: {output}")
            return False
        
        self.logger.info("Changes pushed to remote repository")
        return True
    
    def _pull_changes(self):
        """Pull changes from remote repository"""
        if not self.config['repository'].get('url'):
            self.logger.info("No remote repository configured, skipping pull")
            return True
        
        self.logger.info("Pulling changes from remote repository")
        
        branch = self.config['repository'].get('branch', 'main')
        success, output = self._run_git_command(['pull', 'origin', branch])
        if not success:
            self.logger.error(f"Failed to pull changes: {output}")
            return False
        
        self.logger.info("Changes pulled from remote repository")
        return True
    
    def _sync_all_utilities(self):
        """Sync all enabled utilities"""
        success = True
        
        # Backup all enabled utilities
        for utility in self.config['utilities']:
            if self.stop_requested:
                self.logger.info("Stop requested, aborting sync")
                return False
            
            if not self._backup_utility(utility):
                self.logger.error(f"Failed to backup {utility}")
                success = False
        
        return success
    
    def _restore_all_utilities(self):
        """Restore all enabled utilities"""
        success = True
        
        # Restore all enabled utilities
        for utility in self.config['utilities']:
            if self.stop_requested:
                self.logger.info("Stop requested, aborting restore")
                return False
            
            if not self._restore_utility(utility):
                self.logger.error(f"Failed to restore {utility}")
                success = False
        
        return success
    
    def _perform_sync(self):
        """Perform a complete sync operation"""
        self.logger.info("Starting sync operation")
        
        if not self._acquire_lock():
            self.logger.warning("Could not acquire lock, another sync may be in progress")
            return False
        
        try:
            # Ensure repository is properly configured
            if not self._ensure_repository():
                self.logger.error("Failed to ensure repository")
                self._send_notification("Error", "Failed to configure Git repository")
                return False
            
            # Pull latest changes
            if not self._pull_changes():
                self.logger.error("Failed to pull changes")
                self._send_notification("Error", "Failed to pull changes from repository")
                return False
            
            # Sync all utilities
            if not self._sync_all_utilities():
                self.logger.error("Failed to sync all utilities")
                self._send_notification("Error", "Failed to sync one or more utilities")
                return False
            
            # Commit changes
            if not self._commit_changes():
                self.logger.error("Failed to commit changes")
                self._send_notification("Error", "Failed to commit changes to repository")
                return False
            
            # Push changes
            if not self._push_changes():
                self.logger.error("Failed to push changes")
                self._send_notification("Error", "Failed to push changes to repository")
                return False
            
            # Update last sync time
            self._update_last_sync_time()
            
            self.logger.info("Sync operation completed successfully")
            return True
        
        except Exception as e:
            self.logger.error(f"Sync operation failed: {str(e)}")
            self.logger.error(traceback.format_exc())
            self._send_notification("Error", f"Sync operation failed: {str(e)}")
            return False
        
        finally:
            self._release_lock()
    
    def sync_once(self):
        """Perform a single sync operation"""
        if self.is_syncing:
            self.logger.warning("Sync already in progress")
            return False
        
        self.is_syncing = True
        try:
            return self._perform_sync()
        finally:
            self.is_syncing = False
    
    def sync_in_background(self):
        """Start a background sync thread"""
        if self.is_syncing:
            self.logger.warning("Sync already in progress")
            return False
        
        self.sync_thread = threading.Thread(target=self._background_sync_thread)
        self.sync_thread.daemon = True
        self.sync_thread.start()
        
        return True
    
    def _background_sync_thread(self):
        """Background sync thread function"""
        self.is_syncing = True
        try:
            self._perform_sync()
        finally:
            self.is_syncing = False
    
    def start_daemon(self):
        """Start the background sync daemon"""
        self.logger.info("Starting background sync daemon")
        
        while not self.stop_requested:
            # Check if it's time to sync
            last_sync = self._get_last_sync_time()
            sync_frequency = self.config['sync'].get('frequency', 21600)  # Default: 6 hours
            
            if not last_sync or (datetime.now() - last_sync).total_seconds() >= sync_frequency:
                self.logger.info("Time for scheduled sync")
                self.sync_once()
            
            # Sleep for a minute before checking again
            for _ in range(60):
                if self.stop_requested:
                    break
                time.sleep(1)
        
        self.logger.info("Background sync daemon stopped")
    
    def install_launch_agent(self):
        """Install the LaunchAgent for automatic startup"""
        self.logger.info("Installing LaunchAgent")
        
        # LaunchAgent plist path
        plist_path = os.path.expanduser("~/Library/LaunchAgents/com.mac-sync-wizard.sync.plist")
        
        # Create LaunchAgent directory if it doesn't exist
        os.makedirs(os.path.dirname(plist_path), exist_ok=True)
        
        # Get the path to the mac-sync-wizard executable
        executable_path = os.path.join("/usr/local/bin", "mac-sync-wizard")
        
        # Create plist content
        plist_content = {
            "Label": "com.mac-sync-wizard.sync",
            "ProgramArguments": [
                "/usr/bin/python3",
                executable_path,
                "sync",
                "--daemon"
            ],
            "StartInterval": self.config['sync'].get('frequency', 21600),
            "RunAtLoad": True,
            "StandardErrorPath": os.path.join(self.app_dir, "logs", "daemon_error.log"),
            "StandardOutPath": os.path.join(self.app_dir, "logs", "daemon_output.log")
        }
        
        # Write plist file
        try:
            with open(plist_path, 'wb') as f:
                plistlib.dump(plist_content, f)
            
            # Set permissions
            os.chmod(plist_path, 0o644)
            
            # Load the LaunchAgent
            subprocess.run(['launchctl', 'unload', plist_path], check=False)
            subprocess.run(['launchctl', 'load', plist_path], check=True)
            
            self.logger.info("LaunchAgent installed successfully")
            return True
        
        except Exception as e:
            self.logger.error(f"Failed to install LaunchAgent: {str(e)}")
            return False
    
    def uninstall_launch_agent(self):
        """Uninstall the LaunchAgent"""
        self.logger.info("Uninstalling LaunchAgent")
        
        # LaunchAgent plist path
        plist_path = os.path.expanduser("~/Library/LaunchAgents/com.mac-sync-wizard.sync.plist")
        
        if not os.path.exists(plist_path):
            self.logger.info("LaunchAgent not installed")
            return True
        
        try:
            # Unload the LaunchAgent
            subprocess.run(['launchctl', 'unload', plist_path], check=True)
            
            # Remove the plist file
            os.remove(plist_path)
            
            self.logger.info("LaunchAgent uninstalled successfully")
            return True
        
        except Exception as e:
            self.logger.error(f"Failed to uninstall LaunchAgent: {str(e)}")
            return False
    
    def update_sync_frequency(self, seconds):
        """Update the sync frequency"""
        self.logger.info(f"Updating sync frequency to {seconds} seconds")
        
        # Update config
        self.config['sync']['frequency'] = seconds
        self._save_config()
        
        # Update LaunchAgent if installed
        plist_path = os.path.expanduser("~/Library/LaunchAgents/com.mac-sync-wizard.sync.plist")
        if os.path.exists(plist_path):
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
                subprocess.run(['launchctl', 'unload', plist_path], check=False)
                subprocess.run(['launchctl', 'load', plist_path], check=True)
                
                self.logger.info("LaunchAgent updated successfully")
                return True
            
            except Exception as e:
                self.logger.error(f"Failed to update LaunchAgent: {str(e)}")
                return False
        
        return True


def main():
    """Main entry point for the background syncer"""
    parser = argparse.ArgumentParser(description="Mac Sync Wizard Background Syncer")
    parser.add_argument("command", choices=["sync", "daemon", "install", "uninstall"],
                        help="Command to execute")
    parser.add_argument("--config", help="Path to configuration file")
    parser.add_argument("--daemon", action="store_true", help="Run as daemon")
    parser.add_argument("--frequency", type=int, help="Sync frequency in seconds")
    
    args = parser.parse_args()
    
    syncer = BackgroundSyncer(args.config)
    
    if args.command == "sync":
        if args.daemon:
            syncer.start_daemon()
        else:
            syncer.sync_once()
    
    elif args.command == "daemon":
        syncer.start_daemon()
    
    elif args.command == "install":
        syncer.install_launch_agent()
    
    elif args.command == "uninstall":
        syncer.uninstall_launch_agent()
    
    if args.frequency:
        syncer.update_sync_frequency(args.frequency)


if __name__ == "__main__":
    main()
```

## Key Features

1. **Non-disruptive Operation**
   - Runs as a background daemon
   - Uses file locking to prevent multiple instances
   - Handles signals gracefully for clean shutdown

2. **Robust Error Handling**
   - Comprehensive logging
   - Retry mechanism with exponential backoff
   - Graceful degradation (continues with other utilities if one fails)
   - Detailed error reporting

3. **Configurable Sync Settings**
   - Adjustable sync frequency
   - Configurable notification preferences
   - Customizable commit messages

4. **Notification System**
   - Only notifies on errors (configurable)
   - Uses terminal-notifier with fallback to AppleScript
   - Includes relevant error details

5. **Security Considerations**
   - Safe handling of sensitive files
   - Proper file permissions

6. **System Integration**
   - Installs as a LaunchAgent for automatic startup
   - Integrates with macOS notification system
   - Low resource usage

## Usage Examples

### Manual Sync
```bash
mac-sync-wizard sync
```

### Install Background Service
```bash
mac-sync-wizard install
```

### Change Sync Frequency
```bash
mac-sync-wizard sync --frequency 3600  # 1 hour
```

### Uninstall Background Service
```bash
mac-sync-wizard uninstall
```
