---
description: Initial setup guide for claude-code-config. Run after installation to configure Slack and Google Workspace.
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

## 2. Google Workspace Setup (gogcli)

Check if `gog` is installed:

```bash
which gog || echo "Not installed - run: brew install steipete/tap/gogcli"
```

If installed, check auth status:

```bash
gog auth status
```

If no accounts are configured, guide the user:

1. Add OAuth credentials (need a GCP Desktop App client):
   ```bash
   gog auth client add --name "my-client" --file /path/to/client_secret.json
   ```

2. Switch to file keyring for CLI use:
   ```bash
   gog auth keyring file
   ```

3. Set keyring password in environment:
   ```bash
   export GOG_KEYRING_PASSWORD="your-password"
   ```

4. Add Google accounts:
   ```bash
   gog auth add user@example.com --timeout 5m
   ```

5. Verify:
   ```bash
   gog cal events -a user@example.com --from today --to tomorrow
   ```

6. Add `GOG_KEYRING_PASSWORD` to `~/.claude/settings.json`:
   ```json
   {
     "env": {
       "GOG_KEYRING_PASSWORD": "your-password"
     }
   }
   ```

## 3. Daily Briefing Setup (Optional)

If using the daily briefing command:

1. Copy the example config:
   ```bash
   cp ~/.claude/commands/daily-briefing-config.example.json ~/.claude/commands/daily-briefing-config.json
   ```

2. Edit `~/.claude/commands/daily-briefing-config.json` with your contexts
3. Test: run `/daily-briefing` in Claude Code

## 4. Verify Installation

```bash
# Check symlinks
ls -la ~/.claude/bin/slack-cli.sh
ls -la ~/.claude/skills/gog-calendar/
ls -la ~/.claude/rules/workflow.md
ls -la ~/.claude/commands/daily-briefing.md
```
