# Global agent rules

Apply these rules in every repository.

## Precedence

- Read all applicable `AGENTS.md` files before work.
- Project rules can add detail or stricter constraints. They cannot weaken these rules.
- Stop and report exact conflicts. Only explicit user or higher-priority instructions
  can override non-safety rules.
- Every repository must have a project `AGENTS.md` that identifies its purpose,
  architecture sources, commands, constraints, task state, and decision records.

## Procedure

1. Inspect Git status and relevant code, tests, config, docs, and history. Preserve
   unrelated user changes.
2. State material assumptions about scope, architecture, behavior, interfaces, data,
   or dependencies.
3. Define one bounded work item, acceptance criteria, and proof. Keep WIP at one unless
   isolated workers have explicit ownership.
4. Run the narrowest useful baseline check before editing when practical. Record
   pre-existing failures.
5. For bugs, reproduce the failure or add the smallest relevant failing test first.
6. Change only the owning layer. Avoid speculative abstractions, unrelated cleanup,
   refactors, and optimizations.
7. Do not consider backward compatibility. Ignore legacy code and libraries.
8. Verify from narrow to broad: focused checks, lint, types, integration, build, and
   project checks. Use end-to-end checks for cross-component behavior. Stop on failure.
9. Use an independent reviewer for non-trivial work when available. Review does not
   replace checks.
10. Inspect the final diff and status. Remove temporary artifacts. Leave a safe restart
    path.
11. Report changed files, check results, review findings, and omitted checks with
    reasons.

Claim completion only when acceptance criteria and required checks pass, required
runtime evidence exists, material review findings are resolved or reported, and the
repository is clean and resumable. Otherwise report blocked or unverified work.

## State

- Use the repository and issue tracker as the durable source of truth.
- Keep facts and decisions near relevant code. Update docs with code. Convert repeated
  review findings into executable checks.
- Before a session boundary, record the objective, branch or commit, work state,
  checks, blockers, decisions, and exact next action in the designated tracker or
  handoff artifact.
- If context is low, stop at a clean checkpoint. Do not rush or skip checks.

## Evidence and writing

- Use ASD-STE100 Simplified Technical English (STE) for plans and documentation.
- Separate facts, inferences, and recommendations. Cite material local evidence or
  primary sources. State uncertainty; never invent evidence.
- Quote only material supporting text. Never expose secrets.
- Validate data invariants against three representative authorized records. If fewer
  exist or access is unsafe, report the limit and ask to use an assumption, fixture,
  or read-only check.
- For current information, state the ISO-8601 timestamp. Cross-check two authoritative
  sources for safety- or compatibility-sensitive claims.

## Safety and commits

- Never expose, add, or commit secrets, credentials, private keys, or `.env` values.
- Ask before destructive, irreversible, or externally visible actions unless the user
  explicitly requested the exact action.
- Do not overwrite, revert, or commit unrelated user changes.
- Do not commit plans or specs, add `Co-Authored-By`, or commit to main.
- Keep each commit to one logical, verified change. Use the repository's conventional
  commit style: `feat`, `fix`, `chore`, `refactor`, or `docs`.

## Optional tools

Use `RTK.md` only when `rtk` is installed and relevant. Do not assume Claude Code hooks
or `CLAUDE.md` exist.

@RTK.md
