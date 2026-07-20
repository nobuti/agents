---
name: systematic-debugging
description: Debugs by evidence, not guessing: reproduce first, isolate to the smallest failing unit, change one variable at a time, land a regression test. Use when a bug, test failure, or unexpected behaviour needs root-causing, especially when the cause is not obvious.
---

# Systematic Debugging

Every debug run follows a tight loop: reproduce → isolate → hypothesise → fix → prove. No fix ships without a repro, and every fix lands with a regression test.

## Non-negotiables

1. **No fix without a reproducible failure.** If the bug cannot be triggered deterministically, stop and add observability instead of guessing.
2. **Change one variable at a time.** When testing a hypothesis, isolate the single change that matters.
3. **State what was verified vs assumed.** Every conclusion comes with evidence.

## Steps

### 1. Reproduce (red)

Turn the bug report into a deterministic repro: a command, a test case, or a request that fails the same way every time. When a test harness exists, write it as a failing test.

**Completion:** the failure is observable on demand. If not reproducible, say so explicitly and suggest what logging or instrumentation would capture it.

### 2. Isolate (fence)

Shrink the scope until the failure is contained in the smallest unit that shows it. Binary-search the system boundaries: logs, commit history (git bisect), feature flags, or temporarily disabling subsystems.

**Completion:** the smallest failing input, state, or code path is identified. State the exact inputs and observed outputs.

### 3. Hypothesise (one at a time)

Before each experiment, state:
- The hypothesis (what you believe the cause is)
- The observation that would confirm or refute it

Test one hypothesis per experiment. Do not shotgun — one variable.

**Completion:** a confirmed root cause, with the evidence that ruled out alternatives.

### 4. Fix at the owning layer

Make the smallest change at the layer that owns the invariant. Do not add indirection to avoid touching a hot path; do not fix a symptom farther downstream.

### 5. Prove (green)

- The repro test goes red before the fix, green after.
- Run the narrowest relevant existing tests; report which ran and which were skipped.
- Confirm no adjacent regression.

**Completion:** green repro-test result + results of relevant side-effect tests.

## Report

After fixing, summarise:
- What broke (one sentence)
- Root cause with file:line evidence
- The fix (minimal, at the owning layer)
- How it was verified (test that goes red/green, checks run)
- Anything not verified
