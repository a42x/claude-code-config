# Model Orchestration

You have access to GPT experts via `codex exec` CLI. Use them strategically based on these guidelines.

## Available Tools

| Tool | Provider | Use For |
|------|----------|---------|
| `codex exec` | GPT (model from `~/.codex/config.toml`) | Delegate to an expert (stateless, non-interactive) |

> **Key advantage:** `codex exec` runs with `sandbox: read-only` by default, allowing the expert to read files and run git commands itself. No need to paste full code into prompts.

## Available Experts

| Expert | Specialty | Prompt File |
|--------|-----------|-------------|
| **Architect** | System design, tradeoffs, complex debugging | `prompts/architect.md` |
| **Plan Reviewer** | Plan validation before execution | `prompts/plan-reviewer.md` |
| **Scope Analyst** | Pre-planning, catching ambiguities | `prompts/scope-analyst.md` |
| **Code Reviewer** | Code quality, bugs, security issues | `prompts/code-reviewer.md` |
| **Security Analyst** | Vulnerabilities, threat modeling | `prompts/security-analyst.md` |

## Stateless Design

**Each delegation is independent.** The expert has no memory of previous calls.

**Implications:**
- Include ALL relevant context in every delegation prompt
- For retries, include what was attempted and what failed
- Don't assume the expert remembers previous interactions

## PROACTIVE Delegation (Check on EVERY message)

Before handling any request, check if an expert would help:

| Signal | Expert |
|--------|--------|
| Architecture/design decision | Architect |
| 2+ failed fix attempts on same issue | Architect (fresh perspective) |
| "Review this plan", "validate approach" | Plan Reviewer |
| Vague/ambiguous requirements | Scope Analyst |
| "Review this code", "find issues" | Code Reviewer |
| Security concerns, "is this secure" | Security Analyst |

**If a signal matches -> delegate to the appropriate expert.**

## Delegation Flow (Step-by-Step)

### Step 1: Identify Expert
Match the task to the appropriate expert based on triggers.

### Step 2: Read Expert Prompt
Read the expert's prompt file to get their system instructions.

### Step 3: Determine Mode
| Task Type | Mode | Sandbox |
|-----------|------|---------|
| Analysis, review, recommendations | Advisory | `read-only` |
| Make changes, fix issues, implement | Implementation | `workspace-write` |

### Step 4: Notify User
Always inform the user before delegating.

### Step 5: Build Delegation Prompt
Use the 7-section format from `rules/delegator/delegation-format.md`.

### Step 6: Call the Expert

```bash
cat <<'EOF' > /tmp/codex-delegation-prompt.txt
[Expert persona from prompt file]
---
[7-section delegation prompt]
EOF

codex exec \
  -s read-only \
  -o /tmp/codex-delegation-output.txt \
  "$(cat /tmp/codex-delegation-prompt.txt)"
```

### Step 7: Handle Response
1. Read `/tmp/codex-delegation-output.txt`
2. Synthesize - Never show raw output directly
3. Extract insights - Key recommendations, issues, changes
4. Apply judgment - Experts can be wrong; evaluate critically
5. Verify implementation - For implementation mode, confirm changes work

## Cost Awareness

- One well-structured delegation beats multiple vague ones
- Include full context to avoid retry costs
- Reserve for high-value tasks
- Let codex read files itself - reference paths instead of pasting code
