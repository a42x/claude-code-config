---
name: slack-search
description: "このスキルは、ユーザーが「Slackを検索して」「Slackでメッセージを探して」「Slackで調べて」と依頼した際に使用。Slack APIでメッセージを検索する。"
allowed-tools: Bash
version: "1.0.0"
---

# Slack Search

Search messages using `search.messages` API.

## Instructions

1. Run: `~/.claude/bin/slack-cli.sh search "$QUERY" -w "$WORKSPACE" -n "$COUNT"`
   - `$QUERY`: Search query (supports Slack search syntax)
   - `$WORKSPACE`: Workspace name. Uses default from config if omitted.
   - `$COUNT`: Number of results (default: 10)
2. Summarize results for the user
   - Channel name, sender, content summary
   - Include permalinks for reference
3. Use `history` command to get surrounding context if needed

## Slack Search Syntax

- `from:@username` - Messages from a specific user
- `in:#channel` - Messages in a specific channel
- `has:link` - Messages containing links
- `before:YYYY-MM-DD` / `after:YYYY-MM-DD` - Date filtering
- `is:thread` - Messages within threads

## Available Workspaces

Run `~/.claude/bin/slack-cli.sh workspaces` to see configured workspaces.
