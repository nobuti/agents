# Setup: write `<root>/config.md`

Per-repo config for the engineering skills. Prompt-driven: explore, present, confirm, write. One section, one answer, then the next. Lead each question with the recommended answer.

## 1. Explore (evidence: list what you read)

- `git remote -v`: GitHub, GitLab (`gitlab.com` or self-hosted), or none.
- `<root>/config.md`: exists? Show it and ask what to change.
- `~/Dev/artifacts/default/config.md`: exists? Offer it as the starting point.
- `triage` skill available? If not, skip Triage labels.

## 2. Ask

**Issue tracker.** Propose from the remote: GitHub remote → GitHub (`gh`); GitLab remote → GitLab (`glab`); no remote → local markdown. Options:

- **GitHub**: [setup/issue-tracker-github.md](setup/issue-tracker-github.md)
- **GitLab**: [setup/issue-tracker-gitlab.md](setup/issue-tracker-gitlab.md)
- **Local markdown**: [setup/issue-tracker-local.md](setup/issue-tracker-local.md), files under `<root>/<feature>/`
- **Other** (Jira, Linear, ...): ask for a one-paragraph workflow description; record it as prose.

Leave "PRs/MRs as a request surface" at **no**; do not raise it.

**Triage labels** (only if `triage` is available). Ask exactly one question: "Keep the default triage labels? (recommended: yes)". Defaults: [setup/triage-labels.md](setup/triage-labels.md) as-is. On no, collect the user's label strings per role.

## 3. Confirm

Show the full draft of `<root>/config.md`. Wait for approval or edits.

## 4. Write

Write `<root>/config.md` (create `<root>/` if needed) with the chosen template bodies under `## Issue tracker` and `## Triage labels`. Touch nothing else: no CLAUDE.md/AGENTS.md edits, no glossary or ADR files.

Evidence: read the file back and show its section headings. Tell the user it is editable by hand; re-run `/bob setup` only to switch trackers.
