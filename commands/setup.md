---
description: Initial setup guide for claude-code-config. Run after installation to configure Slack and GWS.
---

# Setup Guide

Walk the user through setting up their environment.

## 1. Slack CLI Setup

Check if `~/.config/slack-cli/workspaces.json` exists:

```bash
cat ~/.config/slack-cli/workspaces.json 2>/dev/null || echo "Not configured"
```

If not configured, guide the user to create it:

1. Open Slack in a browser and sign in
2. Open DevTools (F12) -> Application -> Cookies
3. Find the `d` cookie value (starts with `xoxd-`)
4. Open DevTools -> Network -> filter for `api/` -> find any API call
5. Look at the `Authorization: Bearer xoxc-...` header
6. Create the config file:

```bash
mkdir -p ~/.config/slack-cli
cat > ~/.config/slack-cli/workspaces.json << 'EOF'
{
  "xoxd": "xoxd-YOUR_COOKIE_HERE",
  "default_workspace": "my-workspace",
  "workspaces": {
    "my-workspace": {
      "name": "My Workspace",
      "token": "xoxc-YOUR_TOKEN_HERE"
    }
  }
}
EOF
chmod 600 ~/.config/slack-cli/workspaces.json
```

7. Verify: `~/.claude/bin/slack-cli.sh workspaces`

## 2. GWS CLI Setup (Optional)

Check if `gws` is installed:

```bash
which gws || echo "Not installed"
```

If not installed, guide the user through installation and OAuth setup.

## 3. Verify Installation

```bash
# Check symlinks
ls -la ~/.claude/bin/slack-cli.sh
ls -la ~/.claude/skills/slack-check/
ls -la ~/.claude/rules/workflow.md
```
