# =============================================================================
# Zsh Key Bindings
# =============================================================================
# Source this file from .zshrc: source ~/.config/zsh/keybindings.zsh
# =============================================================================

# Use emacs key bindings (default, good for most use cases)
# Change to 'bindkey -v' for vim mode
bindkey -e

# -----------------------------------------------------------------------------
# Navigation
# -----------------------------------------------------------------------------
# Word navigation (option + arrow on macOS)
bindkey "^[[1;3D" backward-word  # Option + Left
bindkey "^[[1;3C" forward-word   # Option + Right
bindkey "^[b" backward-word      # Alt + b
bindkey "^[f" forward-word       # Alt + f

# Line navigation
bindkey "^A" beginning-of-line   # Ctrl + a
bindkey "^E" end-of-line         # Ctrl + e

# -----------------------------------------------------------------------------
# Editing
# -----------------------------------------------------------------------------
# Delete word backward/forward
bindkey "^W" backward-kill-word  # Ctrl + w (delete word backward)
bindkey "^[d" kill-word          # Alt + d (delete word forward)
bindkey "^[^?" backward-kill-word # Alt + Backspace

# Delete to end/beginning of line
bindkey "^K" kill-line           # Ctrl + k (delete to end)
bindkey "^U" backward-kill-line  # Ctrl + u (delete to beginning)

# Undo
bindkey "^_" undo                # Ctrl + _ (undo)
bindkey "^X^U" undo              # Ctrl + x, Ctrl + u

# -----------------------------------------------------------------------------
# History
# -----------------------------------------------------------------------------
# Only set if atuin is not managing history
if [[ -z "$ATUIN_SESSION" ]]; then
    bindkey "^R" history-incremental-search-backward  # Ctrl + r
    bindkey "^S" history-incremental-search-forward   # Ctrl + s
fi

# History navigation (arrow keys with prefix search)
bindkey "^P" up-line-or-search      # Ctrl + p
bindkey "^N" down-line-or-search    # Ctrl + n

# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------
bindkey "^I" expand-or-complete     # Tab (completion)
bindkey "^[[Z" reverse-menu-complete # Shift + Tab (reverse completion)

# Accept autosuggestion (if using zsh-autosuggestions)
bindkey "^[l" autosuggest-accept 2>/dev/null  # Alt + l
bindkey "^[[1;3C" autosuggest-accept 2>/dev/null # Option + Right

# -----------------------------------------------------------------------------
# Miscellaneous
# -----------------------------------------------------------------------------
# Clear screen
bindkey "^L" clear-screen

# Edit command line in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line  # Ctrl + x, Ctrl + e

# Insert last argument from previous command
bindkey "^[." insert-last-word    # Alt + .
bindkey "^[_" insert-last-word    # Alt + _

# Expand alias
bindkey "^Xa" _expand_alias       # Ctrl + x, a

# Quote region
bindkey "^['" quote-region        # Alt + '

# -----------------------------------------------------------------------------
# Directory Stack Navigation
# -----------------------------------------------------------------------------
# Quick directory jumping
bindkey -s "^[1" "cd -\n"         # Alt + 1: Go to previous directory
bindkey -s "^[2" "cd -2\n"        # Alt + 2: Go to 2nd in stack
bindkey -s "^[3" "cd -3\n"        # Alt + 3: Go to 3rd in stack

# -----------------------------------------------------------------------------
# Vi Mode Additions (if using bindkey -v)
# -----------------------------------------------------------------------------
# Uncomment if you prefer vi mode:
# bindkey -v
# export KEYTIMEOUT=1
#
# # Add some emacs-like bindings in insert mode
# bindkey -M viins '^A' beginning-of-line
# bindkey -M viins '^E' end-of-line
# bindkey -M viins '^K' kill-line
# bindkey -M viins '^W' backward-kill-word
# bindkey -M viins '^U' backward-kill-line
# bindkey -M viins '^R' history-incremental-search-backward
