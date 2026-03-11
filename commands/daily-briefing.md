---
description: Morning daily briefing. Aggregates Calendar/GitHub/Slack/Gmail/Notion across all work contexts.
---

# Daily Briefing

Aggregate "what to do today" from multiple work contexts and display in the terminal.

## Instructions

### Step 1: Load Config

Read `~/.claude/commands/daily-briefing-config.json` to get the list of work contexts.

Each context has:
- `name`, `github_org`, `slack_workspace`, `notion`
- `google_account` (null = skip all Google services)
- `calendar_id` (null = use "primary" if google_account exists)
- `gmail` (`enabled`, `unread_query`, `priority_query`, `max_threads`)

### Step 2: Prepare Date

Run Bash to get today's date info:
```bash
date "+%Y-%m-%d %a" && date -u "+%Y-%m-%dT00:00:00Z" && date -u -v+1d "+%Y-%m-%dT00:00:00Z" && date "+%Y-%m-%dT00:00:00+09:00" && date -v+1d "+%Y-%m-%dT00:00:00+09:00"
```
This gives: display date, UTC today start, UTC tomorrow start, local today start, local tomorrow start.

### Step 3: Parallel Data Collection

Launch **N Agent subagents (haiku model) in parallel**, one per work context. Each agent collects all data sources for its context.

Each agent prompt should include:
- The context name, github_org, slack_workspace, notion flag
- google_account, calendar_id, gmail settings
- Today's date strings (UTC and local ranges)
- Instructions below for each data source

#### Agent instructions per context:

**GitHub** (always):
```bash
# My open PRs in this org
gh search prs --author=@me --state=open --owner=<github_org> --json number,title,url,updatedAt,reviewDecision --limit 20

# PRs requesting my review
gh search prs --review-requested=@me --state=open --owner=<github_org> --json number,title,url,author --limit 20

# Issues assigned to me
gh search issues --assignee=@me --state=open --owner=<github_org> --json number,title,url,updatedAt --limit 20
```

**Slack** (always):
First, get my Slack user ID for this workspace:
```bash
# Get token and cookie for this workspace
TOKEN=$(python3 -c "import json; c=json.load(open('$HOME/.config/slack-cli/workspaces.json')); print(c['workspaces']['<slack_workspace>']['token'])")
XOXD=$(python3 -c "import json; c=json.load(open('$HOME/.config/slack-cli/workspaces.json')); print(c.get('xoxd',''))")

# Get my user ID
curl -s "https://slack.com/api/auth.test" -H "Authorization: Bearer $TOKEN" -H "Cookie: d=$XOXD" | python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('user_id',''))"
```

Then search for mentions using that user ID:
```bash
~/.claude/bin/slack-cli.sh search "<@USER_ID> after:yesterday" -w <slack_workspace> -n 10
```

If `auth.test` fails or returns empty, fall back to:
```bash
~/.claude/bin/slack-cli.sh search "after:yesterday" -w <slack_workspace> -n 5
```

**Google Calendar** (only if google_account is not null):
```bash
# Resolve calendar ID (use explicit value or default to "primary")
CAL_ID="<calendar_id>"
if [ -z "$CAL_ID" ] || [ "$CAL_ID" = "null" ]; then
  CAL_ID="primary"
fi

GOG_KEYRING_PASSWORD="${GOG_KEYRING_PASSWORD:-gogcli}" \
gog cal events "$CAL_ID" \
  -a "<google_account>" \
  --from today \
  --to tomorrow \
  --json \
  --results-only \
  --max 20
```
If google_account is null, skip with message "(Google not configured - skipped)".
If the command fails, show error but continue.

**Gmail** (only if google_account is not null AND gmail.enabled is true):
```bash
# 1. Get unread count (base query)
GOG_KEYRING_PASSWORD="${GOG_KEYRING_PASSWORD:-gogcli}" \
gog gmail search "<gmail.unread_query>" \
  -a "<google_account>" \
  --json \
  --results-only \
  --max 20

# 2. Get priority/important threads
GOG_KEYRING_PASSWORD="${GOG_KEYRING_PASSWORD:-gogcli}" \
gog gmail search "<gmail.priority_query>" \
  -a "<google_account>" \
  --json \
  --results-only \
  --max 5
```
Rendering rule:
- Always show total unread count from base query
- Show up to `gmail.max_threads` (default 3) threads from the priority query
- If priority query returns none, show up to `gmail.max_threads` latest from base query
- For each thread: show sender, subject, and latest time
- If gmail.enabled is false or google_account is null, skip with "(Gmail not configured - skipped)"

**Notion** (only if notion flag is set):
Skip in automated collection. Just output: "(Notion: manual check required)"

Each agent should return a structured text block like:
```
CONTEXT: <name>
---CALENDAR---
<calendar results or "No events" or "Skipped">
---GITHUB---
<github results or "No activity">
---SLACK---
<slack results or "No mentions">
---GMAIL---
<unread count + top threads or "No unread" or "Skipped">
---NOTION---
<notion results or "N/A">
```

### Step 4: Format and Display

Combine all agent results into a single formatted output:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Daily Briefing - YYYY-MM-DD (Day)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Context A

Calendar:
  - 10:00-11:00 Team Standup
GitHub:
  - PR #123 "feat: add validation" (open)
  - Review requested: PR #456 by @teammate
Slack:
  - #dev Bug fix request (12:30)
Gmail: 5 unread
  - From: sender@example.com "Subject line" (09:15)

## Context B

Calendar: No events
GitHub:
  - PR #78 "fix: endpoint error" (open)
Slack: No mentions
Gmail: 2 unread
  - From: dev@example.com "Sprint review notes" (18:00)
```

### Important Notes

- Calendar events: Show time (HH:MM-HH:MM) and summary. All-day events show as "All day".
- GitHub: Show PR/Issue number, title, and status. For review requests show author.
- Slack: Show channel name and message excerpt (truncated to ~80 chars). Show time.
- Gmail: Show "X unread" + up to 3 important threads (sender, subject, time). Keep concise.
- If any data source fails, show error message but continue with other sources.
- Keep it concise - this is a quick morning overview.
