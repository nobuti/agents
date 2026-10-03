# Models by role

| Role | Who | How |
| --- | --- | --- |
| implement | Sonnet subagent | `Agent` with `model: sonnet` |
| investigate | Sonnet or Explore subagent | `Agent` (`Explore` for read-only search) |
| judge / decide | main model | in conversation |
| review | main model | reads the files itself |

Rules:

1. The implementer gets the plan path (spec/ticket) and the repo conventions (`CLAUDE.md`, `<root>/GLOSSARY.md`), nothing else.
2. The reviewer never trusts the implementer's summary: read the changed files and run the tests.
3. The main model is not the implementer, unless the change is trivial (a few lines, one file).
