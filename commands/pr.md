---
description: Create a GitHub PR with a rich, template-aware description. Checks for PR templates, analyzes diff, pushes branch, and opens PR.
allowed-tools: Bash(git *), Bash(gh *), Bash(cat *), Read, Write
---

# /pr — Create Pull Request

Create a GitHub pull request with a meaningful, template-aware description.

**AGENT RULES — read before executing:**

1. **Shell state does NOT persist** between `Bash` tool calls. Each bash block must re-derive every variable it needs (branch name, base ref, etc.).
2. **YOU write the PR description** using the `Write` tool — do NOT generate PR body via bash heredocs. Your intelligence is the value here.
3. **Fill the template properly** — replace every placeholder with real content based on the diff. Never leave italic placeholder text in the output.
4. **Do NOT append extra sections** (like "Change Summary", "Files Changed", "Related") to the template. Only output what the template defines.
5. **Stop on FATAL_ERROR** — show the error to the user.

---

## Step 1: Validate and Gather Context

Run this single block to validate prerequisites and collect everything needed.

**Tool:** `Bash`
**Command:**

```bash
# --- Prerequisites ---
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "FATAL_ERROR: Not in a git repository"; exit 1
fi
if ! command -v gh &> /dev/null; then
  echo "FATAL_ERROR: gh CLI not installed — https://cli.github.com/"; exit 1
fi
if ! gh auth status > /dev/null 2>&1; then
  echo "FATAL_ERROR: Not authenticated with gh CLI — run: gh auth login"; exit 1
fi

# --- Branch ---
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
  echo "FATAL_ERROR: Detached HEAD — checkout a branch first"; exit 1
fi

git fetch origin --prune 2>/dev/null

if git show-ref --verify --quiet refs/remotes/origin/main; then
  BASE_NAME="main"
elif git show-ref --verify --quiet refs/remotes/origin/master; then
  BASE_NAME="master"
else
  BASE_NAME=$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')
  if [ -z "$BASE_NAME" ]; then
    echo "FATAL_ERROR: Could not determine base branch"; exit 1
  fi
fi
BASE_REF="origin/$BASE_NAME"

if [ "$CURRENT_BRANCH" = "$BASE_NAME" ]; then
  echo "FATAL_ERROR: You are on '$BASE_NAME'. Create a feature branch first."; exit 1
fi

MERGE_BASE=$(git merge-base "$BASE_REF" HEAD 2>/dev/null || echo "")
if [ -z "$MERGE_BASE" ]; then
  echo "FATAL_ERROR: No common ancestor with $BASE_REF"; exit 1
fi

# --- Change Detection ---
COMMITS_AHEAD=$(git rev-list --count "$BASE_REF"..HEAD 2>/dev/null || echo "0")

echo "=== BRANCH ==="
echo "CURRENT=$CURRENT_BRANCH"
echo "BASE=$BASE_NAME"
echo "COMMITS_AHEAD=$COMMITS_AHEAD"

if [ "$COMMITS_AHEAD" -eq 0 ]; then
  echo ""
  echo "FATAL_ERROR: Branch '$CURRENT_BRANCH' has 0 commits ahead of '$BASE_NAME'."
  echo "Possible causes:"
  echo "  - Branch was already merged into $BASE_NAME"
  echo "  - Changes haven't been committed yet"
  echo "  - Wrong branch checked out"
  if [ -n "$(git status --porcelain 2>/dev/null | head -1)" ]; then
    echo ""
    echo "You have uncommitted changes — commit them first:"
    git status --short
  fi
  exit 1
fi

# --- Uncommitted Warning ---
UNCOMMITTED=$(git status --porcelain 2>/dev/null | head -5)
if [ -n "$UNCOMMITTED" ]; then
  echo ""
  echo "=== WARNING: UNCOMMITTED CHANGES (not included in PR) ==="
  echo "$UNCOMMITTED"
fi

# --- Commits ---
echo ""
echo "=== COMMITS ==="
git log --no-merges --pretty=format:'%h %s' "$BASE_REF"..HEAD

# --- Diff Stats ---
echo ""
echo "=== DIFF_STATS ==="
git diff --stat "$MERGE_BASE"..HEAD

# --- Files Changed ---
echo ""
echo "=== FILES_CHANGED ==="
git diff --name-status "$MERGE_BASE"..HEAD

# --- Diff (truncated to avoid context overflow) ---
echo ""
echo "=== DIFF ==="
git diff "$MERGE_BASE"..HEAD | head -3000 || true

# --- Issue References ---
echo ""
echo "=== REFS ==="
(
  echo "$CURRENT_BRANCH" | grep -oE '(#[0-9]+|[A-Z]+-[0-9]+)' || true
  git log --no-merges --pretty=format:'%s' "$BASE_REF"..HEAD | grep -oE '(#[0-9]+|[A-Z]+-[0-9]+)' || true
) | sort -u | grep -v '^$' || echo "(none)"

# --- PR Template ---
echo ""
echo "=== TEMPLATE ==="
for loc in ".github/pull_request_template.md" ".github/PULL_REQUEST_TEMPLATE.md" "PULL_REQUEST_TEMPLATE.md" "docs/pull_request_template.md"; do
  if [ -f "$loc" ]; then
    echo "FOUND=$loc"
    echo "--- TEMPLATE_CONTENT ---"
    cat "$loc"
    echo ""
    echo "--- END_TEMPLATE ---"
    break
  fi
done

# --- Existing PR ---
echo ""
echo "=== EXISTING_PR ==="
gh pr view "$CURRENT_BRANCH" --json number,url,state,title 2>/dev/null || echo "NONE"

echo ""
echo "CONTEXT_COMPLETE"
```

