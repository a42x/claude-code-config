# Coding Standards

## TDD (MANDATORY)

- Write tests FIRST before implementation
- TDD cycle: RED -> GREEN -> REFACTOR
- No commit until tests pass. Coverage target: >80%

## API Implementation

- Response format: `{ data, meta }` for success, `{ error: { code, message } }` for errors
- NEVER use `{ success: true, data: {...} }` format
- Reference: project's `docs/api-conventions.md` or OpenSpec spec

## Pre-Commit & Pre-PR Quality Gate

Run before every commit/PR:
```bash
# Adjust commands to your project's toolchain
npm run format && npm run lint && npm run type-check && npm run test && npm run build
```
All must pass. Do NOT create PR until all pass.

## Test Mock Requirements

- Ensure all mocks are set before test execution
- If tests fail due to missing mocks, add mocks BEFORE writing test cases

## OpenSpec Execution

- Break tasks into granular checkpoints
- Make steps idempotent (safely repeatable)
- Track progress continuously, self-contained execution
- Observable validation at each checkpoint

## Task Management

- Todo files: `tasks/TODO.md` (split by domain if large)
- Temporary files: ALWAYS use `tmp/` directory

## Failure Database

- Learn from mistakes: record and review past failures
- Before starting work: review relevant failure categories
- After completing work: record new failures if applicable
