---
name: slack-check
description: "このスキルは、ユーザーが「Slackを確認して」「チャンネルの最新メッセージを見て」「Slackチャンネルをチェックして」と依頼した際に使用。Slack APIでチャンネル履歴を取得する。"
allowed-tools: Bash
version: "1.0.0"
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
