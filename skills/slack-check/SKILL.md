---
name: slack-check
description: Check latest messages in a Slack channel via API. Triggers on "slack check", "slack channel", "check slack".
---

# Slack Check

Read channel history using `conversations.history` API.

## Instructions

1. Run: `~/.claude/bin/slack-cli.sh history "$CHANNEL" -w "$WORKSPACE" -n "$COUNT"`
   - `$CHANNEL`: Channel name or ID
   - `$WORKSPACE`: Workspace name (see `slack-cli.sh workspaces` for available ones). Uses default from config if omitted.
   - `$COUNT`: Number of messages (default: 10)
2. Summarize results for the user
   - Latest messages summary
   - Note any active threads
3. If channel name is unknown, run `slack-cli.sh channels -w <workspace>` to list available channels

## Available Commands

```
slack-cli.sh history <channel> -w <workspace>    # Channel history
slack-cli.sh channels -w <workspace>             # List channels
slack-cli.sh search <query> -w <workspace>       # Search messages
slack-cli.sh workspaces                          # List configured workspaces
```
