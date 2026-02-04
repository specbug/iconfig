# =============================================================================
# Zsh Completion Configuration
# =============================================================================
# Source this file from .zshrc: source ~/.config/zsh/completions.zsh
# =============================================================================

# Initialize completion system
autoload -Uz compinit

# Only regenerate .zcompdump once a day for faster shell startup
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# -----------------------------------------------------------------------------
# Completion Styling
# -----------------------------------------------------------------------------
# Use menu selection
zstyle ':completion:*' menu select

# Group matches by category
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'

# Case-insensitive matching (first try exact, then case-insensitive)
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Partial completion suggestions
zstyle ':completion:*' list-suffixes
zstyle ':completion:*' expand prefix suffix

# Color completion for files
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# -----------------------------------------------------------------------------
# Process Completion
# -----------------------------------------------------------------------------
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:processes' command 'ps -u $USER -o pid,user,comm -w'

# -----------------------------------------------------------------------------
# Directory Completion
# -----------------------------------------------------------------------------
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:cd:*' ignore-parents parent pwd

# Prioritize current directory completions
zstyle ':completion:*' list-dirs-first true

# -----------------------------------------------------------------------------
# SSH/SCP Completion
# -----------------------------------------------------------------------------
zstyle ':completion:*:(scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:ssh:*' group-order hosts-domain hosts-host users hosts-ipaddr

# -----------------------------------------------------------------------------
# Git Completion (if using git)
# -----------------------------------------------------------------------------
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash 2>/dev/null

# Cache completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Ensure cache directory exists
[[ -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" ]] || mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

# -----------------------------------------------------------------------------
# Rehash on new program installation
# -----------------------------------------------------------------------------
zstyle ':completion:*' rehash true
