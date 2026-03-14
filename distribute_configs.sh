#!/bin/bash

set -euo pipefail

# Resolve the repo root regardless of where the script is called from
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"

# ── Load server list ──
source "$SCRIPT_DIR/server-list.env"

# ── Config mapping: remote path on source host → local relative path ──
OMEGA_FILES=(
  "/home/chameleon/.vimrc"
  "/home/chameleon/.bashrc"
  "/home/chameleon/.tmux.conf"
  "/home/chameleon/.bashrc.d/custom.sh"
  "/home/chameleon/terminal_tools_changelog.md"
)

# ── Step 1: Download configs from source host into repo ──
echo "=== Downloading configs from $SOURCE_HOST ==="
for f in "${OMEGA_FILES[@]}"; do
  rel="${f#/home/chameleon/}"        # e.g. .vimrc, .bashrc.d/custom.sh
  dest="$CONFIGS_DIR/$rel"
  mkdir -p "$(dirname "$dest")"
  echo -n "  $rel ... "
  if scp -q "$SOURCE_HOST:$f" "$dest"; then
    echo "ok"
  else
    echo "FAILED"
  fi
done

# ── Step 2: Install configs on the local (host) machine ──
echo ""
echo "=== Installing configs on local machine ==="
for f in "${OMEGA_FILES[@]}"; do
  rel="${f#/home/chameleon/}"
  src="$CONFIGS_DIR/$rel"
  dest="$HOME/$rel"
  mkdir -p "$(dirname "$dest")"
  echo -n "  $rel ... "
  if [ -f "$src" ] && cp "$src" "$dest"; then
    echo "ok"
  else
    echo "FAILED"
  fi
done

# ── Step 3: Distribute to remote servers ──

DIST_FILES=(".vimrc" ".tmux.conf")

BASHRC_D_LOADER='# ── Load custom extensions from ~/.bashrc.d/ ──────────────────
if [ -d ~/.bashrc.d ]; then
    for f in ~/.bashrc.d/*.sh; do
        [ -f "$f" ] && . "$f"
    done
    unset f
fi'

echo ""
echo "=== Distributing configs to servers ==="
for host in "${DIST_HOSTS[@]}"; do
  echo -n "$host ... "

  # .vimrc and .tmux.conf
  for f in "${DIST_FILES[@]}"; do
    src="$CONFIGS_DIR/$f"
    if [ -f "$src" ] && scp -q "$src" "$host":~/"$f"; then
      ssh "$host" "chmod 777 ~/'$f'"
      echo -n "$f ok  "
    else
      echo -n "$f FAILED  "
    fi
  done

  # terminal_tools_changelog.md
  CHANGELOG="terminal_tools_changelog.md"
  src="$CONFIGS_DIR/$CHANGELOG"
  if [ -f "$src" ] && scp -q "$src" "$host":~/"$CHANGELOG"; then
    ssh "$host" "chmod 777 ~/'$CHANGELOG'"
    echo -n "$CHANGELOG ok  "
  else
    echo -n "$CHANGELOG FAILED  "
  fi

  # .bashrc.d/custom.sh + loader in .bashrc
  ssh "$host" 'mkdir -p ~/.bashrc.d' \
    && scp -q "$CONFIGS_DIR/.bashrc.d/custom.sh" "$host":~/.bashrc.d/custom.sh \
    && ssh "$host" "chmod 777 ~/.bashrc.d/custom.sh"
  if [ $? -eq 0 ]; then
    ssh "$host" 'grep -q "Load custom extensions from ~/.bashrc.d/" ~/.bashrc 2>/dev/null || cat >> ~/.bashrc << '\''BLOCK'\''
'"$BASHRC_D_LOADER"'
BLOCK'
    echo -n "bashrc.d ok  "
  else
    echo -n "bashrc.d FAILED  "
  fi

  echo
done

# ── Step 4: Commit and push to origin ──
echo ""
echo "=== Committing and pushing to origin ==="
cd "$SCRIPT_DIR"
git add -A
if git diff --cached --quiet; then
  echo "  No changes to commit."
else
  git commit -m "Updated configs $(date '+%Y-%m-%d %H:%M:%S')"
  git push origin
  echo "  Pushed to origin."
fi
