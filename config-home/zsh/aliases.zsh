# =============================================================================
# Zsh Aliases
# =============================================================================
# Source this file from .zshrc: source ~/.config/zsh/aliases.zsh
# =============================================================================

# -----------------------------------------------------------------------------
# Modern CLI Replacements (if installed)
# These complement the aliases you may have in .zshrc
# -----------------------------------------------------------------------------

# eza (modern ls) - only define if not already defined
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first' 2>/dev/null
    alias ll='eza -l --icons --group-directories-first --git' 2>/dev/null
    alias la='eza -la --icons --group-directories-first --git' 2>/dev/null
    alias lt='eza --tree --icons --level=2' 2>/dev/null
    alias lta='eza --tree --icons -a --level=2' 2>/dev/null
    alias l='eza -1 --icons' 2>/dev/null
fi

# bat (modern cat)
if command -v bat &> /dev/null; then
    alias cat='bat --paging=never' 2>/dev/null
    alias catp='bat --plain --paging=never' 2>/dev/null
    alias batl='bat --line-range' 2>/dev/null
fi

# fd (modern find)
if command -v fd &> /dev/null; then
    alias find='fd' 2>/dev/null
fi

# -----------------------------------------------------------------------------
# Git Shortcuts
# -----------------------------------------------------------------------------
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gpl='git pull'
alias gf='git fetch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline -10'
alias glg='git log --graph --oneline --decorate'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gst='git stash'
alias gstp='git stash pop'
alias gsts='git stash show -p'

# -----------------------------------------------------------------------------
# Directory Navigation
# -----------------------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'

# Make directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# -----------------------------------------------------------------------------
# Safety Aliases
# -----------------------------------------------------------------------------
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'

# Force versions (use with caution)
alias rmf='rm -rf'
alias cpf='\cp'
alias mvf='\mv'

# -----------------------------------------------------------------------------
# System & Utilities
# -----------------------------------------------------------------------------
alias c='clear'
alias q='exit'
alias reload='source ~/.zshrc'
alias path='echo $PATH | tr ":" "\n"'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'

# Disk usage
alias df='df -h'
alias du='du -h'
alias dud='du -d 1 -h'
alias duf='du -sh *'

# Process management
alias psg='ps aux | grep -v grep | grep -i'
alias top='htop' 2>/dev/null  # Use htop if available

# Network
alias ip='curl -s ifconfig.me'
alias localip='ipconfig getifaddr en0'
alias ports='netstat -tulanp 2>/dev/null || lsof -i -P -n | grep LISTEN'

# -----------------------------------------------------------------------------
# Development
# -----------------------------------------------------------------------------
# Python
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source .venv/bin/activate 2>/dev/null || source venv/bin/activate'

# Node.js
alias ni='npm install'
alias nid='npm install --save-dev'
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'

# Docker (if using colima)
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs -f'
alias dprune='docker system prune -af'

# Kubernetes
alias k='kubectl'
alias kx='kubectx'
alias kn='kubens'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kex='kubectl exec -it'

# -----------------------------------------------------------------------------
# Zellij Shortcuts
# -----------------------------------------------------------------------------
alias zj='zellij'
alias zja='zellij attach'
alias zjl='zellij list-sessions'
alias zjk='zellij kill-session'
alias zjka='zellij kill-all-sessions'

# -----------------------------------------------------------------------------
# Quick Edit
# -----------------------------------------------------------------------------
alias zshrc='${EDITOR:-nvim} ~/.zshrc'
alias vimrc='${EDITOR:-nvim} ~/.config/nvim/init.lua'
alias ghosttyrc='${EDITOR:-nvim} ~/.config/ghostty/config'
alias zellijrc='${EDITOR:-nvim} ~/.config/zellij/config.kdl'
