---
name: slack-post
description: Post a message to Slack via API. Triggers on "slack post", "post to slack", "send slack message".
---

# Slack Post

Post messages using `chat.postMessage` API.

## Instructions

1. Draft the message content
2. Present the draft to the user and get explicit approval before posting (MANDATORY)
3. After approval, run:
   ```
   ~/.claude/bin/slack-cli.sh post "$CHANNEL" "$MESSAGE" -w "$WORKSPACE" [-t "$THREAD_TS"]
   ```
   - `$CHANNEL`: Channel name or ID
   - `$WORKSPACE`: Workspace name. Uses default from config if omitted.
   - `$THREAD_TS`: Thread timestamp for replies (optional)

## IMPORTANT

- ALWAYS get user approval before posting
- Use `--thread-ts` for thread replies
- If channel name is unknown, run `slack-cli.sh channels -w <workspace>` to list available channels
