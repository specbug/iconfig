##### ===== 1Password helpers (sourced by .zshrc and lazily by op_export) =====
# Extracted into a separate file so that shell snapshot tools (e.g. Claude Code)
# which skip _-prefixed functions and zsh typed arrays can lazy-load them.

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
