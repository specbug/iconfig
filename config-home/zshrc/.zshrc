##### ===== PATH (deduped; early) =====
export PATH="$HOME/.local/bin:$HOME/go/bin:/opt/homebrew/opt/libpq/bin:/opt/homebrew/opt/node@20/bin:/opt/homebrew/opt/go@1.24/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

##### ===== Aliases & Git helpers =====
alias gitpush='git push origin "$(git rev-parse --abbrev-ref HEAD)"'
gitpull() { BRANCH=${1:-"$(git rev-parse --abbrev-ref HEAD)"}; git pull origin "$BRANCH" --no-rebase; }

##### ===== Modern CLI Tool Aliases =====
# eza (modern ls)
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons'
alias la='eza -a --icons --group-directories-first'

# bat (modern cat)
alias cat='bat --paging=never'
alias catp='bat'

# fd (modern find) - use 'fd' directly, don't alias to 'find' as it breaks scripts
# alias find='fd'  # Disabled: breaks scripts using traditional find syntax

# Productivity
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -p'

# Git shortcuts
alias gs='git status'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline -20'
alias gco='git checkout'
alias gcb='git checkout -b'
alias ga='git add'
alias gc='git commit'
alias gca='git commit --amend'

# Docker shortcuts
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dps='docker ps'
alias dclean='docker system prune -af'

# Kubernetes shortcuts
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'

# Interactive kubectl context switcher (requires gum)
kx() {
  local ctx
  ctx=$(kubectl config get-contexts -o name 2>/dev/null | \
    gum filter --placeholder="Select context..." --height=15 \
      --indicator="→" --indicator.foreground="212" \
      --match.foreground="212" --header="Kubernetes Contexts")
  [[ -z "$ctx" ]] && return 1
  kubectl config use-context "$ctx" >/dev/null
  gum style --foreground 82 "✓ Switched to: $ctx"
}

# Interactive kubectl namespace switcher (requires gum)
kn() {
  local ns
  ns=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n' | \
    gum filter --placeholder="Select namespace..." --height=15 \
      --indicator="→" --indicator.foreground="212" \
      --match.foreground="212" --header="Namespaces")
  [[ -z "$ns" ]] && return 1
  kubectl config set-context --current --namespace="$ns" >/dev/null
  gum style --foreground 82 "✓ Namespace: $ns"
}

##### ===== Misc env =====
export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"
export JAVA_HOME=$(/usr/libexec/java_home -v 21 2>/dev/null)

##### ===== jenv (lazy) =====
if command -v jenv >/dev/null 2>&1; then
  _jenv_lazy() { unfunction jenv 2>/dev/null; eval "$(jenv init -)"; jenv "$@"; }
  alias jenv=_jenv_lazy
  export PATH="$HOME/.jenv/bin:$PATH"
fi

##### ===== nvm (lazy) =====
export NVM_DIR="$HOME/.nvm"
_nvm_lazy() {
  unfunction nvm node npm npx 2>/dev/null || true
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
}
for _n in node npm npx nvm; do
  eval "function ${_n}(){ _nvm_lazy; unset -f ${_n}; ${_n} \"\$@\"; }"
done

##### ===== Optional extras (guarded) =====
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"; export PATH="$BUN_INSTALL/bin:$PATH"
[[ -f "$HOME/.ghcup/env" ]] && . "$HOME/.ghcup/env"

##### ===== fzf Configuration =====
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="
  --height 60%
  --layout=reverse
  --border rounded
  --preview-window=right:60%:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo {} | pbcopy)'
"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {}'"

# Source fzf keybindings
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

##### ===== Zellij: auto-start in interactive TTY (optional) =====
# Uncomment to auto-start zellij
# if [[ $- == *i* && -t 1 && -z "$ZELLIJ" ]]; then
#   eval "$(zellij setup --generate-auto-start zsh)"
# fi

##### ===== 1Password Integration =====
# Multi-account support with per-key item/field mapping
# Customize OP_ACCOUNTS, OP_VARS, OP_ITEM_FOR, OP_FIELD_FOR for your setup

export OP_BIOMETRIC_UNLOCK_ENABLED=true
typeset -ga OP_ACCOUNTS=("my.1password.com")  # Add your 1Password accounts
export OP_VAULT="${OP_VAULT:-Personal}"       # Default vault

# Define which secrets to manage (customize these)
typeset -ga OP_VARS=(
  OPENAI_API_KEY
  GITHUB_TOKEN
  # Add more as needed
)

