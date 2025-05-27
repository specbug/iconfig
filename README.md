# Mac Sync Wizard (iconfig)

A robust tool for synchronizing macOS application configurations across multiple machines using Git.

## Features

- **Automatic Sync**: Keep your dotfiles and app settings consistent across Macs.
- **Secure**: Supports SSH and HTTPS authentication for private repositories.
- **Selective Sync**: Choose specific applications to sync.
- **Safe Operations**: Automatic backups before restoring configurations.
- **Dry Run Mode**: Preview changes before applying.
- **Pre-flight Checks**: Validates environment before syncing.
- **Resume Support**: Setup wizard can resume after interruptions.
- **Detailed Logging**: Comprehensive logs for troubleshooting.

## Quick Start

### Installation

```bash
git clone https://github.com/yourusername/iconfig.git
cd iconfig
chmod +x src/install-simple.sh
./src/install-simple.sh
```

### Initial Setup

```bash
mac-sync-wizard setup
```

### Regular Usage

```bash
# Sync configurations
mac-sync-wizard sync

# Check sync status
mac-sync-wizard status

# Restore configurations on a new machine
mac-sync-wizard restore
```

## Supported Applications

- **Cursor** (editor settings, keybindings)
- **PyCharm** (IDE settings: keymaps, options, code styles)
- **Sublime Text** (user packages)
- **Trackpad** (macOS preferences)
- **Git** (configuration and settings)
- **Arc Browser** *(installation only, sync disabled by default)*
- **Warp Terminal** (themes, settings)
- **Fonts** (user-installed fonts)
- **Anki** (add-ons, preferences)
- **Logitech Options+** *(installation only, sync disabled by default)*
- **1Password** *(installation only, sync disabled by default)*
- **Stretchly** (break reminder settings)
- **Maccy** (clipboard manager preferences)

## Commands

### `setup`
Interactive wizard to configure repository and preferences.

### `sync`
Manually sync configurations.

Options:
- `--dry-run`: Preview changes without applying.
- `--daemon`: Run continuously in the background.

### `restore`
Restore configurations from repository.

Options:
- `--utility <name>`: Restore a specific utility.

### `config`
Modify sync settings.

Options:
- `--enable <utility>`: Enable syncing for a utility.
- `--disable <utility>`: Disable syncing for a utility.
- `--frequency <seconds>`: Set automatic sync interval.
- `--reset`: Reset configuration to defaults.

### `status`
Check current sync status.

Options:
- `--verbose`: Detailed status information.

### `install`
Manage background sync service (LaunchAgent).

Options:
- `--uninstall`: Remove background sync service.

## Configuration

Stored at: `~/.mac-sync-wizard/config/sync_config.json`

### Repository Settings
- **URL**: Git repository URL (SSH or HTTPS).
- **Branch**: Branch for syncing (default: `main`).
- **Auth Type**: SSH or HTTPS.

### Sync Settings
- **Frequency**: Automatic sync interval (seconds).
- **Auto Commit**: Automatically commit changes.
- **Commit Message Template**: Customize commit messages.

### Notification Settings
- **Level**: `all`, `errors_only`, or `none`.
- **Method**: Terminal notifications (`terminal-notifier`).

## Best Practices

- Use SSH authentication for security.
- Regularly sync (default every 6 hours).
- Test major changes with `--dry-run`.
- Review logs at `~/.mac-sync-wizard/logs/`.
- Automatic backups are created before restores.

## Troubleshooting

### Pre-flight Checks
- Ensure Git is installed and accessible.
- Verify at least 100MB free disk space.
- Confirm network connectivity.
- Configure Git credentials (SSH keys for SSH URLs).

### Common Issues
- **No SSH key found**: Generate with `ssh-keygen` and add to Git provider.
- **Failed to pull changes**: Check network and repository access.
- **Path does not exist**: Verify application installation paths.

### Logs
- Application logs: `~/.mac-sync-wizard/logs/mac-sync-wizard.log`
- Daemon logs: `~/.mac-sync-wizard/logs/daemon.log`

## Advanced Usage

### Custom Paths
Edit `sync_config.json` to add custom paths:

```json
{
  "utilities": {
    "custom_app": {
      "enabled": true,
      "paths": [
        "~/Library/Application Support/CustomApp/",
        "~/Library/Preferences/com.company.customapp.plist"
      ],
      "exclude_patterns": ["*.log", "Cache/*"]
    }
  }
}
```

### Exclude Patterns
Use rsync-style patterns:
- `*.log`: Exclude log files.
- `Cache/*`: Exclude cache directories.
- `**/node_modules`: Exclude node_modules directories.

## Security Considerations

- Never commit sensitive files (use `.gitignore`).
- Use private repositories for configurations.
- Local backups are created before restores.
- Audit logs regularly.

## Contributing

Contributions are welcome:

1. Fork the repository.
2. Create a feature branch.
3. Submit a pull request.

## License

MIT License – see `LICENSE` file for details.
