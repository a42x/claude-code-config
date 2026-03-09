#!/bin/bash
# Push notification for Claude Code hooks
# Sends notifications when Claude Code needs user attention
#
# Supported notification backends:
#   - Bark (iOS): Set BARK_DEVICE_KEY environment variable
#   - Webhook: Set NOTIFY_WEBHOOK_URL environment variable
#
# Claude Code passes hook data via stdin as JSON

# Read JSON from stdin
INPUT=$(cat)

NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // empty' 2>/dev/null)
MESSAGE=$(echo "$INPUT" | jq -r '.message // empty' 2>/dev/null)

TITLE="Claude Code"

case "$NOTIFICATION_TYPE" in
  permission_prompt)  BODY="Permission required" ;;
  idle_prompt)        BODY="Task completed - awaiting input" ;;
  elicitation_dialog) BODY="Question - input needed" ;;
  *)                  BODY="${MESSAGE:-Notification}" ;;
esac

# Bark notification (iOS)
if [ -n "${BARK_DEVICE_KEY:-}" ]; then
  ENCODED_TITLE=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$TITLE'))")
  ENCODED_BODY=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$BODY")
  curl -sf -o /dev/null "https://api.day.app/${BARK_DEVICE_KEY}/${ENCODED_TITLE}/${ENCODED_BODY}?isArchive=1" 2>/dev/null &
fi

# Generic webhook notification
if [ -n "${NOTIFY_WEBHOOK_URL:-}" ]; then
  curl -sf -o /dev/null -X POST "${NOTIFY_WEBHOOK_URL}" \
    -H "Content-Type: application/json" \
    -d "{\"title\": \"$TITLE\", \"body\": \"$BODY\", \"type\": \"$NOTIFICATION_TYPE\"}" 2>/dev/null &
fi

# Zellij attention tab notification (if running in Zellij)
if [ -n "${ZELLIJ_PANE_ID:-}" ] && command -v zellij &>/dev/null; then
  nohup zellij pipe --name "zellij-attention::waiting::${ZELLIJ_PANE_ID}" -- "" >/dev/null 2>&1 &
fi