# Map env var → 1Password item name
typeset -A OP_ITEM_FOR=(
  OPENAI_API_KEY    "OpenAI API Key"
  GITHUB_TOKEN      "GitHub Token"
)

# Map env var → field name in the item
typeset -A OP_FIELD_FOR=(
  OPENAI_API_KEY    api_key
  GITHUB_TOKEN      token
)

autoload -Uz colors && colors

_op_ref_var() {
  local var="$1"
  local item="${OP_ITEM_FOR[$var]}" field="${OP_FIELD_FOR[$var]}"
  print -r -- "op://$OP_VAULT/$item/$field"
}

_op_can_read_var() {
  local acct="$1" var="$2"
  OP_ACCOUNT="$acct" op read "$(_op_ref_var "$var")" >/dev/null 2>&1
}

_op_pick_account_for_var() {
  local var="$1" acct
  for acct in "${OP_ACCOUNTS[@]}"; do
    if _op_can_read_var "$acct" "$var"; then
      print -r -- "$acct"; return 0
    fi
  done
  return 1
}

op_export_one() {
  local name="$1"
  [[ -n "${(P)name}" && "${(P)name}" != op://* ]] && return 0

  local acct; acct="$(_op_pick_account_for_var "$name")" || {
    print -P "%F{red}[op_export] Not found: vault=%B$OP_VAULT%b item=%B${OP_ITEM_FOR[$name]}%b field=%B${OP_FIELD_FOR[$name]}%b in any account (${OP_ACCOUNTS[*]})%f" >&2
    return 1
  }

  local val; val="$(OP_ACCOUNT="$acct" op read "$(_op_ref_var "$name")" 2>/dev/null)" || {
    print -P "%F{red}[op_export] Read failed for %B$name%b via $acct%f" >&2
    return 1
  }

  export "$name=$val"
  print -P "%F{green}[op_export]%f exported %B$name%b from %B$acct%b"
}

op_export() {
  local v rc=0
  for v in "${OP_VARS[@]}"; do op_export_one "$v" || rc=1; done
  return $rc
}

# Run a command with all secrets loaded
withenv() {
  op_export || { echo "[withenv] some secrets failed to export — aborting" >&2; return 1; }
  if [[ $# -gt 0 ]]; then
    "$@"
  else
    zsh -i
  fi
}

# Export op:// references for use with `op run`
op_export_refs() {
  local v
  for v in "${OP_VARS[@]}"; do
    export "$v=$(_op_ref_var "$v")"
    print -P "%F{blue}[op_export_refs]%f set %B$v%b to reference"
  done
}

# Run command with op:// references (uses op run for injection)
withenv_refs() {
  op_export_refs
  op run -- "${@:-zsh -i}"
}

# Quick helpers
opwho()  { op whoami; }
opls()   { op account list; }
opref()  { local v="$1"; [[ -z "$v" ]] && { echo "usage: opref VAR"; return 2; }; echo "$(_op_ref_var "$v")"; }

##### ===== Fuzzy file search + open =====
# fe [query]: fuzzy find file → open in editor
fe() {
  local file query="${*:-}"
  file=$(fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude __pycache__ | \
    fzf --query="$query" \
        --prompt=" " --pointer="→" \
        --preview 'bat --color=always --style=plain --line-range=:300 {}' \
        --preview-window=right:55%:border-left \
        --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up')
  [[ -n "$file" ]] && ${EDITOR:-nvim} "$file"
}

# fgr: fuzzy grep content → open at line in editor
fgr() {
  local selection file line
  selection=$(rg --color=always --line-number --no-heading --smart-case "${*:-}" | \
    fzf --ansi --prompt=" " --pointer="→" \
        --delimiter : \
        --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' \
        --preview-window=right:60%:border-left:+{2}-10 \
        --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up')
  [[ -z "$selection" ]] && return
  file=$(echo "$selection" | cut -d: -f1)
  line=$(echo "$selection" | cut -d: -f2)
  ${EDITOR:-nvim} "+$line" "$file"
}

##### ===== Yazi file manager integration =====
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

##### ===== Completions (cached & fast) - MUST BE NEAR END =====
fpath=(~/.zsh/completions /opt/homebrew/share/zsh/site-functions $fpath)
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then compinit; else compinit -C; fi

##### ===== Modern Tool Initializations (after compinit) =====
# Zoxide (smart cd)
eval "$(zoxide init zsh)"

# Atuin (shell history)
eval "$(atuin init zsh)"

# Starship prompt (must be last)
eval "$(starship init zsh)"

##### ===== pnpm =====
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

##### ===== End =====
