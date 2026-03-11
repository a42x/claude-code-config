# gogcli (gog) Setup Guide

[gogcli](https://github.com/steipete/gogcli) provides command-line access to Google Workspace APIs (Calendar, Gmail, Sheets, Docs, Drive, etc.) with native multi-account support.

## Installation

```bash
brew install steipete/tap/gogcli
```

## Prerequisites

You need a GCP OAuth 2.0 Desktop App client. If you don't have one:

1. Go to [GCP Console](https://console.cloud.google.com/) > APIs & Services > Credentials
2. Create an OAuth 2.0 Client ID (Application type: Desktop app)
3. Download the client secret JSON

## Add OAuth Credentials

```bash
gog auth client add --name "my-client" --file /path/to/client_secret.json
```

## Keyring Backend

By default, gogcli uses the system keychain. For non-interactive (CLI/CI) environments, switch to the encrypted file backend:

```bash
gog auth keyring file
```

Then set the password via environment variable:

```bash
export GOG_KEYRING_PASSWORD="your-password"
```

Add this to your `~/.claude/settings.json` env section for Claude Code:

```json
{
  "env": {
    "GOG_KEYRING_PASSWORD": "your-password"
  }
}
```

## Add Accounts

```bash
gog auth add user@example.com --timeout 5m
```

This opens a browser for OAuth consent. Repeat for each Google account.

**Note:** If your GCP app is in "Testing" mode, you must add each email to the OAuth consent screen's test users list in GCP Console.

## Verify

```bash
# List today's calendar events
gog cal events -a user@example.com --from today --to tomorrow

# Search Gmail
gog gmail search "in:inbox is:unread" -a user@example.com --max 5

# Read a Google Sheet
gog sheets get SPREADSHEET_ID "Sheet1!A1:C10" -a user@example.com
```

## Multi-Account Usage

All commands support `-a <email>` to specify which account to use:

```bash
gog cal events -a work@company.com --from today --to tomorrow
gog cal events -a personal@gmail.com --from today --to tomorrow
```

## Safety Notes

gogcli categorizes Gmail commands clearly:

| Category | Commands | Risk |
|----------|----------|------|
| **Read** | `search`, `get`, `messages`, `attachment` | Safe (read-only) |
| **Organize** | `archive`, `mark-read`, `unread`, `trash` | Mutates state |
| **Write** | `send`, `drafts` | Sends email |

- Destructive commands require confirmation (use `--force` to skip)
- Use `--dry-run` to preview actions without executing
- Use `--enable-commands` to restrict available commands

## Common Issues

- **Keychain locked**: Switch to file keyring with `gog auth keyring file`
- **OAuth timeout**: Use `--timeout 5m` for slow auth flows
- **Access denied**: Ensure the email is added as a test user in GCP Console
- **Scope errors**: Re-auth with `gog auth add <email>` to request new scopes
