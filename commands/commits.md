---
description: Create atomic semantic commits from an OpenSpec active change. Maps tasks to conventional commits.
allowed-tools: Bash(git *), Bash(openspec *), Bash(cat *), Bash(grep *), Bash(sed *), Bash(awk *), Read, Write
---

# /commits — Create Atomic Commits from OpenSpec Change

Create atomic semantic commits based on an OpenSpec active change's completed tasks.

## Overview

1. Validate environment (git repo, OpenSpec CLI, pending changes)
2. Select the active OpenSpec change
3. Parse tasks from the change
4. Generate commit plan from completed tasks
5. **Ask user for confirmation**
6. Create atomic commits
7. Verify and report results

---

## Step 1: Validate Environment

**Agent Action**: Verify prerequisites. Stop with clear error if any fail.

**Checklist**:
- [ ] In a git repository (`git rev-parse --git-dir`)
- [ ] OpenSpec CLI available (`command -v openspec`)
- [ ] Working tree has changes (`git status --porcelain`)

**On Failure**:
- Not a git repo → "Error: Not in a git repository. Navigate to a git repository and try again."
- OpenSpec not found → "Error: OpenSpec CLI not found. Ensure openspec is installed."
- No changes → "Error: Working tree clean - nothing to commit. Make changes first."

---

## Step 2: Select OpenSpec Change

**Agent Action**: List changes and auto-select or prompt user.

**Logic**:
1. Run: `openspec list --json`
2. Parse and count active changes (filter out archived)
3. **Decision**:
   - 0 changes → Stop: "No active OpenSpec changes. Create one with `openspec new change '<name>'`"
   - 1 change → Auto-select it, report: "Using change: {name}"
   - 2+ changes → **Ask user**: "Multiple active changes found. Which one?" (list them numbered)

**Reference** (for parsing JSON):
```bash
# Extract change names from JSON
CHANGES=$(openspec list --json 2>/dev/null)
echo "$CHANGES" | grep -o '"name": "[^"]*"' | cut -d'"' -f4
```

---

## Step 3: Get Change Details

**Agent Action**: Load change status and tasks.

**Steps**:
1. Run: `openspec status --change "$CHANGE_NAME" --json`
2. Extract `schemaName` from JSON
3. Locate tasks file: `openspec/changes/{change_name}/tasks.md`
4. Verify file exists (stop with error if not)

**Report**:
- Schema being used
- Tasks file location
- Total tasks count

---

## Step 4: Parse Tasks

**Agent Action**: Read and analyze tasks file.

**Steps**:
1. Read `tasks.md` content
2. Count tasks by status:
   - Completed: lines matching `- [x]`
   - Pending: lines matching `- [ ]`
3. **Decision**: If 0 completed tasks → Stop: "No completed tasks found. Complete tasks in tasks.md first."

**Report**:
```
=== Tasks Summary ===
Total: {N} | Completed: {N} | Pending: {N}

=== Completed Tasks ===
1. [task description]
2. [task description]
...
```

---

## Step 5: Analyze Git State

**Agent Action**: Check what files have been modified.

**Steps**:
1. Get current branch: `git branch --show-current`
2. Get changed files: `git status --short`
3. Get stats: `git diff --stat`

**Report**:
```
=== Git Status ===
Branch: {branch}
Modified: {N} | Added: {N} | Deleted: {N}

=== Changed Files ===
[git status --short output]
```

---

## Step 6: Generate Commit Plan

**Agent Action**: Create plan mapping completed tasks to commits.

**Determine Commit Type**:
- Check `$CHANGE_NAME` for keywords:
  - Contains "fix", "bug", "hotfix" → type: `fix`
  - Contains "doc", "readme" → type: `docs`
  - Contains "test", "spec" → type: `test`
  - Contains "refactor", "cleanup" → type: `refactor`
  - Default → type: `feat`

