# Config resolution

Single source of truth for where per-repo skill config lives. Other skills say "resolve `<root>` per the `## Agent skills` block in CLAUDE.md" and point here.

## Resolve `<root>`

1. Run `git remote get-url origin`. Strip scheme, host, and trailing `.git`: `git@gitlab.com:firesponse/web/calmapper.git` → `firesponse/web/calmapper`.
2. Override: if `~/Dev/artifacts/repos.md` has a line `<remote-or-cwd-prefix> -> <path>` matching the remote URL or the cwd, use `<path>`.
3. No remote and no override: ask the user once for the path.
4. `<root>` = `~/Dev/artifacts/<repo-path>/`. State the resolved `<root>` in your first message.

## Layout

```
<root>/
├── config.md        ## Issue tracker, ## Triage labels
├── GLOSSARY.md      one repo, one glossary (monorepo: <root>/<context>/GLOSSARY.md)
├── adr/NNNN-slug.md
└── <feature>/
    ├── spec.md
    └── issues/NN-slug.md
```

## Read rules

- Read `<root>/config.md`. Missing → read `~/Dev/artifacts/default/config.md` (read-only fallback).
- Standalone skills never create or write config. Only `/bob` (first run in a repo without `<root>/config.md`) or `/bob setup` creates it, via [SETUP.md](SETUP.md).
- `GLOSSARY.md` and `adr/` are created lazily by `/domain-modeling`, in `<root>` only: never in the working repo, never in `default/`.
- Missing glossary or ADRs: proceed silently.
