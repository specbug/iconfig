# Zsh Configuration

A clean, modular zsh configuration with modern CLI tools.

## Features

- **Modern CLI replacements**: eza, bat, fd, ripgrep, fzf, zoxide, atuin
- **Lazy loading**: nvm and jenv load only when needed (faster shell startup)
- **1Password integration**: `withenv` command to run with secrets loaded
- **Fuzzy finders**: `fe` (find file), `fgr` (grep + open at line)
- **Kubernetes helpers**: `kx` (context switcher), `kn` (namespace switcher)
- **Yazi integration**: `y` command with directory tracking
- **Starship prompt**: Fast, customizable prompt

## Prerequisites

Install these tools (via Homebrew on macOS):

```bash
# Core tools
brew install eza bat fd ripgrep fzf zoxide atuin starship

# Optional
brew install yazi gum jenv nvm

# 1Password CLI (if using secrets management)
brew install --cask 1password-cli
```

## Installation

```bash
# Backup existing .zshrc
[[ -f ~/.zshrc ]] && mv ~/.zshrc ~/.zshrc.backup

# Copy config files
cp .zshrc ~/.zshrc
cp op_env.zsh ~/.op_env.zsh

# Reload
source ~/.zshrc
```

## Customization

### 1Password Secrets

Edit `~/.op_env.zsh` to match your setup:

```zsh
# Your 1Password accounts
typeset -ga OP_ACCOUNTS=("my.1password.com" "work.1password.com")

# Your vault name
export OP_VAULT="Personal"

# Secrets to manage
typeset -ga OP_VARS=(OPENAI_API_KEY GITHUB_TOKEN MY_SECRET)

# Item names in 1Password
typeset -A OP_ITEM_FOR=(
  OPENAI_API_KEY    "OpenAI API Key"
  GITHUB_TOKEN      "GitHub Token"
  MY_SECRET         "My Secret Item"
)

# Field names within each item
typeset -A OP_FIELD_FOR=(
  OPENAI_API_KEY    api_key
  GITHUB_TOKEN      token
  MY_SECRET         password
)
```

> **Why a separate file?** Shell snapshot tools (e.g. Claude Code) strip
> `_`-prefixed functions and zsh typed arrays (`typeset -ga`/`-A`) from their
> environment capture. Keeping OP config in `~/.op_env.zsh` lets `op_export`
> lazy-load them at runtime when they're missing.

Then use:
- `withenv <command>` - Run command with secrets exported
- `op_export` - Export all secrets to current shell
- `opref VAR` - Show the op:// reference for a variable

### Editor

The `fe` and `fgr` functions use `$EDITOR`. Set it:

```zsh
export EDITOR=nvim  # or vim, code, etc.
```

## Key Bindings

- `Ctrl+T` - fzf file finder
- `Alt+C` - fzf directory finder
- `Ctrl+R` - atuin history search
- `Ctrl+/` - toggle fzf preview

## Directory Navigation

- `z <partial>` - zoxide jump to directory
- `y` - yazi file manager (cd's to last dir on exit)
- `..`, `...`, `....` - quick parent navigation
