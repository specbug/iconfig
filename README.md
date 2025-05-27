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
- **Smart Font Sync**: Selective font syncing to avoid large backups.

## Quick Start

### Installation

#### Method 1: One-line installer (Recommended for fresh machines)
```bash
curl -fsSL https://raw.githubusercontent.com/specbug/iconfig/main/web_installer.sh | bash
```

This will download all required files and install iconfig automatically.

#### Method 2: Clone and install
```bash
git clone https://github.com/specbug/iconfig.git
cd iconfig
chmod +x install.sh
./install.sh
```

### First Time Setup

```bash
mac-sync-wizard setup
```

### Manual Sync

```bash
mac-sync-wizard sync
```

### Restore on New Machine

```bash
mac-sync-wizard setup
mac-sync-wizard restore
```

## Supported Applications

- **Cursor**: Editor settings, keybindings, extensions
- **PyCharm**: IDE settings, keymaps, code styles
- **Sublime Text**: User preferences and packages
- **Trackpad**: macOS trackpad preferences
- **Git**: Global git configuration
- **Warp**: Terminal themes and settings
- **Fonts**: Custom fonts (with selective sync)
- **Anki**: Add-ons and preferences
- **Stretchly**: Break reminder settings
- **Maccy**: Clipboard manager preferences
- **Shell**: Organized aliases, functions, and shell configurations

## Shell Configuration Sync

iconfig automatically extracts and syncs your existing shell aliases and functions across machines.

### Setting Up Shell Sync

Shell alias extraction is integrated into the main setup process:

```bash
mac-sync-wizard setup
# When prompted to enable "shell", say yes
# It will automatically extract your existing aliases
```

The setup will:
1. **Scan** your existing shell files (`.bashrc`, `.zshrc`, etc.) 
2. **Extract** all your aliases and functions to `~/.iconfig/shell/aliases.sh`
3. **Setup** auto-loading in your shell configuration
4. **Preserve** your original files unchanged

### How It Works

After setup:
- Your existing aliases and functions are copied to `~/.iconfig/shell/aliases.sh`
- This file is synced when you run `mac-sync-wizard sync`
- On new machines, `mac-sync-wizard restore` brings all your aliases and functions
- Machine-specific items can go in `~/.iconfig/shell/local.sh` (not synced)

### Example

```bash
# Your existing .zshrc has:
alias gitpush='git push origin $(git rev-parse --abbrev-ref HEAD)'
alias gs='git status'

gitpull() {
    BRANCH=${1:-$(git rev-parse --abbrev-ref HEAD)}
    git pull origin $BRANCH --no-rebase
}

# After setup:
# These are automatically extracted to ~/.iconfig/shell/aliases.sh
# And will sync to all your machines!
```

### Benefits

- **Automatic**: Extracts existing aliases - no manual copying
- **Simple**: One file contains all synced aliases
- **Clean**: No noise from history files or caches
- **Safe**: Original shell files remain untouched
- **Flexible**: Edit the aliases file to add/remove what syncs

## Font Sync Configuration

By default, syncing the entire `~/Library/Fonts/` directory can result in very large backups (1.5GB+). iconfig provides several options to sync only the fonts you need:

### Configure Font Sync

During setup or using the config command:

```bash
# Configure fonts interactively
mac-sync-wizard config --fonts

# Or through the main config UI
mac-sync-wizard config
```

### Font Sync Options

1. **Font Families by Name**: Specify font families as they appear in Font Book
   ```
   Example: "Zed Plex Sans", "SF Mono", "JetBrains Mono"
   ```
   This automatically includes all weights and styles (Regular, Bold, Italic, etc.)

2. **File Pattern Matching**: Use wildcards to match font files
   ```
   Example: MyCompany-*.ttf, Custom*.otf
   ```

3. **Exclude Patterns**: Sync all fonts except those matching patterns
   ```
   Example: Exclude System*.ttf, *.dfont
   ```

4. **All Fonts**: Sync everything (default, but not recommended due to size)

## Commands

### `setup`
Interactive wizard to configure repository and preferences.

Options:
- `--fresh`: Perform a fresh reinstall, removing all existing configuration and data.

### `sync`
Manually sync configurations.

Options:
- `--dry-run`: Preview changes without applying.
- `--daemon`: Run continuously in the background.
- `--verbose`: Show detailed output including file sizes.

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
- `--fonts`: Configure font sync settings.

### `status`
Check current sync status.

Options:
- `--verbose`: Detailed status information.

### `install`
Manage background sync service.

Options:
- `--uninstall`: Remove the background service.

## Configuration

Configuration is stored in `~/.iconfig/config/sync_config.json`.

### Repository Settings
- URL: Your Git repository URL
- Branch: Branch to use for syncing (default: main)
- Authentication: SSH (recommended) or HTTPS

### Sync Settings
- Frequency: How often to sync automatically
- Auto-commit: Whether to commit changes automatically
- Pull strategy: Rebase (default) or merge

### Utility Settings
Each utility can be individually enabled/disabled and has:
- Paths: Files/directories to sync
- Exclude patterns: Files to ignore
- Include patterns: File patterns to specifically include (fonts only)
- Custom fonts: Font family names to sync (fonts only, e.g., "Zed Plex Sans")

## Large Files (Fonts) Support

Some font files can exceed Git's 100MB limit. iconfig automatically uses Git LFS (Large File Storage) for font files.

### Setup Git LFS

1. Install Git LFS:
   ```bash
   brew install git-lfs
   ```

2. The setup wizard will automatically configure Git LFS for your repository

3. If using GitHub, ensure your repository has LFS enabled (it's free for up to 1GB)

### Alternative: Split Font Selection

If you can't use Git LFS, consider:
- Syncing only essential custom fonts
- Using the interactive selector to choose smaller font families
- Excluding large font families (like variable fonts with many weights)

## Troubleshooting

### Logs
Logs are stored in `~/.iconfig/logs/`

### Common Issues

1. **Git not found**: Install Git via Homebrew: `brew install git`
2. **SSH authentication fails**: Ensure SSH keys are set up for your Git provider
3. **Large font files**: Install Git LFS: `brew install git-lfs`
4. **Large sync size**: Configure font sync to only include needed fonts
5. **Conflicts during sync**: The tool will attempt to resolve automatically, or prompt for manual resolution

## Security

- SSH keys are recommended for repository authentication
- Sensitive files can be excluded using patterns
- All operations create backups before making changes
- Repository should be private to protect your configurations

## Contributing

Pull requests are welcome! Please ensure:
- Code follows existing style
- Changes are tested on macOS
- Documentation is updated

## License

MIT License - see LICENSE file for details
