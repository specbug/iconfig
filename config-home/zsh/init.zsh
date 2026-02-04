# =============================================================================
# Zsh Configuration Init
# =============================================================================
# Add this single line to your .zshrc to source all configs:
#   source ~/.config/zsh/init.zsh
#
# Or copy these configs to ~/.config/zsh/ and source individually.
# =============================================================================

# Get the directory where this init file is located
ZSH_CONFIG_DIR="${0:A:h}"

# Source configuration files
[[ -f "${ZSH_CONFIG_DIR}/options.zsh" ]] && source "${ZSH_CONFIG_DIR}/options.zsh"
[[ -f "${ZSH_CONFIG_DIR}/history.zsh" ]] && source "${ZSH_CONFIG_DIR}/history.zsh"
[[ -f "${ZSH_CONFIG_DIR}/completions.zsh" ]] && source "${ZSH_CONFIG_DIR}/completions.zsh"
[[ -f "${ZSH_CONFIG_DIR}/keybindings.zsh" ]] && source "${ZSH_CONFIG_DIR}/keybindings.zsh"
[[ -f "${ZSH_CONFIG_DIR}/aliases.zsh" ]] && source "${ZSH_CONFIG_DIR}/aliases.zsh"
[[ -f "${ZSH_CONFIG_DIR}/functions.zsh" ]] && source "${ZSH_CONFIG_DIR}/functions.zsh"

# Source local overrides (not tracked in git)
[[ -f "${ZSH_CONFIG_DIR}/local.zsh" ]] && source "${ZSH_CONFIG_DIR}/local.zsh"
