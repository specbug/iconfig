#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# === Configuration: edit these as needed ===
REPO_DIR="$HOME/Documents/Personal/iconfig"
BACKUP_ITEMS=(
  "$HOME/.config/ghostty"
  "$HOME/.config/zellij"
  "$HOME/.config/zsh"
  # add more absolute source paths as needed
)
GIT_REMOTE="origin"
GIT_BRANCH="ghostty"

# === Pull latest & ensure repo exists ===
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "ERROR: $REPO_DIR is not a git repository."
  exit 1
fi

cd "$REPO_DIR"
echo "Updating repo from remote..."
git pull "$GIT_REMOTE" "$GIT_BRANCH"

# === Copy items into repo with non-dot folder names ===
for src in "${BACKUP_ITEMS[@]}"; do
  if [ ! -e "$src" ]; then
    echo "WARNING: source $src does not exist — skipping."
    continue
  fi

  # e.g. src="/home/user/.config/ghostty"
  rel_path="${src/#$HOME\/\.config\//}"   # removes /home/user/.config/
  # So rel_path becomes "ghostty"
  dst="$REPO_DIR/config-home/${rel_path}"

  echo "Backing up $src → $dst"

  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  cp -a "$src" "$dst"
done

# === Commit & push ===
cd "$REPO_DIR"
git add .
git commit -m "Backup configs: $(date +'%Y-%m-d %H:%M:%S')"
git push "$GIT_REMOTE" "$GIT_BRANCH"

echo "Backup complete."