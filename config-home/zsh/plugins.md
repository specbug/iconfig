# Recommended Zsh Plugins

Plugins to enhance your zsh experience. These are suggestions - install based on your needs.

## Plugin Manager Options

### 1. Zinit (Fast, recommended)
```zsh
# Install zinit
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"

# Add to .zshrc
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab
```

### 2. Oh My Zsh
```zsh
# Install
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# In .zshrc plugins=(...)
plugins=(git docker kubectl fzf zoxide)
```

### 3. Manual (No Manager)
Clone plugins to ~/.zsh/plugins and source them:
```zsh
# Clone
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting

# Source in .zshrc
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

---

## Essential Plugins

### zsh-autosuggestions
Fish-like autosuggestions based on history.
```zsh
# Accept suggestion: Right arrow or Alt+L
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
```

### zsh-syntax-highlighting
Syntax highlighting for commands as you type.
- Green = valid command
- Red = invalid command
- Underline = valid path

### zsh-completions
Additional completions for many commands.

### fzf-tab
Replace default completion with fzf.
```zsh
# Disable sort for cd completions
zstyle ':completion:*:git-checkout:*' sort false
# Preview for cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
```

---

## Prompt/Theme Options

### Starship (Cross-shell, fast)
```zsh
# Install
brew install starship

# Add to end of .zshrc
eval "$(starship init zsh)"
```

### Powerlevel10k (Feature-rich)
```zsh
# With zinit
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Run configuration wizard
p10k configure
```

### Pure (Minimal)
```zsh
# With zinit
zinit ice pick"async.zsh" src"pure.zsh"
zinit light sindresorhus/pure
```

---

## Already Configured Tools

Based on your setup, you likely already have these configured:

- **atuin** - Shell history with sync (replaces Ctrl+R)
- **zoxide** - Smart cd (use `z` command)
- **fzf** - Fuzzy finder (Ctrl+T, Alt+C, Ctrl+R)
- **eza** - Modern ls with icons
- **bat** - Cat with syntax highlighting
- **fd** - Fast find
- **ripgrep** - Fast grep

---

## Sample .zshrc Structure

```zsh
# =============================================================================
# .zshrc
# =============================================================================

# Path modifications (before plugins)
export PATH="$HOME/.local/bin:$PATH"

# Plugin manager (zinit example)
source "$HOME/.zinit/bin/zinit.zsh"

# Plugins
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab

# Your zsh configs
source ~/.config/zsh/init.zsh

# Tool integrations (order matters)
eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"
eval "$(fzf --zsh)"
eval "$(starship init zsh)"  # Prompt should be last
```
