# Model Selection Guidelines

GPT experts serve as specialized consultants for complex problems via `codex exec` CLI.

## Expert Directory

| Expert | Specialty | Best For |
|--------|-----------|----------|
| **Architect** | System design | Architecture, tradeoffs, complex debugging |
| **Plan Reviewer** | Plan validation | Reviewing plans before execution |
| **Scope Analyst** | Requirements analysis | Catching ambiguities, pre-planning |
| **Code Reviewer** | Code quality | Code review, finding bugs |
| **Security Analyst** | Security | Vulnerabilities, threat modeling, hardening |

## Operating Modes

| Mode | Sandbox | Use When |
|------|---------|----------|
| **Advisory** | `read-only` | Analysis, recommendations, reviews |
| **Implementation** | `workspace-write` | Making changes, fixing issues |

## Codex Exec Parameters

| Parameter | Values | Notes |
|-----------|--------|-------|
| `-s` / sandbox | `read-only`, `workspace-write` | Set based on task |
| `-o` / output | file path | Save output to file |
| model | default from `~/.codex/config.toml` | Override with `-m <model>` |

## When NOT to Delegate

- Simple questions you can answer
- First attempt at any fix
- Trivial decisions
- Research tasks (use other tools)
- When user just wants quick info
