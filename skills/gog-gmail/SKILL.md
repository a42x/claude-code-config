---
name: gog-gmail
description: Gmail read/search via gogcli (gog). Multi-account support. Read-only operations only.
args:
  - name: action
    description: "Action to perform (e.g., search, read message, check unread)"
    required: true
  - name: query
    description: "Gmail search query or message ID"
    required: false
---

# Gmail via gogcli (Read-Only)

Gmail operations use `gog gmail` CLI. Supports multi-account via `--account`.

**IMPORTANT: This skill uses READ-ONLY commands only.** Do not use Organize (archive, mark-read, trash) or Write (send) commands.

## Accounts

Configure your accounts with `gog auth add <email>`. Use `-a <email>` to switch accounts.

## Common Commands

### Search threads (Gmail query syntax)
```bash
gog gmail search "in:inbox is:unread" -a user@example.com --max 10
```

### Search with JSON output
```bash
gog gmail search "in:inbox is:unread newer_than:2d" -a user@example.com --json --results-only --max 20
```

### Read a specific message
```bash
gog gmail get MESSAGE_ID -a user@example.com
```

### Read message as JSON
```bash
gog gmail get MESSAGE_ID -a user@example.com --json --results-only
```

### Get message metadata only
```bash
gog gmail get MESSAGE_ID -a user@example.com --format metadata --headers "From,To,Subject,Date"
```

### Download attachment
```bash
gog gmail attachment MESSAGE_ID ATTACHMENT_ID -a user@example.com
```

### Get Gmail web URL for a thread
```bash
gog gmail url THREAD_ID
```

## Useful Gmail Query Syntax

| Query | Description |
|-------|-------------|
| `is:unread` | Unread messages |
| `in:inbox` | Inbox only |
| `newer_than:2d` | Last 2 days |
| `from:sender@example.com` | From specific sender |
| `subject:"keyword"` | Subject contains keyword |
| `has:attachment` | Has attachments |
| `label:important` | Labeled important |
| `category:primary` | Primary category |
| `after:2026/03/01 before:2026/03/12` | Date range |

Queries can be combined: `in:inbox is:unread from:boss@company.com newer_than:7d`

## Safety

gogcli categorizes Gmail commands clearly:

| Category | Commands | Used by this skill |
|----------|----------|-------------------|
| **Read** | `search`, `get`, `messages`, `attachment`, `url` | Yes |
| **Organize** | `archive`, `mark-read`, `unread`, `trash` | **NO** |
| **Write** | `send`, `drafts` | **NO** |

## Instructions

1. Parse `$ARGUMENTS.action` to determine the operation
2. Use `$ARGUMENTS.query` for search query or message ID
3. Execute via `gog gmail` READ commands only
4. Report results to user
5. **NEVER use**: `archive`, `mark-read`, `unread`, `trash`, `send`, `drafts`
