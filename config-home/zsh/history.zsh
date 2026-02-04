# =============================================================================
# Zsh History Configuration
# =============================================================================
# Source this file from .zshrc: source ~/.config/zsh/history.zsh
# =============================================================================

# History file location
HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/history"

# Ensure history directory exists
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"

# History size (in memory and file)
HISTSIZE=100000
SAVEHIST=100000

# History timestamp format
HIST_STAMPS="yyyy-mm-dd"

# -----------------------------------------------------------------------------
# History Search (if not using atuin)
# -----------------------------------------------------------------------------
# Up/Down arrow search based on current input
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Bind to arrow keys (only if atuin not active)
if [[ -z "$ATUIN_SESSION" ]]; then
    bindkey "^[[A" up-line-or-beginning-search
    bindkey "^[[B" down-line-or-beginning-search
    bindkey "^P" up-line-or-beginning-search
    bindkey "^N" down-line-or-beginning-search
fi

# -----------------------------------------------------------------------------
# History Aliases
# -----------------------------------------------------------------------------
alias h='history'
alias hg='history | grep'
alias hs='history | tail -20'

# Search history with fzf (if available)
if command -v fzf &> /dev/null; then
    fh() {
        print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
    }
fi
