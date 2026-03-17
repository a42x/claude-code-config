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
- `notion_meetings_db_id` (null = skip Notion meeting matching for completed events)
- `gmail` (`enabled`, `unread_query`, `priority_query`, `max_threads`)

### Step 2: Prepare Date

Run Bash to get today's date info:
```bash
date "+%Y-%m-%d %a" && date -u "+%Y-%m-%dT00:00:00Z" && date -u -v+1d "+%Y-%m-%dT00:00:00Z" && date "+%Y-%m-%dT00:00:00+09:00" && date -v+1d "+%Y-%m-%dT00:00:00+09:00" && date "+%Y-%m-%dT%H:%M:%S+09:00"
```
This gives: display date, UTC today start, UTC tomorrow start, local today start, local tomorrow start, **current local timestamp** (for classifying past vs upcoming events).

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

**IMPORTANT**: Output the **raw JSON** from `gog cal events` in the `---CALENDAR---` block. Do NOT format it as human-readable text. The main conversation needs the structured JSON fields (`id`, `summary`, `start`, `end`, `attachments`, `conferenceData`, `htmlLink`) to classify completed vs upcoming events and match meeting logs. If the JSON is an empty array `[]`, output "No events".

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
Output: "(Notion: collected separately via MCP)"
Notion data will be collected in Step 3.5 using MCP tools.

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

### Step 3.5: Notion Collection (MCP)

For each context where the `notion` flag is truthy, collect Notion data using MCP tools **in the main conversation** (not in subagents). This can run **in parallel** with the Step 3 subagents.

Use `mcp__notion__API-post-search` to get recently updated pages:

```
mcp__notion__API-post-search:
  filter:
    property: "object"
    value: "page"
  sort:
    direction: "descending"
    timestamp: "last_edited_time"
  page_size: 10
```

For each result page, extract:
- Page title: look for `properties.title`, `properties.Name`, or `properties.日報` (whichever has `type: "title"`) and extract `plain_text` from the title array
- Last edited time: `last_edited_time`
- Summary: if `properties.要約` exists with `rich_text`, show a truncated excerpt (~80 chars)

Display rules:
- Filter to only pages edited within the last 48 hours
- Show up to 5 pages
- For each page: title, last edited time, and summary excerpt (if available)
- If no pages were edited recently, show "No recent updates"
- If the MCP tool call fails, show the error but continue with other data

Since Notion MCP uses a single workspace token (not per-context), run a single search and show results under all notion-enabled contexts.

### Step 3.6: Notion Meetings Matching (MCP)

For each context where `notion_meetings_db_id` is set, query the Notion Meetings DB for today's meeting pages. Run this **in parallel** with Step 3 subagents and Step 3.5.

Use `mcp__notion__API-query-data-source`:

```
mcp__notion__API-query-data-source:
  data_source_id: "<notion_meetings_db_id>"
  filter:
    property: "Event time"
    date:
      equals: "<YYYY-MM-DD>"   # today's date from Step 2
  page_size: 10
```

For each result, extract:
- **title**: `properties.Name` (title type) -> `plain_text`
- **event_time**: `properties.Event time` -> `date.start`
- **url**: `url` field (Notion page URL)
- **summary**: `properties.要約` (rich_text) -> truncated ~80 chars (if present)

Store the results as a list of `{title, url, summary}` objects for use in Step 4 matching.

If `notion_meetings_db_id` is null or not set, skip this step.
If the MCP call fails, show warning but continue with other data.

### Step 3.7: Invoice Filing Check

毎月の請求書ファイリング状況を簡易チェックする。Step 3 のサブエージェントと並行して実行可能。

**実行条件**: 毎月1日〜15日の間のみ実行（前月分の請求書が届く期間）。それ以外の日はスキップ。

**チェック手順**:

1. Drive の該当月フォルダを確認:
```bash
export GOG_KEYRING_PASSWORD="gogcli-keyring"
# 前月分のフォルダ（例: 今が3月なら「2026.3月」フォルダ）を確認
gog drive ls --parent 13y2jsuP6MjL27RLuZZp7YKmjMw4C5VGu -a hiro@a42x.co.jp --max 5
# → 該当フォルダのファイル数を確認
gog drive ls --parent <該当フォルダID> -a hiro@a42x.co.jp --max 50
```

