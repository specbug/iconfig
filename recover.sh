#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# === Configuration: edit for your setup ===
REPO_DIR="$HOME/Documents/Personal/iconfig"
RESTORE_ITEMS=(
  "ghostty"
  "zellij"
  "zsh"
  # these correspond to sub-folders under repo/config-home
)

# === Ensure repo exists & update ===
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "ERROR: repo directory $REPO_DIR not found or not a git repo."
  exit 1
fi

cd "$REPO_DIR"
echo "Pulling latest changes..."
git pull

# === Copy back each item ===
for rel in "${RESTORE_ITEMS[@]}"; do
  src="$REPO_DIR/config-home/${rel}"
  dst="$HOME/.config/${rel}"

  if [ ! -e "$src" ]; then
    echo "WARNING: backup item $src not found — skipping."
    continue
  fi

  echo "Restoring $src → $dst"

  if [ -e "$dst" ]; then
    mv "$dst" "${dst}.bak-$(date +'%Y%m%d%H%M%S')"
    echo "  Existing destination moved to backup: ${dst}.bak-<timestamp>"
  fi

  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
done

echo "Restore complete. You may need to restart relevant applications."