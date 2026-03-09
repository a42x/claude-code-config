# claude-code-config

Opinionated Claude Code configuration with Slack integration, Google Workspace tools, autonomous workflow rules, and GPT expert delegation.

## What's Included

| Category | Contents |
|----------|----------|
| **Skills** | Slack (check, post, search), Google Sheets, Google Calendar |
| **Rules** | Autonomous workflow (PAP, R1-R7), coding standards (TDD), GPT/Gemini delegation |
| **Hooks** | Push notification template (Bark, webhook, Zellij) |
| **Bin** | `slack-cli.sh` - Slack Web API wrapper supporting multiple workspaces |

## Quick Start

```bash
git clone https://github.com/a42x/claude-code-config.git
cd claude-code-config
./install.sh
```

Then run `/setup` in Claude Code to configure Slack tokens and GWS.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- `curl`, `python3`, `jq` available in PATH
- (Optional) [Codex CLI](https://github.com/openai/codex) for GPT delegation
- (Optional) `gws` CLI for Google Workspace operations

## Installation

The install script creates symlinks from your `~/.claude/` directory to this repository:

```bash
./install.sh            # Install (symlinks)
./install.sh --uninstall  # Remove symlinks
```

Existing files are never overwritten. If a file already exists and is not a symlink, it will be skipped.

## Slack Setup

The Slack integration uses browser session tokens (`xoxc` + `xoxd` cookie) for API access. See [docs/slack-token-guide.md](docs/slack-token-guide.md) for detailed setup instructions.

```bash
mkdir -p ~/.config/slack-cli
cat > ~/.config/slack-cli/workspaces.json << 'EOF'
{
  "xoxd": "xoxd-YOUR_COOKIE",
  "default_workspace": "my-workspace",
  "workspaces": {
    "my-workspace": {
      "name": "My Workspace",
      "token": "xoxc-YOUR_TOKEN"
    }
  }
}
EOF
chmod 600 ~/.config/slack-cli/workspaces.json
```

## Google Workspace Setup

See [docs/gws-setup-guide.md](docs/gws-setup-guide.md).

## Skills

| Skill | Description |
|-------|-------------|
| `/slack-check` | Read latest messages from a Slack channel |
| `/slack-post` | Post a message to Slack (requires user approval) |
| `/slack-search` | Search Slack messages with full search syntax |
| `/gws-sheets` | Read and write Google Sheets |
| `/gws-calendar` | View, create, update, delete Google Calendar events |

## Rules

### Workflow (`rules/workflow.md`)

Autonomous execution rules including:
- **R1-R7**: Edit strategy, subagent management, parallel execution, completion reports
- **PAP (Pre-Action Protocol)**: 8-step checklist before every action
- **Agent Orchestration**: PDCA cycle for delegated tasks

### Coding Standards (`rules/coding-standards.md`)

- TDD (mandatory): RED -> GREEN -> REFACTOR
- API response format conventions
- Pre-commit quality gate
- Failure database for learning from mistakes

### GPT Delegation (`rules/delegator/`)

Route complex tasks to GPT experts via `codex exec`:
- **Architect**: System design, tradeoffs
- **Plan Reviewer**: Validate plans before execution
- **Code Reviewer**: Find bugs, security issues
- **Security Analyst**: Vulnerability assessment
- **Scope Analyst**: Catch ambiguities early

## Hooks

`hooks/notify.sh` sends push notifications when Claude Code needs attention:
- **Bark** (iOS): Set `BARK_DEVICE_KEY` env var
- **Webhook**: Set `NOTIFY_WEBHOOK_URL` env var
- **Zellij**: Auto-detected when running in Zellij

## License

MIT