**Determine Scope** (from task descriptions):
- Keywords "api", "route", "endpoint" → scope: `api`
- Keywords "ui", "component", "page" → scope: `ui`
- Keywords "db", "model", "migration" → scope: `db`
- Keywords "test", "spec" → scope: `test`
- Keywords "doc", "readme" → scope: `docs`
- Default → no scope

**Build Commit Messages**:
- Format with scope: `{type}({scope}): {task description}`
- Format without scope: `{type}: {task description}`
- Truncate to 72 characters max

**Report - Commit Plan**:
```
=== Commit Plan ===
Base type: {feat|fix|refactor|docs|test}

Planned commits:
1. {type}({scope}): {description}
2. {type}({scope}): {description}
...
```

---

## Step 7: User Confirmation

**Agent Action**: **Must ask user before creating commits.**

**Ask**:
```
Create {N} atomic commits as listed above?

Options:
- [Y] Yes, create all commits
- [n] No, cancel
- [s] Show which files will be included in each commit
- [e] Edit commit messages first

Proceed? [Y/n/s/e]:
```

**Handle Response**:
- `Y` or Enter → Continue to Step 8
- `n` → Stop: "Cancelled. No commits created."
- `s` → Show file mapping, then re-ask
- `e` → Allow editing commit messages, then re-ask

---

## Step 8: Create Commits

**Agent Action**: Create atomic commits for each completed task.

**For Each Completed Task**:
1. Stage changes: `git add -A` (or specific files if clearly mapped)
2. Check if staged files exist: `git diff --cached --name-only`
3. If no staged files → Skip with message: "No changes for: {task}"
4. Create commit: `git commit -m "{message}"`
5. Report: "✓ Created: {message}" or "✗ Failed: {error}"

**Important**:
- If a commit fails, stop and report the error
- Do not continue with remaining commits on failure
- Allow user to fix issue and retry

---

## Step 9: Verify Results

**Agent Action**: Show summary of what was created.

**Steps**:
1. Count created commits: `git log --oneline -{N}`
2. Show commit log

**Report**:
```
=== Commits Created ===
{commit hash} {message}
{commit hash} {message}
...

=== Summary ===
Change: {change_name}
Commits created: {N}
Branch: {branch}
```

---

## Complete Flow

```
Step 1: Validate → Stop on any error
    ↓
Step 2: Select change → Auto-select or prompt user
    ↓
Step 3: Load details → Report schema + tasks file
    ↓
Step 4: Parse tasks → Stop if 0 completed
    ↓
Step 5: Git status → Report branch + files
    ↓
Step 6: Generate plan → Show planned commits
    ↓
Step 7: **User confirmation** → Must approve
    ↓
Step 8: Create commits → One per task
    ↓
Step 9: Verify → Show results
```

---

## Error Handling

| Error | Action |
|-------|--------|
| Not a git repo | Stop: "Navigate to a git repository" |
| OpenSpec not initialized | Stop: "Run `openspec init` first" |
| No active changes | Stop: "Create a change with `openspec new change '<name>'`" |
| No changes to commit | Stop: "Make some changes first" |
| No completed tasks | Stop: "Complete tasks in tasks.md first" |
| Multiple changes | Prompt user to select |
| Commit fails | Stop, report error, don't continue |

---

## Reference: Conventional Commits

Format: `type(scope): subject` (max 72 chars)

**Types**:
- `feat` - New feature
- `fix` - Bug fix
- `refactor` - Code restructuring
- `docs` - Documentation
- `test` - Tests
- `chore` - Build/tooling

**Scopes** (auto-detected from task):
- `api` - API/routes
- `ui` - Components/pages
- `db` - Database/migrations
- `test` - Test files
- `docs` - Documentation

---

## Reference: File Paths

```
openspec/
└── changes/
    └── {change_name}/
        ├── change.md
        ├── tasks.md          ← Read this
        ├── design.md
        └── plan.md
```

---

## Reference: OpenSpec Commands

```bash
# List active changes
openspec list --json

# Get change status
openspec status --change "{name}" --json

# Tasks are in
openspec/changes/{name}/tasks.md
```
