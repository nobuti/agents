# Playbook: triage

**Use when:** raw incoming issues (bug reports, feature requests) need triage. Not for tickets made by `/to-tickets`: those are agent-ready.

1. Confirm each target issue was not created by `/to-tickets`; skip those with a reason.
2. `/triage` over the incoming issues: roles per `## Triage labels` in `<root>/config.md`.
3. Hand agent-ready issues to the feature or bug playbook only when the user asks.

**Success evidence:** per issue, its tracker URL or path, the category and state role applied, read back from the tracker.
