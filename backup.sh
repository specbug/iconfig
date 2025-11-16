#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# === Configuration: edit these as needed ===
REPO_DIR="$HOME/Documents/Personal/iconfig"
BACKUP_ITEMS=(
  "$HOME/.config/ghostty"
  "$HOME/.config/zellij"
  # add more paths if you like
)
GIT_REMOTE="origin"
GIT_BRANCH="main"

# === Navigate and update repo ===
cd "$REPO_DIR"

echo "Pulling latest changes from remote..."
git pull "$GIT_REMOTE" "$GIT_BRANCH"

# === Copy items into repo ===
for src in "${BACKUP_ITEMS[@]}"; do
  rel="${src/#$HOME\//}"   # make relative path inside repo
  dst="$REPO_DIR/$rel"

  echo "Backing up $src → $dst"

  # Ensure directory exists
  mkdir -p "$(dirname "$dst")"

  # Remove old copy (optional)
  rm -rf "$dst"

  # Copy new version
  cp -a "$src" "$dst"
done

# === Commit & push ===
git add .
git commit -m "Backup configs: $(date +'%Y-%m-%d %H:%M:%S')"
git push "$GIT_REMOTE" "$GIT_BRANCH"

echo "Backup complete."