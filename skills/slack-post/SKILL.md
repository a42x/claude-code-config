---
name: slack-post
description: "このスキルは、ユーザーが「Slackに投稿して」「Slackメッセージを送って」「Slackにポストして」と依頼した際に使用。Slack APIでメッセージを投稿する。投稿前にユーザー承認が必須。"
disable-model-invocation: true
allowed-tools: Bash
version: "1.0.0"
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
