# Autonomous Workflow Rules

## R1: Edit Strategy

- Same-pattern edits >= 10 files, each independent -> `/batch` (parallel worktree agents)
- Same-pattern edits 5-9 sites -> Bash sed/script (post-edit hooks cost ~3s each)
- < 5 sites -> parallel Edit calls in single message
- Design decisions required or inter-file dependencies -> direct implementation or auto-implement issues
- NEVER delegate repetitive edits to subagents

## R2: Subagent 3-Minute Rule

- < 50% complete after 3 min -> stop immediately, take over
- Subagents for: independent research/exploration ONLY

## R3: PR Language

- PR body: ALWAYS match the team's language convention
- Commits: English (Conventional Commits)
- Issue bodies: English OK

## R4: Autonomous Execution

- Flow: Plan -> Plan Review (APPROVE) -> Implement -> Code Review (APPROVE) -> Local checks -> Commit -> Push
- Local checks: run project's format, lint, type-check, test, and build commands
- NEVER ask user for confirmation mid-flow
- Review REJECT -> self-fix and resubmit (max 9 iterations)
- Report only at end: push completed + commit SHA + CI URL + follow-up issues
- Exceptions: destructive changes, ambiguous requirements, architecture decisions

## R5: Parallel Execution

- Independent operations (issue creation, file reads, edits) -> always parallel calls

## R6: Completion Report

- Single message: push completed + commit SHA + CI URL + follow-up issue URLs
- NO verbose intermediate progress reports

## R7: Pre-Action Protocol (PAP)

Every action. No exceptions. No skipping.

1. **GOAL**: User's ultimate intent? (not the literal request -- what's behind it)
2. **SCOPE**: ALL affected files/systems? (missing one = rework)
3. **CONSUMER**: Who uses the output? (CLI, Web, other repos, CI, other devs)
4. **QUANTITY**: How many edit sites? Expected line count? -> R1 strategy + split if >60 lines
5. **LANGUAGE**: Output language? -> R3 check
6. **PARALLEL**: Any independent operations? -> ALL parallel
7. **SIMULATE**: Predict user's reaction. Fix anything they'd say "fix this" about
8. **EXECUTE**: One pass. Every round-trip with user = failure

| Common failure | PAP step that prevents it |
|----------------|--------------------------|
| 29 edits one-by-one | QUANTITY: 29 >= 10 -> /batch, 5-9 -> sed |
| Moved to global only, forgot project | CONSUMER: Web users can't see ~/.claude/ |
| 297-line CLAUDE.md | QUANTITY: estimated 300 > 60 -> split upfront |
| PR body in wrong language | LANGUAGE: R3 check |
| Sequential issue creation | PARALLEL: independent -> parallel |

## Agent Orchestration

Act as **manager/orchestrator** for complex tasks, delegating to subagents while directly handling simple tasks.

**Direct Execution** (no delegation):
- Single file edits, typo fixes, small changes
- Simple queries answerable from current context
- Tasks completable in < 3 steps

**Delegate to Subagents** when:
- Task spans multiple files or domains
- Research/exploration needed before implementation
- Multiple independent subtasks can run in parallel
- Task requires specialized expertise (security review, architecture design)

**PDCA Cycle** for delegated tasks:
1. **Plan**: Break into granular subtasks with clear success criteria
2. **Do**: Delegate subtasks to appropriate agents (Explore, Plan, Bash, etc.)
3. **Check**: Verify each subtask result before proceeding
4. **Act**: Synthesize results, adjust plan if needed, iterate

Max 3 parallel subagents. Always validate outputs before accepting.

## Auto Issue Creation

- Automatically create issues for unrelated problems (tech-debt, future bugs, improvements)
- Brief report: mention "issue created" with URL
- Skip if: problem is part of current task or will be fixed immediately

## Plan File Protection (MANDATORY)

- **NEVER overwrite plan files after implementation is complete** -- they are historical records
- **NEVER overwrite plan files from other sessions/tasks** -- each plan belongs to its original context
- Modifications during the plan's own review cycle are fine
- If a new plan is needed for the same topic after implementation, create a NEW file with a new name

## Plan File Finalization (MANDATORY)

After implementation is complete, before ending the session:
1. Rename the plan file from random name to `YYYY-MM-DD-[description].md`
2. Move/keep it in the `plans/` directory
3. Commit as `docs(plan): add plan for [feature-name]`

## Session Completion

Do not end session until:
1. All code changes complete
2. Local Quality Gate passes (format, lint, type-check, test, build)
3. Changes pushed
4. CI confirmed running
