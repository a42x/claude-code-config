# Slack Token Setup Guide

This guide explains how to obtain `xoxc` tokens and `xoxd` cookies for the Slack CLI.

## Why xoxc Tokens?

The Slack CLI uses browser session tokens (`xoxc` + `xoxd` cookie) instead of OAuth Bot tokens. This allows access to all workspaces you're signed into, with your user permissions.

## Steps

### 1. Sign in to Slack Web

Open https://app.slack.com in your browser and sign in to the workspace you want to configure.

### 2. Get the xoxd Cookie

1. Open DevTools (F12 or Cmd+Option+I)
2. Go to **Application** tab -> **Cookies** -> `https://app.slack.com`
3. Find the cookie named `d`
4. Copy its value (starts with `xoxd-`)

> The `xoxd` cookie is shared across all workspaces.

### 3. Get the xoxc Token

1. In DevTools, go to **Network** tab
2. Filter for `api/` requests
3. Click any Slack API request (e.g., `client.counts`)
4. In the request headers or form data, find the `token` parameter
5. Copy the value (starts with `xoxc-`)

> Each workspace has its own `xoxc` token.

### 4. Create the Config File

```bash
mkdir -p ~/.config/slack-cli
cat > ~/.config/slack-cli/workspaces.json << 'EOF'
{
  "xoxd": "xoxd-YOUR_COOKIE_VALUE",
  "default_workspace": "my-workspace",
  "workspaces": {
    "my-workspace": {
      "name": "My Workspace Display Name",
      "token": "xoxc-YOUR_TOKEN_HERE"
    },
    "another-workspace": {
      "name": "Another Workspace",
      "token": "xoxc-ANOTHER_TOKEN"
    }
  }
}
EOF
chmod 600 ~/.config/slack-cli/workspaces.json
```

### 5. Verify

```bash
slack-cli.sh workspaces
slack-cli.sh channels -w my-workspace
```

## Token Rotation

Tokens may expire when you sign out of Slack or clear browser cookies. If you get authentication errors, repeat steps 2-3 to get fresh tokens.

## Security

- The config file contains sensitive credentials
- `chmod 600` ensures only your user can read it
- **Never commit this file to version control**
- Add `workspaces.json` to your global `.gitignore`
