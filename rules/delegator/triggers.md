# Delegation Triggers

Check these triggers on EVERY message. This is NOT optional.

## Explicit Triggers (Highest Priority)

| Phrase Pattern | Expert |
|----------------|--------|
| "ask GPT", "consult GPT" | Route based on context |
| "review this architecture" | Architect |
| "review this plan" | Plan Reviewer |
| "analyze the scope" | Scope Analyst |
| "review this code" | Code Reviewer |
| "security review", "is this secure" | Security Analyst |

## Semantic Triggers

### Architecture (-> Architect)
- "how should I structure"
- "what are the tradeoffs"
- "should I use [A] or [B]"
- System design questions
- After 2+ failed fix attempts

### Plan Validation (-> Plan Reviewer)
- "review this plan", "is this plan complete"
- Before significant work

### Requirements (-> Scope Analyst)
- "what am I missing"
- Vague or ambiguous requests
- "before we start"

### Code Review (-> Code Reviewer)
- "review this code", "find issues in"
- After implementing features

### Security (-> Security Analyst)
- "security implications", "is this secure"
- "vulnerabilities in", "threat model"

## Trigger Priority

1. Explicit user request
2. Security concerns
3. Architecture decisions
4. Failure escalation (2+ failed attempts)
5. Default: handle directly

## When NOT to Delegate

- Simple syntax questions
- Direct file operations
- Trivial bug fixes
- Research/documentation
- First attempt at any fix
