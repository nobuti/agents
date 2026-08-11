# Global agent rules

Sources: `README.md` (purpose, structure, commands); this file (constraints); Git/issues
(state, decisions).

## Precedence

- Load applicable `AGENTS.md` first. Specific rules can strengthen, not weaken, these.
- On conflict, stop, state both, ask. Only explicit user/higher-priority
  instructions override non-safety rules.
- Project `AGENTS.md` must link purpose, architecture, commands, constraints, tracker,
  and decisions.

## Definitions

- **Non-trivial**: affects behavior, public interfaces, persisted data, dependencies,
  or multiple files or subsystems.
- **Protected**: deletes user-owned or persistent data; force-pushes; rewrites history;
  deploys; publishes; changes access; sends external messages; or mutates external state.

## Workflow

1. Inspect Git status, code, tests, config, docs, and history; preserve unrelated
   changes.
2. Define one item, criteria, and proof. Limit work in progress to one unless parallel
   workers own separate scopes. Before non-trivial work, state material assumptions
   affecting scope, design, behavior, interfaces, data, or dependencies.
3. Before edits, run the narrowest check or say none exists. Record existing
   failures.
4. For bugs, reproduce or add the smallest failing test before changing behavior.
5. Edit only the owning layer; add no speculative abstractions, unrelated cleanup, or
   unrequested optimization.
6. Preserve compatibility for published APIs and known consumers. If consumer status
   is unknown, ask before breaking. Ignore legacy compatibility only when neither exists.
7. Verify: focused check, lint, types, integration, build, project checks. Use
   end-to-end evidence across components. Investigate the first new failure; record
   unrelated existing failures and continue when safe.
8. For non-trivial work, get independent review by skill or subagent; it does not
   replace checks.
9. Inspect final diff and status. Remove task temporary files, account for changes,
   and leave the repository resumable.
10. After changes, report files, checks, review findings, and skipped checks with
    reasons.

Report completion only if criteria/checks pass, behavior changes have runtime evidence,
review findings are resolved/reported, and no task-created temporary artifacts remain.
Else report blocked/unverified.

## Handoff

- Treat repository/issues as authoritative. Keep decisions near code, align docs, and
  automate repeated findings.
- For unfinished work, record objective, ref, state, checks, blockers, decisions, and
  next action in tracker or final response.
- On low context, stop at a clean checkpoint. Skip no required work.

## Evidence

- Use ASD-STE100 Simplified Technical English (STE) for plans and docs.
- In reviews, research, and handoffs, separate facts, inferences, recommendations;
  cite non-obvious facts and uncertainty.
- Quote minimum evidence. Never quote or expose secrets.
- Prefer authoritative schemas and tests. For data-inferred invariants, inspect up to
  three authorized representative records; state any access or sample limit.
- Timestamp time-sensitive claims in ISO 8601. Safety or compatibility claims need two
  authoritative sources.

## Safety

- Do not read secret-bearing files such as credentials, private keys, or `.env`; never
  expose, write, or commit secret values.
- Ask before a protected action unless the user requested that exact action.
- Never overwrite, revert, or commit unrelated user changes.
- Never commit agent scratch plans/specs, add `Co-Authored-By`, or commit to `main`.
- Make one logical, verified change per commit. Use `feat`, `fix`, `chore`, `refactor`,
  or `docs`.

## Tools

Read `RTK.md` before `rtk`. Assume no hooks or `CLAUDE.md`.
