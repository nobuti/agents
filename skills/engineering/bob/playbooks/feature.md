# Playbook: feature

**Use when:** an idea to build, from sharpening to ship.

1. `/grill-with-docs`: sharpen the idea; glossary and ADRs land in `<root>`.
2. Question needs a runnable answer? `/handoff` → `/prototype` → `/handoff` back. Otherwise skip (state why).
3. `/to-spec`: spec at `<root>/<feature>/spec.md` or on the tracker.
4. `/to-tickets`: tracer-bullet tickets with blocking edges.
5. Build: `/implement` per ticket (clear context between), or `/implement-spec` for the whole spec. Both drive `/tdd` and `/code-review`. Implement via a Sonnet subagent ([models.md](../models.md)).
6. `/retro`.

Keep steps 1-4 in one context window (see [FLOWS.md](../FLOWS.md)).

**Success evidence:** spec and ticket paths or URLs; full test run output (green); `/code-review` findings with each addressed or deferred; diff read by the main model.
