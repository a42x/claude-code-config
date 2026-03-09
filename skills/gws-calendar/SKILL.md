---
name: gws-calendar
description: Google Calendar operations (view, create, update events) using gws CLI.
---

# Google Calendar (gws CLI)

Manage Google Calendar events using the `gws` CLI tool.

## Commands

### List events

```bash
gws calendar events list --params '{
  "calendarId": "primary",
  "timeMin": "2026-01-01T00:00:00+09:00",
  "timeMax": "2026-01-01T23:59:59+09:00",
  "singleEvents": true
}'
```

### Create event

```bash
gws calendar events insert --params '{"calendarId": "primary"}' --json '{
  "summary": "Meeting Title",
  "start": {"dateTime": "2026-01-01T10:00:00+09:00", "timeZone": "Asia/Tokyo"},
  "end": {"dateTime": "2026-01-01T11:00:00+09:00", "timeZone": "Asia/Tokyo"},
  "attendees": [
    {"email": "guest@example.com"}
  ]
}'
```

### Update event

```bash
gws calendar events patch --params '{"calendarId": "primary", "eventId": "EVENT_ID"}' --json '{
  "summary": "Updated Title"
}'
```

### Delete event

```bash
gws calendar events delete --params '{"calendarId": "primary", "eventId": "EVENT_ID"}'
```

## Instructions

1. Determine the action from user request (list, create, update, delete)
2. Build the appropriate gws command
3. Execute and report results to the user
