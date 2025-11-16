#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# === Configuration — edit for your environment ===
REPO_DIR="$HOME/Documents/Personal/iconfig"
BACKUP_ITEMS=(
  ".config/ghostty"
  ".config/zellij"
  # add more relative paths under $HOME as needed
)
GIT_REMOTE="origin"
GIT_BRANCH="ghostty"

# === Navigate to repo and update ===
cd "$REPO_DIR"
echo "Pulling latest from remote..."
git pull "$GIT_REMOTE" "$GIT_BRANCH"

# === Copy each item from home into repo ===
for rel in "${BACKUP_ITEMS[@]}"; do
  src="$HOME/$rel"
  dst="$REPO_DIR/$rel"

  if [ ! -e "$src" ]; then
    echo "Warning: source '$src' does not exist — skipping"
    continue
  fi

  echo "Backing up $src → $dst"
  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  cp -a "$src" "$dst"
done

# === Ensure Git will track the backup items ===
# We assume you have already fixed .gitignore as per instructions

# === Commit & push changes ===
git add .
git commit -m "Backup configs: $(date +'%Y-%m-%d %H:%M:%S')" || echo "No changes to commit"
git push "$GIT_REMOTE" "$GIT_BRANCH"

echo "Backup complete."