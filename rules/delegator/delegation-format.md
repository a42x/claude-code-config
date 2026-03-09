# Delegation Prompt Templates

When delegating to GPT experts via `codex exec`, use this structured template.

## The 7-Section Format (MANDATORY)

```
1. TASK: [One sentence -- atomic, specific goal]

2. EXPECTED OUTCOME: [What success looks like]

3. CONTEXT:
   - Current state: [what exists now]
   - Relevant code: [paths - codex can read them itself]
   - Background: [why this is needed]

4. CONSTRAINTS:
   - Technical: [versions, dependencies]
   - Patterns: [existing conventions to follow]
   - Limitations: [what cannot change]

5. MUST DO:
   - [Requirement 1]
   - [Requirement 2]

6. MUST NOT DO:
   - [Forbidden action 1]
   - [Forbidden action 2]

7. OUTPUT FORMAT:
   - [How to structure response]
```

## Invocation Pattern

```bash
# Write prompt to file
cat <<'EOF' > /tmp/codex-delegation-prompt.txt
[Expert persona from prompt file]
---
[7-section delegation prompt]
EOF

# Execute
codex exec \
  -s read-only \
  -o /tmp/codex-delegation-output.txt \
  "$(cat /tmp/codex-delegation-prompt.txt)"
```

**Note:** codex exec can read files and run git commands itself (read-only sandbox). Reference file paths in prompts instead of pasting code.

## Quick Reference

| Expert | Advisory Output | Implementation Output |
|--------|-----------------|----------------------|
| Architect | Recommendation + plan + effort | Changes + files + verification |
| Plan Reviewer | APPROVE/REJECT + justification | Revised plan |
| Scope Analyst | Analysis + questions + risks | Refined requirements |
| Code Reviewer | Issues + verdict | Fixes + verification |
| Security Analyst | Vulnerabilities + risk rating | Hardening + verification |
