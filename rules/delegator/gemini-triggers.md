# Gemini Research Triggers

Gemini CLI for research tasks. codex exec (GPT) handles code review/design/security, Gemini handles research/investigation.

## Trigger Priority

1. **Explicit user request (codex/GPT)** -> codex exec
2. **Explicit user request (gemini)** -> gemini research
3. **Code review / Security / Architecture / Plan review** -> codex exec
4. **Research / Investigation / Comparison** -> gemini research
5. **Simple factual questions** -> Claude answers directly

## Semantic Triggers (Research Intent)

| Intent Pattern | Example |
|----------------|---------|
| "research", "investigate" | "Research Terraform best practices" |
| "compare" | "Compare Redis vs Memcached" |
| "latest", "current" | "Latest React Server Components info" |
| Technology selection | "Which ORM is best?" |
| "check docs" | "Check Cloud Run documentation" |
| Broad technical survey | "gRPC vs REST vs GraphQL tradeoffs" |

## DO NOT Delegate to Gemini

| Intent | Route To | Reason |
|--------|----------|--------|
| Code review | codex exec (Code Reviewer) | GPT specialty |
| Security analysis | codex exec (Security Analyst) | GPT specialty |
| Architecture design | codex exec (Architect) | GPT specialty |
| Plan validation | codex exec (Plan Reviewer) | GPT specialty |
| Simple factual question | Claude directly | No delegation needed |
| File operations | Claude directly | Tool operations |
