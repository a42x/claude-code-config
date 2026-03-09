#!/bin/bash
# Install claude-code-config by creating symlinks in ~/.claude/
# Usage: ./install.sh [--uninstall]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

if [[ "${1:-}" == "--uninstall" ]]; then
  echo "Uninstalling claude-code-config..."

  # Remove skill symlinks
  for skill_dir in "$REPO_DIR/skills/"*/; do
    skill_name=$(basename "$skill_dir")
    target="$CLAUDE_DIR/skills/$skill_name"
    if [[ -L "$target" ]]; then
      rm "$target"
      echo "  Removed: skills/$skill_name"
    fi
  done

  # Remove rule symlinks
  for rule_file in "$REPO_DIR/rules/"*; do
    rule_name=$(basename "$rule_file")
    target="$CLAUDE_DIR/rules/$rule_name"
    if [[ -L "$target" ]]; then
      rm "$target"
      echo "  Removed: rules/$rule_name"
    fi
  done

  # Remove bin symlinks
  for bin_file in "$REPO_DIR/bin/"*; do
    bin_name=$(basename "$bin_file")
    target="$CLAUDE_DIR/bin/$bin_name"
    if [[ -L "$target" ]]; then
      rm "$target"
      echo "  Removed: bin/$bin_name"
    fi
  done

  # Remove hook symlinks
  for hook_file in "$REPO_DIR/hooks/"*; do
    hook_name=$(basename "$hook_file")
    target="$CLAUDE_DIR/hooks/$hook_name"
    if [[ -L "$target" ]]; then
      rm "$target"
      echo "  Removed: hooks/$hook_name"
    fi
  done

  # Remove command symlinks
  for cmd_file in "$REPO_DIR/commands/"*; do
    cmd_name=$(basename "$cmd_file")
    target="$CLAUDE_DIR/commands/$cmd_name"
    if [[ -L "$target" ]]; then
      rm "$target"
      echo "  Removed: commands/$cmd_name"
    fi
  done

  echo "Done."
  exit 0
fi

echo "Installing claude-code-config..."

# Create directories
mkdir -p "$CLAUDE_DIR"/{skills,rules,bin,hooks,commands}

# Skills
for skill_dir in "$REPO_DIR/skills/"*/; do
  skill_name=$(basename "$skill_dir")
  target="$CLAUDE_DIR/skills/$skill_name"
  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "  SKIP: skills/$skill_name (exists, not a symlink)"
  else
    ln -sfn "$skill_dir" "$target"
    echo "  Linked: skills/$skill_name"
  fi
done

# Rules (files and directories)
for rule_item in "$REPO_DIR/rules/"*; do
  rule_name=$(basename "$rule_item")
  target="$CLAUDE_DIR/rules/$rule_name"
  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "  SKIP: rules/$rule_name (exists, not a symlink)"
  else
    ln -sfn "$rule_item" "$target"
    echo "  Linked: rules/$rule_name"
  fi
done

# Bin
for bin_file in "$REPO_DIR/bin/"*; do
  bin_name=$(basename "$bin_file")
  target="$CLAUDE_DIR/bin/$bin_name"
  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "  SKIP: bin/$bin_name (exists, not a symlink)"
  else
    ln -sfn "$bin_file" "$target"
    echo "  Linked: bin/$bin_name"
  fi
done

# Hooks
for hook_file in "$REPO_DIR/hooks/"*; do
  hook_name=$(basename "$hook_file")
  target="$CLAUDE_DIR/hooks/$hook_name"
  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "  SKIP: hooks/$hook_name (exists, not a symlink)"
  else
    ln -sfn "$hook_file" "$target"
    echo "  Linked: hooks/$hook_name"
  fi
done

# Commands
for cmd_file in "$REPO_DIR/commands/"*; do
  cmd_name=$(basename "$cmd_file")
  target="$CLAUDE_DIR/commands/$cmd_name"
  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "  SKIP: commands/$cmd_name (exists, not a symlink)"
  else
    ln -sfn "$cmd_file" "$target"
    echo "  Linked: commands/$cmd_name"
  fi
done

echo ""
echo "Done. Run '/setup' in Claude Code to configure Slack and GWS."
