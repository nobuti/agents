---
name: dev-workflow
description: "Personal dev lifecycle reference. Pure info — no actions. Shows feature vs bug workflows: which skills to load, commands to run, artifacts generated at each phase. Trigger: /dev-workflow, 'what's my workflow', 'which skill for X phase', 'how do I start', 'dev lifecycle'."
metadata:
  tags: workflow, lifecycle, reference, skills-map, dev-process
---

# Dev Workflow — Lifecycle Reference

**Pure information. No actions. Read, pick path, load skills.**

---

## PATH A: New Feature

Full lifecycle: define → plan → build → verify → review → ship

```
DEFINE          PLAN           BUILD          VERIFY         REVIEW          SHIP
 ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐
 │Idea  │ ───▶ │ Spec │ ───▶ │ Code │ ───▶ │ Test │ ───▶ │  QA  │ ───▶ │  Go  │
 │Refine│      │  PRD │      │ Impl │      │Debug │      │ Gate │      │ Live │
 └──────┘      └──────┘      └──────┘      └──────┘      └──────┘      └──────┘
```

| # | Phase | Load skill(s) | What happens | Artifact generated |
|---|-------|---------------|--------------|-------------------|
| 1 | **Clarify idea** | `idea-refine` | Divergent/convergent thinking on rough concept. Explore angles, constraints, trade-offs. | Refined proposal (in-chat or `.idea/plans/`) |
| 2 | **Write spec** | `spec-driven-development` | PRD: objectives, users, acceptance criteria, tech stack, boundaries. Human validates before any code. | `SPEC.md` in project root |
| 3 | **Plan tasks** | `planning-and-task-breakdown` | Decompose spec into small, verifiable tasks. Vertical slices. Dependency ordering. Acceptance criteria per task. | `tasks/plan.md`, `tasks/todo.md` |
| 4 | **Build** | `incremental-implementation` + `test-driven-development` | Pick next task. Red → Green → Refactor. Commit each slice. | Commits (one per task), tests |
| 5 | **Verify** | `debugging-and-error-recovery` *(if needed)* | Tests fail or behavior mismatches? Triage: reproduce → localize → reduce → fix → guard. | Bug fix commits, regression guard tests |
| 6 | **Review** | `code-review-and-quality` | Five-axis: correctness, readability, architecture, security, performance. Categorize: Critical / Important / Suggestion. | Structured review output |
| 7 | **Simplify** | `code-simplification` *(optional)* | Reduce complexity. Guard clauses, extracted helpers, dead code removal. Tests must stay green. | Cleaner diff |
| 8 | **Ship** | `shipping-and-launch` | Pre-launch checklist. Parallel fan-out: code-reviewer + security-auditor + test-engineer. GO / NO-GO + rollback plan. | Ship decision report, rollback plan |

### Feature — Cross-cutting skills (load when applicable)

| Condition | Load skill |
|-----------|-----------|
| Designing APIs, module boundaries, type contracts | `api-and-interface-design` |
| Building or modifying UI components | `frontend-ui-engineering` |
| Browser runtime inspection needed | `browser-testing-with-devtools` |
| Framework/library decisions need official docs | `source-driven-development` |
| Auth, user input, external integrations | `security-and-hardening` |
| Performance requirements exist | `performance-optimization` |
| Architectural decision to record | `documentation-and-adrs` |
| Setting up CI/CD pipelines | `ci-cd-and-automation` |
| Removing or migrating old systems | `deprecation-and-migration` |

---

## PATH B: Bug Fix

Focused lifecycle: reproduce → diagnose → fix → verify → review → ship

```
REPRODUCE       DIAGNOSE       FIX           VERIFY         REVIEW          SHIP
 ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐
 │Report│ ───▶ │Triage│ ───▶ │ Prove│ ───▶ │ Guard│ ───▶ │  QA  │ ───▶ │ Patch│
 │      │      │      │      │  It  │      │      │      │ Gate │      │      │
 └──────┘      └──────┘      └──────┘      └──────┘      └──────┘      └──────┘
```

| # | Phase | Load skill(s) | What happens | Artifact generated |
|---|-------|---------------|--------------|-------------------|
| 1 | **Reproduce** | `debugging-and-error-recovery` | Stop-the-line: preserve evidence, logs, repro steps. Confirm bug exists. | Repro steps, error output saved |
| 2 | **Diagnose** | `debugging-and-error-recovery` | Triage checklist: localize → reduce → root cause. No guessing. | Root cause identified |
| 3 | **Fix (Prove-It)** | `test-driven-development` | Write failing test that reproduces the bug. Implement fix. Test passes. | Failing test → passing test, fix commit |
| 4 | **Verify** | `test-driven-development` + `browser-testing-with-devtools` *(if UI)* | Full test suite. No regressions. Browser check if applicable. | Green CI |
| 5 | **Review** | `code-review-and-quality` | Same five-axis, but focus: correctness + regression safety. Is the guard test adequate? | Structured review output |
| 6 | **Ship** | `git-workflow-and-versioning` | Atomic commit. Trunk-based. Message: fix(scope): description + fix reference. | Patch commit, merged |

### Bug — When to escalate

| Situation | Load skill |
|-----------|-----------|
| Bug reveals design flaw or missing spec area | `spec-driven-development` (patch the spec) |
| Fix requires architectural change | `documentation-and-adrs` (record why) |
| Bug is security-related | `security-and-hardening` |
| Bug causes performance regression | `performance-optimization` |
| Fix simplifies tangled code | `code-simplification` |

---

## Expectations by scope

| Scope | Minimum artifacts | Optional artifacts |
|-------|-------------------|-------------------|
| **Feature** (multi-file, >30min) | `SPEC.md`, `tasks/plan.md`, tests, commits, review | ADRs, changelog entry, docs |
| **Feature** (small, <30min, clear reqs) | Tests, commit, review | Spec if ambiguity exists |
| **Bug** (reproducible) | Repro test, fix commit, review | Root cause note in commit |
| **Bug** (production incident) | Repro, fix, guard test, rollback plan, incident note | ADR, post-mortem |

---

## Git discipline (always)

Load `git-workflow-and-versioning` for any code change.
- Atomic commits. One logical change per commit.
- ~100 lines per change when possible. Split if larger.
- Trunk-based development. Short-lived branches.
- Commit message: `type(scope): description`

---

## Source: vendored skills

Skills from `~/.agents/vendor/addyosmani-agent-skills/skills/`. Sync:
```
bash ~/.agents/vendor-update.sh && bash ~/.agents/sync.sh
```
