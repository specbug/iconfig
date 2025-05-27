# Mac Sync Wizard (iconfig)

Synchronize macOS application configurations across multiple machines using Git.

## Features

- Keep dotfiles and app settings consistent across Macs
- SSH and HTTPS authentication for private repositories
- Choose specific applications to sync
- Automatic backups before restoring configurations
- Preview changes with dry run mode
- Pre-flight environment validation
- Resume setup after interruptions
- Comprehensive logging
- Selective font syncing

## Quick Start

### Installation

#### Method 1: Web installer (Recommended)
```bash
curl -O https://raw.githubusercontent.com/specbug/iconfig/main/web_installer.sh
chmod +x web_installer.sh
./web_installer.sh
```

#### Method 2: Clone repository
```bash
git clone https://github.com/specbug/iconfig.git
cd iconfig
chmod +x install.sh
./install.sh
```

### Prerequisites

- **Homebrew**: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- **Git & Git LFS**: `brew install git git-lfs && git lfs install`

### Usage

#### Create new sync repository
```bash
mac-sync-wizard setup
```

#### Sync configurations
```bash
mac-sync-wizard sync
```

#### Setup on new machine
Run the web installer and answer "Yes" when prompted for new machine setup.

#### Install applications
After setup, use the generated Brewfile:
```bash
brew bundle --file ~/.iconfig/Brewfile
```

## Supported Applications

- **Cursor**: Settings, keybindings, extensions
- **PyCharm**: IDE settings, keymaps, code styles
- **Sublime Text**: Preferences and packages
- **Trackpad**: macOS trackpad preferences
- **Git**: Global configuration
- **Warp**: Terminal themes and settings
- **Fonts**: Custom fonts (selective sync available)
- **Anki**: Add-ons and preferences
- **Stretchly**: Break reminder settings
- **Maccy**: Clipboard manager preferences
- **Shell**: Aliases, functions, and configurations

## Shell Configuration Sync

iconfig extracts and syncs existing shell aliases and functions.

### Setup

Shell sync is integrated into the main setup:

```bash
mac-sync-wizard setup
# Enable "shell" when prompted
```

The setup:
1. Scans existing shell files (`.bashrc`, `.zshrc`, etc.)
2. Extracts aliases and functions to `~/.iconfig/shell/aliases.sh`
3. Configures auto-loading in your shell
4. Preserves original files

### How It Works

- Aliases and functions are stored in `~/.iconfig/shell/aliases.sh`
- This file syncs across machines
- Machine-specific items go in `~/.iconfig/shell/local.sh` (not synced)

### Example

```bash
# Original .zshrc:
alias gitpush='git push origin $(git rev-parse --abbrev-ref HEAD)'
alias gs='git status'

gitpull() {
    BRANCH=${1:-$(git rev-parse --abbrev-ref HEAD)}
    git pull origin $BRANCH --no-rebase
}

# After setup: These are extracted to ~/.iconfig/shell/aliases.sh
# and sync to all machines
```

## Font Sync Configuration

The `~/Library/Fonts/` directory can be large (1.5GB+). Configure selective font syncing:

### Configure

```bash
# Interactive font configuration
mac-sync-wizard config --fonts

# Or through main config
mac-sync-wizard config
```

### Options

1. **Font Families**: Specify by name (includes all weights/styles)
   ```
   Example: "Zed Plex Sans", "SF Mono", "JetBrains Mono"
   ```

2. **File Patterns**: Use wildcards
   ```
   Example: MyCompany-*.ttf, Custom*.otf
   ```

3. **Exclude Patterns**: Sync all except matches
   ```
   Example: System*.ttf, *.dfont
   ```

4. **All Fonts**: Sync everything (not recommended)

## Commands

### `setup`
Configure repository and preferences.
- `--fresh`: Clean reinstall

### `sync`
Sync configurations.
- `--dry-run`: Preview changes
- `--daemon`: Run continuously
- `--verbose`: Show detailed output

### `restore`
Restore configurations.
- `--utility <name>`: Restore specific utility

### `config`
Modify settings.
- `--enable <utility>`: Enable utility sync
- `--disable <utility>`: Disable utility sync
- `--frequency <seconds>`: Set sync interval
- `--reset`: Reset to defaults
- `--fonts`: Configure font sync

### `status`
Check sync status.
- `--verbose`: Detailed information

### `install`
Manage background service.
- `--uninstall`: Remove service

## Configuration

Settings stored in `~/.iconfig/config/sync_config.json`.

### Repository Settings
- URL: Git repository URL
- Branch: Sync branch (default: main)
- Authentication: SSH (recommended) or HTTPS

### Sync Settings
- Frequency: Auto-sync interval
- Auto-commit: Automatic commits
- Pull strategy: Rebase (default) or merge

### Utility Settings
Each utility has:
- Paths: Files/directories to sync
- Exclude patterns: Files to ignore
- Include patterns: Specific file patterns (fonts only)
- Custom fonts: Font families to sync (fonts only)

## Large Files Support

Font files may exceed Git's 100MB limit. iconfig uses Git LFS automatically.

### Setup Git LFS

1. Install: `brew install git-lfs`
2. Setup wizard configures LFS automatically
3. GitHub provides 1GB free LFS storage

### Alternative

If LFS unavailable:
- Sync only essential fonts
- Use interactive selector
- Exclude large font families

## Troubleshooting

### Logs
Located in `~/.iconfig/logs/`

### Common Issues

1. **Git not found**: `brew install git`
2. **SSH authentication fails**: Set up SSH keys for Git provider
3. **Large font files**: Install Git LFS
4. **Large sync size**: Configure selective font sync
5. **Conflicts**: Tool attempts auto-resolution or prompts for manual resolution

## Security

- SSH keys recommended for authentication
- Exclude sensitive files using patterns
- Operations create backups before changes
- Use private repository for configurations

## Contributing

Pull requests welcome. Please:
- Follow existing code style
- Test on macOS
- Update documentation

## License

MIT License - see LICENSE file
