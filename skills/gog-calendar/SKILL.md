---
name: gog-calendar
description: Google Calendar operations via gogcli (gog). Multi-account support.
args:
  - name: action
    description: "Action to perform (e.g., list events, create event, check free time)"
    required: true
  - name: details
    description: "Details such as date, attendees, title"
    required: false
---

# Google Calendar via gogcli

Google Calendar operations use `gog cal` CLI. Supports multi-account via `--account`.

## Accounts

Configure your accounts with `gog auth add <email>`. Use `-a <email>` to switch accounts.

## Common Commands

### List events
```bash
gog cal events -a user@example.com --from today --to tomorrow
```

### List events for specific date
```bash
gog cal events -a user@example.com --from 2026-03-11 --to 2026-03-12
```

### Create event
```bash
gog cal create user@example.com \
  --title "Meeting" \
  --from "2026-03-11T18:00" \
  --to "2026-03-11T18:30" \
  --attendees "guest@example.com"
```

### Update event
```bash
gog cal update user@example.com EVENT_ID \
  --title "New Title"
```

### Delete event
```bash
gog cal delete user@example.com EVENT_ID
```

### Free/busy check
```bash
gog cal freebusy -a user@example.com --from today --to tomorrow
```

### Search events
```bash
gog cal search "keyword" -a user@example.com
```

## Instructions

1. Parse `$ARGUMENTS.action` to determine the operation
2. Use `$ARGUMENTS.details` for parameters
3. Execute via `gog cal` commands
4. Report results to user
