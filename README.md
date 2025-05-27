# Mac Sync Wizard

A comprehensive utility to automatically sync Mac application settings across multiple machines.

## Overview

Mac Sync Wizard provides a simple way to synchronize your Mac utilities and settings across multiple machines. With a user-friendly terminal wizard and robust Git-based synchronization, you can easily set up a new Mac with all your preferred configurations.

## Features

- **Simple Setup**: Just run a single curl command to install and set up
- **User-Friendly Terminal UI**: Clear, intuitive interface with visual feedback
- **Automatic Background Sync**: Non-disruptive synchronization that runs in the background
- **Configurable Sync Settings**: Adjust sync frequency, notification preferences, and more
- **Robust Error Handling**: Graceful recovery from network issues and other errors
- **Comprehensive Utility Support**: Syncs settings for a wide range of Mac applications

## Supported Utilities

Mac Sync Wizard can sync settings for the following applications:

1. **Cursor**: Keymaps, shortcuts, themes, settings, extensions
2. **PyCharm**: Keymaps, shortcuts, themes, settings, extensions
3. **Sublime Text**: Keymaps, shortcuts, themes, settings, extensions
4. **Mac Trackpad**: Tracking speed, gestures, and other settings
5. **Git**: User configuration, aliases, and other settings
6. **Arc Browser**: Settings and configurations
7. **Dev Tools**: Setup for Python, Brew, and other development tools
8. **Warp Terminal**: Keymaps, shortcuts, themes, settings
9. **System Fonts**: User-installed fonts
10. **Anki**: Extensions and settings (cards are synced via Anki server)
11. **Logi Options+**: App settings
12. **1Password**: App settings
13. **Arc Browser Extensions**: Browser extensions and settings
14. **Stretchly**: App settings and preferences
15. **Maccy**: App settings and pinned items

## Installation

To install Mac Sync Wizard, run the following command in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/username/mac-sync-wizard/main/install.sh | bash
```

This will download and run the installation script, which will:

1. Check for required dependencies
2. Install necessary Python packages
3. Set up the application directory structure
4. Create the executable script
5. Run the initial setup wizard (optional)

## Usage

### Setup

To run the setup wizard:

```bash
mac-sync-wizard setup
```

The setup wizard will guide you through:
- Configuring your Git repository
- Selecting which utilities to sync
- Setting sync frequency and notification preferences

### Manual Sync

To manually trigger a sync:

```bash
mac-sync-wizard sync
```

### Configuration

To configure sync settings:

```bash
mac-sync-wizard config
```

### Status

To check sync status:

```bash
mac-sync-wizard status
```

### Help

To view help information:

```bash
mac-sync-wizard help
```

## Configuration Options

Mac Sync Wizard offers a range of configuration options:

- **Repository Settings**: URL, branch, authentication method
- **Sync Frequency**: From 15 minutes to weekly, or custom intervals
- **Notification Preferences**: All notifications, errors only, or none
- **Utility Selection**: Enable or disable individual utilities
- **Path Configuration**: Customize which files and directories to sync
- **Exclude Patterns**: Specify files or patterns to exclude from sync

## How It Works

Mac Sync Wizard uses Git to synchronize your settings across machines:

1. **Backup**: Your settings are backed up to a Git repository
2. **Sync**: Changes are automatically committed and pushed to the repository
3. **Restore**: When setting up a new machine, settings are pulled from the repository
4. **Background Service**: A LaunchAgent runs in the background to keep everything in sync

## Project Structure

```
mac-sync-wizard/
├── bin/                  # Executable scripts
├── config/               # Configuration files
├── logs/                 # Log files
└── repo/                 # Git repository
```

## Troubleshooting

### Common Issues

- **Sync Fails**: Check your network connection and Git repository access
- **Permission Errors**: Some settings may require admin privileges
- **Application Not Found**: Ensure the application is installed before syncing

### Logs

Log files are stored in `~/.mac-sync-wizard/logs/`:

- `sync.log`: Sync operation logs
- `error.log`: Error logs
- `daemon.log`: Background service logs

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Thanks to all the open-source projects that made this possible
- Special thanks to the Mac community for inspiration and support
