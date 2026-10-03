# Playbook: bug

**Use when:** something is broken, throwing, failing, or slow.

1. `/diagnosing-bugs`: build the feedback loop first. The loop must go red on this bug before any theory.
2. `/tdd`: write the regression test (red on the bug), then fix (green).
3. `/code-review`: review the diff against the spec or bug report.

**Success evidence:** the loop command with red output before the fix and green after; regression test name and run output; full suite output; `/code-review` findings.
