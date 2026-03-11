# claude-code-config

Opinionated Claude Code configuration with Slack integration, Google Workspace tools (via gogcli), autonomous workflow rules, and GPT expert delegation.

## What's Included

| Category | Contents |
|----------|----------|
| **Skills** | Slack (check, post, search), Google Calendar, Sheets, Docs (via gogcli) |
| **Commands** | Daily Briefing (multi-context morning summary) |
| **Rules** | Autonomous workflow (PAP, R1-R7), coding standards (TDD), GPT/Gemini delegation |
| **Hooks** | Push notification template (Bark, webhook, Zellij) |
| **Bin** | `slack-cli.sh` - Slack Web API wrapper supporting multiple workspaces |

## Quick Start

```bash
git clone https://github.com/a42x/claude-code-config.git
cd claude-code-config
./install.sh
```

Then run `/setup` in Claude Code to configure Slack tokens and Google accounts.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- `curl`, `python3`, `jq` available in PATH
- [gogcli](https://github.com/steipete/gogcli) for Google Workspace operations (`brew install steipete/tap/gogcli`)
- (Optional) [Codex CLI](https://github.com/openai/codex) for GPT delegation

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

## Google Workspace Setup (gogcli)

See [docs/gogcli-setup-guide.md](docs/gogcli-setup-guide.md) for detailed setup.

Quick version:

```bash
# Install
brew install steipete/tap/gogcli

# Add OAuth credentials
gog auth client add --name "my-client" --file /path/to/client_secret.json

# Use file keyring for CLI environments
gog auth keyring file
export GOG_KEYRING_PASSWORD="your-password"

# Add accounts
gog auth add user@example.com --timeout 5m
gog auth add work@company.com --timeout 5m
```

Add `GOG_KEYRING_PASSWORD` to `~/.claude/settings.json`:

```json
{
  "env": {
    "GOG_KEYRING_PASSWORD": "your-password"
  }
}
```

## Daily Briefing Setup

The `/daily-briefing` command aggregates Calendar, GitHub, Slack, Gmail, and Notion data from multiple work contexts.

1. Copy the example config:
   ```bash
   cp commands/daily-briefing-config.example.json ~/.claude/commands/daily-briefing-config.json
   ```

2. Edit `~/.claude/commands/daily-briefing-config.json` with your contexts:
   ```json
   {
     "contexts": [
       {
         "name": "Work",
         "github_org": "my-company",
         "slack_workspace": "my-company",
         "notion": null,
         "google_account": "user@company.com",
         "calendar_id": "primary",
         "gmail": {
           "enabled": true,
           "unread_query": "in:inbox is:unread newer_than:2d",
           "priority_query": "in:inbox is:unread newer_than:2d (label:important OR category:primary)",
           "max_threads": 3
         }
       }
     ]
   }
   ```

3. Run `/daily-briefing` in Claude Code.

Config fields:
- `google_account`: set to `null` to skip all Google services for that context
- `calendar_id`: set to `null` to default to `"primary"`
- `gmail.enabled`: set to `false` to skip Gmail for that context

## Skills

| Skill | Description |
|-------|-------------|
| `/slack-check` | Read latest messages from a Slack channel |
| `/slack-post` | Post a message to Slack (requires user approval) |
| `/slack-search` | Search Slack messages with full search syntax |
| `/gog-calendar` | View, create, update, delete Google Calendar events (multi-account) |
| `/gog-sheets` | Read and write Google Sheets (multi-account) |
| `/gog-docs` | Read, export, create Google Docs (multi-account) |
| `/gog-gmail` | Search and read Gmail (multi-account, read-only) |
| `/daily-briefing` | Morning briefing across all work contexts |

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
