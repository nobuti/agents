# Playbook: quick

**Use when:** a small, concrete change; no spec needed.

1. `/tdd`: one red-green slice per behaviour.
2. `/code-review` of the diff.

**Escalate to the [feature playbook](feature.md)** and say so when any trigger fires: the change touches more than ~3 files, needs a design decision, spans more than one session, or the user's wording shows an unsettled question. State which trigger fired.

**Success evidence:** red then green test output; full suite output; `/code-review` findings.
