#!/bin/bash
# Slack CLI - search, post, history, channels via Slack Web API
# Uses xoxc tokens + xoxd cookie from ~/.config/slack-cli/workspaces.json

set -euo pipefail

CONFIG_FILE="$HOME/.config/slack-cli/workspaces.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Config file not found: $CONFIG_FILE" >&2
  echo "Run the setup command or create it manually. See README for details." >&2
  exit 1
fi

# Parse config
get_config() {
  local key="$1"
  python3 -c "import json,sys; c=json.load(open('$CONFIG_FILE')); print(c.get('$key',''))"
}

get_workspace_field() {
  local ws="$1" field="$2"
  python3 -c "import json; c=json.load(open('$CONFIG_FILE')); print(c['workspaces']['$ws']['$field'])"
}

list_workspaces() {
  python3 -c "import json; c=json.load(open('$CONFIG_FILE')); [print(f'  {k}: {v[\"name\"]}') for k,v in c['workspaces'].items()]"
}

XOXD=$(get_config xoxd)
DEFAULT_WS=$(get_config default_workspace)

# Defaults
WORKSPACE="$DEFAULT_WS"
COUNT=10
OLDEST=""
POSITIONAL=()

slack_api() {
  local method="$1"
  shift
  local token
  token=$(get_workspace_field "$WORKSPACE" token)

  curl -s "https://slack.com/api/$method" \
    -H "Authorization: Bearer $token" \
    -H "Cookie: d=$XOXD" \
    "$@"
}

cmd_search() {
  local query="$1"
  slack_api "search.messages" \
    -d "query=$query" \
    -d "count=$COUNT" \
    -d "sort=timestamp" \
    -d "sort_dir=desc" | \
  python3 -c "
import json,sys
data = json.loads(sys.stdin.read())
if not data.get('ok'):
    print('Error:', data.get('error', 'unknown'))
    sys.exit(1)
matches = data.get('messages', {}).get('matches', [])
print(f'Found {data[\"messages\"][\"total\"]} results (showing {len(matches)})')
print()
for m in matches:
    ts = m.get('ts', '')
    user = m.get('username', m.get('user', 'unknown'))
    ch = m.get('channel', {}).get('name', 'unknown')
    text = m.get('text', '')[:200]
    permalink = m.get('permalink', '')
    print(f'[{ch}] {user}: {text}')
    print(f'  ts={ts} {permalink}')
    print()
"
}

cmd_post() {
  local channel="$1" message="$2" thread_ts="${3:-}"
  local curl_args=(-d "channel=$channel" --data-urlencode "text=$message")
  if [[ -n "$thread_ts" ]]; then
    curl_args+=(-d "thread_ts=$thread_ts")
  fi

  slack_api "chat.postMessage" "${curl_args[@]}" | \
  python3 -c "
import json,sys
data = json.loads(sys.stdin.read())
if data.get('ok'):
    print('Posted to', data.get('channel', 'unknown'), 'ts=' + data.get('ts', ''))
else:
    print('Error:', data.get('error', 'unknown'))
    sys.exit(1)
"
}

cmd_channels() {
  local result
  result=$(slack_api "conversations.list" \
    -d "types=public_channel,private_channel" \
    -d "limit=200" \
    -d "exclude_archived=true")

  python3 -c "
import json,sys
data = json.loads(sys.stdin.read())
if not data.get('ok'):
    print('Error:', data.get('error', 'unknown'))
    sys.exit(1)
channels = data.get('channels', [])
channels.sort(key=lambda c: c.get('name', ''))
for ch in channels:
    name = ch.get('name', '')
    topic = ch.get('topic', {}).get('value', '')[:60]
    cid = ch.get('id', '')
    print(f'{name} ({cid}) {topic}')
" <<< "$result"
}

cmd_history() {
  local channel="$1"

  # If channel is a name (not ID), resolve it
  if [[ ! "$channel" =~ ^C[A-Z0-9]+$ ]]; then
    local ch_id
    ch_id=$(slack_api "conversations.list" \
      -d "types=public_channel,private_channel" \
      -d "limit=1000" | \
      python3 -c "
import json,sys
data = json.loads(sys.stdin.read())
channels = data.get('channels', [])
for ch in channels:
    if ch.get('name') == '$channel':
        print(ch['id'])
        sys.exit(0)
print('')
")
    if [[ -z "$ch_id" ]]; then
      echo "Error: Channel '$channel' not found" >&2
      exit 1
    fi
    channel="$ch_id"
  fi

  local api_args=(-d "channel=$channel" -d "limit=$COUNT")
  [[ -n "$OLDEST" ]] && api_args+=(-d "oldest=$OLDEST")

  local result
  result=$(slack_api "conversations.history" "${api_args[@]}")

  python3 -c "
import json,sys,datetime
data = json.loads(sys.stdin.read())
if not data.get('ok'):
    print('Error:', data.get('error', 'unknown'))
    sys.exit(1)
msgs = data.get('messages', [])
msgs.reverse()
for m in msgs:
    ts = float(m.get('ts', 0))
    dt = datetime.datetime.fromtimestamp(ts).strftime('%m/%d %H:%M')
    user = m.get('user', 'bot')
    text = m.get('text', '')[:300]
    thread = ' [thread]' if m.get('thread_ts') and m.get('reply_count') else ''
    print(f'[{dt}] {user}{thread}: {text}')
    print()
" <<< "$result"
}

# Parse arguments
COMMAND="${1:-help}"
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace|-w) WORKSPACE="$2"; shift 2 ;;
    --count|-n) COUNT="$2"; shift 2 ;;
    --oldest|-o) OLDEST="$2"; shift 2 ;;
    --thread-ts|-t) THREAD_TS="$2"; shift 2 ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

case "$COMMAND" in
  search)
    cmd_search "${POSITIONAL[0]:-}"
    ;;
  post)
    cmd_post "${POSITIONAL[0]:-}" "${POSITIONAL[1]:-}" "${THREAD_TS:-}"
    ;;
  channels)
    cmd_channels
    ;;
  history)
    cmd_history "${POSITIONAL[0]:-}"
    ;;
  workspaces)
    echo "Available workspaces (default: $DEFAULT_WS):"
    list_workspaces
    ;;
  help|*)
    echo "Usage: slack-cli.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  search <query>                   Search messages"
    echo "  post <channel> <message>         Post a message"
    echo "  channels                         List channels"
    echo "  history <channel>                Channel history"
    echo "  workspaces                       List workspaces"
    echo ""
    echo "Options:"
    echo "  --workspace, -w <name>           Workspace (default: $DEFAULT_WS)"
    echo "  --count, -n <num>                Result count (default: 10)"
    echo "  --oldest, -o <epoch>             Only messages after this Unix timestamp"
    echo "  --thread-ts, -t <ts>             Reply to thread"
    ;;
esac