2. Gmail で直近の未処理請求書メールを簡易検索:
```
mcp__claude_ai_Gmail__gmail_search_messages:
  q: "(請求書 OR invoice) has:attachment after:YYYY/M-1/25 before:YYYY/M/15"
  maxResults: 10
```

3. Drive 上のファイル名リストと Gmail の請求書メール送信元を比較し、**Drive に未アップロードの請求書**を検出する

**出力**: briefing の末尾に以下のセクションを追加:

```
Invoices:
  Filed: 15 files in 2026.3月/
  Unfiled: 3 invoices detected (津田, FINOLAB, 中央総合法律事務所)
  → Run /file-invoices 2月分 to process
```

ファイリング済みの場合:
```
Invoices: All filed (18 files in 2026.3月/) ✓
```

15日以降の場合:
```
Invoices: (check period ended)
```

### Step 4: Format and Display

Combine all agent results + Notion meeting matches into a single formatted output.

#### Step 4.1: Calendar Event Classification

Parse the raw JSON from each subagent's `---CALENDAR---` block. For each event, compare the **current local timestamp** (from Step 2) with the event's `end.dateTime`:

- `end.dateTime` <= current timestamp → **completed**
- `end.dateTime` > current timestamp → **upcoming**
- All-day events (`start.date` without time): treat as **upcoming** unless the date is in the past

#### Step 4.2: Meeting Log Matching (completed events only)

For each **completed** calendar event, check for meeting logs:

**Gemini Meeting Notes (Google Docs attachments)**:
1. Check the event's `attachments` array in the JSON
2. If any attachment has a `fileUrl` containing `docs.google.com`, use that as the meeting notes link
3. If no `attachments` field exists but `conferenceData` is present (= Google Meet event):
   - Use `mcp__claude_ai_Google_Calendar__gcal_get_event` with `calendarId="primary"` and `eventId=<event id>` to fetch full details
   - Check the returned `attachments` for Google Docs links
   - If MCP call fails, silently skip (no error displayed)

**Notion Meeting Page**:
1. From the Step 3.6 results, find a matching Notion page for this calendar event
2. Matching algorithm: extract significant words (3+ characters) from the calendar event `summary`, then check if 2+ of these words appear in the Notion page title (case-insensitive)
3. If matched, use the Notion page `url`

#### Step 4.3: Output Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Daily Briefing - YYYY-MM-DD (Day)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Context A

Calendar:
  Completed:
    [done] 10:00-10:30 橘定例MTG
           Notion: https://www.notion.so/xxx
    [done] 14:00-15:00 Crypto Garage <-> MynaWallet
           Notes: https://docs.google.com/document/d/abc
           Notion: https://www.notion.so/yyy
  Upcoming:
    - 16:00-17:00 Sprint Planning
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

━━ Invoices ━━
  Filed: 15 files in 2026.3月/
  Unfiled: 3 invoices (津田, FINOLAB, 中央総合法律事務所)
  → Run /file-invoices 2月分
```

#### Calendar Display Rules

- If **no completed events** exist: omit "Completed:" sub-header, show only upcoming events with `-` prefix
- If **no upcoming events** exist: omit "Upcoming:" sub-header, show only completed events with `[done]` prefix
- If **both types exist**: show "Completed:" and "Upcoming:" sub-headers as shown above
- "Notes:" sub-line only appears when a Google Docs attachment was found
- "Notion:" sub-line only appears when a matching Notion meeting page was found
- Sub-lines (Notes/Notion) are indented under their parent event, aligned with the event summary text
- All-day events show as "All day" (unchanged from current behavior)

### Important Notes

- Calendar events: Classified as completed (past end time) or upcoming. Completed events show `[done]` prefix with optional meeting log links (Google Docs, Notion). Upcoming events show time (HH:MM-HH:MM) and summary. All-day events show as "All day".
- GitHub: Show PR/Issue number, title, and status. For review requests show author.
- Slack: Show channel name and message excerpt (truncated to ~80 chars). Show time.
- Gmail: Show "X unread" + up to 3 important threads (sender, subject, time). Keep concise.
- If any data source fails, show error message but continue with other sources.
- Keep it concise - this is a quick morning overview.
