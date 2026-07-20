---
name: code-review
description: Reviews a diff, PR, or uncommitted changes for correctness and fit. Use when the user asks to review code, a PR, a branch, or a diff, or before merging. Reports findings by severity with file:line evidence.
---

# Code Review

Review the code that is there, not the style you would prefer. Report what matters: logic errors, edge cases, contract breaks, test gaps, and mismatches with project conventions.

## When to use

- Review a diff, PR, or branch
- Pre-merge sanity check
- "Review this change" / "Look at this diff"

Pair with solid for the quality bar and writer-persona when the review report is customer-facing.

## Steps

### 1. Establish intent

Read the PR description, commit messages, and linked issues. State the claimed behaviour change in one sentence. If no description exists, infer from the diff and label it **inferred**.

**Completion:** one-sentence intent statement.

### 2. Map the diff

Group changed files:
- **Core logic** — the behaviour change itself
- **Tests** — new or modified test files
- **Config/docs/churn** — incidental changes

**Completion:** every changed file fits into one category.

### 3. Correctness pass

Apply the checklist below to every changed hunk in core logic files. Do not skip hunks that look trivial — bugs hide in small diffs.

- Logic errors (off-by-one, inverted conditions, missing cases)
- Edge cases (null/empty/missing/zero, boundary values)
- Error handling (swallowed errors, missing error paths, timeout defaults)
- Concurrency / race conditions
- API / schema / ABI contract breaks (renamed fields, changed types, removed endpoints)
- Migration / deployment safety (backwards incompatibility, missing rollout order)
- Security (injection, hardcoded secrets, missing authz checks, untrusted input)

### 4. Fit pass

- Follows project conventions and instructions (AGENTS.md, lint rules, existing patterns)
- Diff is minimal — flag unrelated changes, formatting churn, speculative abstractions
- Changes at the right layer (the code that owns the invariant)
- Tests cover the new behaviour and relevant edge cases

### 5. Verify claims

Run the narrowest relevant tests if safe and feasible. Report what was run, what was skipped, and what cannot be run locally.

### 6. Report

Findings ordered by severity:
- **Blocker** — must not merge as-is (data loss, crash, security, contract break)
- **Major** — should fix before merge (wrong behaviour, missing error handling)
- **Minor** — improve but not a blocker (naming, small duplication, missing test)
- **Nit** — personal preference, explicitly labelled as optional

Every finding includes:
- `path:line` — where the issue is
- Why it matters — concrete impact, not opinion
- Suggestion — the smallest fix

**Completion:** every finding is actionable and traced to source. Summary states: intent vs reality, checks run, and residual risk.

## Rules

- Review the diff as presented, not the system you wish existed.
- Flag absent tests when the change modifies behaviour.
- If a finding could go either way, mark it as a question, not a demand.
- No approval-theatre: do not say "looks good" when findings remain unaddressed.
- Distinguish "must fix" from "consider" in every finding.
