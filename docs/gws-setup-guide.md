# GWS CLI Setup Guide

The `gws` CLI provides command-line access to Google Workspace APIs (Sheets, Calendar, Drive, etc.).

## Installation

```bash
pip install gws-cli
# or
pipx install gws-cli
```

## Authentication

Run the OAuth flow:

```bash
gws auth login
```

This opens a browser for Google OAuth consent. Grant access to the requested scopes (Calendar, Sheets, etc.).

## Verify

```bash
# List today's calendar events
gws calendar events list --params '{
  "calendarId": "primary",
  "timeMin": "2026-01-01T00:00:00Z",
  "timeMax": "2026-01-01T23:59:59Z",
  "singleEvents": true
}'
```

## Usage Tips

- `--params` for URL/query parameters (JSON format)
- `--json` for request body (not `--body`)
- Japanese text in JSON: use `cat <<'EOF' > /tmp/file.json` then `--json "$(cat /tmp/file.json)"` pattern
- Output format: `--format table|csv|yaml|json`

## Common Issues

- **Scope errors**: Re-run `gws auth login` if new API scopes are needed
- **Token expiry**: Run `gws auth login` to refresh
- **Multiple accounts**: Use `gws auth login --account <email>` to switch accounts
