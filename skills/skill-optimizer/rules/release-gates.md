# Release gates for skill changes

## When a benchmark harness is available

- No universal 0% criteria with skill enabled
- No negative delta on critical scenarios
- Benchmark run recorded with date, matrix, and deltas
- Follow-up issues opened for unresolved failures/regressions

## Manual smoke checklist (always applicable)

Before shipping, run the skill on 2–3 representative prompts and check:
- [ ] Skill fires when expected (matching each trigger branch)
- [ ] Output format matches the template/spec
- [ ] No regression in behaviour compared to prior version (diff old vs new output)
- [ ] Edge cases handled explicitly (empty inputs, invalid args, boundary conditions)

## Soft pass conditions

- At least one measurable gain on a target weak model
- No significant context-size increase without measured benefit

## PR checklist

- [ ] Updated `SKILL.md` links for any new/renamed rule file
- [ ] Added/updated benchmark run log entry
- [ ] Included validation command outputs (`test`, `typecheck`, `lint`)
- [ ] Linked tracking issues and remediation notes

## Post-merge loop

- schedule rerun after next model update
- compare against prior run history
- prune stale guidance that no longer moves metrics