**On FATAL_ERROR:** Stop and show the error to the user.

---

## Step 2: Generate PR Title and Body

> **THIS IS NOT A BASH STEP.** Use your intelligence to write the content.

### Title

Craft a PR title from the commits and branch name:

- 72 characters max, imperative mood
- Keep conventional commit prefix if present (`feat:`, `fix:`, etc.)
- Do NOT include issue numbers in the title

### Body

**If a TEMPLATE was found**, fill in every section with real content from the diff. Replace ALL italic placeholder text. Do NOT append sections that aren't in the template.

For the Omnia PR template, fill each section as follows:

| Section                    | How to Fill                                                                                                                         |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| **Related PRs** line       | Insert issue/PR refs from REFS output. Write "N/A" if none found.                                                                   |
| **PR Goal**                | 1-3 sentences: what this PR achieves and why. Delete the italic placeholder.                                                        |
| **Implementation details** | Bullet points describing key code changes, files modified, patterns used. Delete the italic placeholder.                            |
| **Testing checklist**      | Check `[x]` boxes that apply based on diff (test files added/modified = check relevant boxes). Leave inapplicable items as `[ ]`.   |
| **Code Quality**           | Check boxes that apply. Leave unchecked if not applicable.                                                                          |
| **UI/Component changes**   | Check "Yes" if `.tsx` component or CSS files changed, "No" otherwise. If "No", remove the Before/After screenshot section entirely. |
| **Code Review Framework**  | Check ONE: "Automate" for small/routine, "Defer" for medium, "Pair" for complex/risky.                                              |

**If NO template was found**, generate:

```
## Summary
<1-3 bullet points of what and why>

## Changes
<key file changes as bullet points>

## Testing
- [ ] Tested locally
- [ ] Added/updated tests
```

### Save Files

Use the `Write` tool to create both:

- `/tmp/pr_title.txt` — the title only (no trailing newline)
- `/tmp/pr_body.md` — the complete body

---

## Step 3: Push and Create/Update PR

**Tool:** `Bash`
**Command:**

```bash
CURRENT_BRANCH=$(git branch --show-current)
PR_TITLE=$(cat /tmp/pr_title.txt)

# Determine base
if git show-ref --verify --quiet refs/remotes/origin/main; then
  BASE_NAME="main"
elif git show-ref --verify --quiet refs/remotes/origin/master; then
  BASE_NAME="master"
else
  BASE_NAME=$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')
fi

# Push
echo "Pushing $CURRENT_BRANCH..."
git push -u origin "$CURRENT_BRANCH" 2>&1
if [ $? -ne 0 ]; then
  echo "FATAL_ERROR: Failed to push branch"; exit 1
fi

# Check for existing PR
EXISTING=$(gh pr view "$CURRENT_BRANCH" --json number,state 2>/dev/null || echo "")
PR_STATE=$(echo "$EXISTING" | grep -o '"state":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "")

if [ -n "$PR_STATE" ] && [ "$PR_STATE" != "MERGED" ] && [ "$PR_STATE" != "CLOSED" ]; then
  echo "Updating existing PR..."
  gh pr edit --title "$PR_TITLE" --body-file /tmp/pr_body.md
  if [ $? -ne 0 ]; then
    echo "FATAL_ERROR: Failed to update PR"; exit 1
  fi
  echo "STATUS=UPDATED"
else
  echo "Creating new PR..."
  gh pr create --title "$PR_TITLE" --body-file /tmp/pr_body.md --base "$BASE_NAME" --head "$CURRENT_BRANCH"
  if [ $? -ne 0 ]; then
    echo "FATAL_ERROR: Failed to create PR"; exit 1
  fi
  echo "STATUS=CREATED"
fi

echo ""
echo "=== RESULT ==="
gh pr view "$CURRENT_BRANCH" --json url,title,number --jq '"PR #\(.number): \(.title)\n\(.url)"'
```

**On failure:** Stop and report error.

---

## Step 4: Open in Browser

**Tool:** `Bash`
**Command:**

```bash
CURRENT_BRANCH=$(git branch --show-current)
PR_URL=$(gh pr view "$CURRENT_BRANCH" --json url --jq '.url' 2>/dev/null)

if [ -n "$PR_URL" ]; then
  if command -v open &> /dev/null; then
    open "$PR_URL"
  elif command -v xdg-open &> /dev/null; then
    xdg-open "$PR_URL"
  fi
  echo "PR_URL=$PR_URL"
else
  echo "Could not retrieve PR URL"
fi

echo "DONE"
```

---

## Output

After all steps, show the user:

```
PR Complete

Title: <title>
URL: <url>
Base: <base> <- <branch>
Status: Created | Updated
```
