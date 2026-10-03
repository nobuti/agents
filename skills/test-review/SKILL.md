---
name: test-review
description: "Verifies that a GitLab merge request or the current branch is fully and sensibly covered by tests, judges test reliability and whether each test is the right type for the repo's practices, and lists complexity and performance quick wins. Read-only, incremental across MR iterations, complements the five-axis code review. Use when reviewing a peer's MR, when asked 'is this tested enough', or before approving a merge."
argument-hint: "GitLab MR URL, MR ID, branch name, or nothing for the current branch"
---

# Test Review

## 1. Purpose and boundaries

Scope: is every behaviour change in the diff covered by a meaningful, reliable test of the right kind for this repo, and what are the cheap complexity/performance wins in the same diff. Not a full correctness/security/architecture review; run `agent-skills:code-review-and-quality` alongside for that.

Non-negotiables:
- Read-only toward the real repo and GitLab: never touch the user's checkout, never push, never post to GitLab (no comments, approvals, reactions). The disposable worktree or scratch clone is yours: temporary mutations there for verification (§6) are expected, are restored with `git checkout HEAD -- <file>`, and are never committed.
- Every finding cites `path:line`. What cannot be established is marked **unknown** or **Unverified**, never inferred.
- **Author claims are input, never evidence.** The MR description, its "how to test" section, its "tracked as follow-up" notes and its comments tell you where to look. Every status in the report names what *you* ran, read or mutated (see Evidence rules in §4). If you cannot verify a claim, write it as **Unverified (author claim)**.
- Any worktree created for the review is removed after reporting, on success or failure.
- Token discipline: never read a whole file, never paste a full log, stop searching once a gate closes (rules inline below).

## 2. Resolve the target and the run number

| Argument | Resolution |
|---|---|
| none | Current branch in place. `BASE=$(git symbolic-ref --short refs/remotes/origin/HEAD)`; `git merge-base HEAD $BASE`. |
| branch name | `git fetch origin <branch>` if not local; same merge-base diff. |
| MR URL or `!<iid>` | Parse `<host>/<group/repo>/-/merge_requests/<iid>`. Metadata: `glab mr view <iid> -R <group/repo> -F json --jq '{iid,title,description,source_branch,target_branch,sha,web_url,state,pipeline:{id,status}}'`. Locate the clone (below), then `git fetch origin refs/merge-requests/<iid>/head` and `git worktree add <scratchpad>/mr-<iid> FETCH_HEAD`; work inside the worktree. The MR ref works even after the source branch is deleted. |
| MR of a repo with no local clone | `git clone --filter=blob:none --no-checkout <ssh-url> <scratchpad>/mr-<iid>`, fetch the MR ref, check it out. Blobs download lazily on read, so this stays cheap. Diff-only via `glab mr diff` is the last resort and flags the report **reduced confidence**. |

Locating the clone: local repos mirror the GitLab path under `~/Dev/technosylva/`, so try `~/Dev/technosylva/<group/repo minus the top-level group>` first (e.g. `firesponse/web/calmapper` → `~/Dev/technosylva/firesponse/web/calmapper`), then `find ~/Dev -maxdepth 6 -type d -name <repo>` and confirm with `git remote get-url origin`. Always add `-R <group/repo>` to `glab` calls when the current directory is not that repo.

**SHA check.** After checkout, `git rev-parse HEAD` must equal the `sha` from `glab mr view`. If it does not (wrong ref, a locally re-created commit, the `/merge` ref), stop and fix the checkout; never review a commit the MR does not point at. `reviewed_sha` in the report is that verified value.

Storage root: `~/Dev/artifacts/test-review/<folder>/` (create if missing).

| Target | Folder |
|---|---|
| MR | First `ls -d …/test-review/mr-<iid>-*` and reuse the match. Otherwise `mr-<iid>-<slug>` with `slug=$(printf '%s' "$title" \| tr '[:upper:]' '[:lower:]' \| sed -E 's/[^a-z0-9]+/-/g; s/^-+\|-+$//g' \| cut -d- -f1-6)` |
| Local branch | `yyyy-mm-dd-<branch-slug>`; before creating, reuse an existing folder ending in `-<branch-slug>` so a branch reviewed across days keeps one history |

Nothing else is created under the storage root: no scratch folders, no copies of the repo.

`N` = highest existing `run-*.md` + 1 (1 for a new folder). N>1 is an **incremental run**, see §8.

Cleanup once `run-N.md` is written: `git worktree remove <scratchpad>/mr-<iid>` (worktree) or `rm -rf <scratchpad>/mr-<iid>` (scratch clone), after `git status --short` confirms nothing was left modified.

## 3. Learn how this repo tests

Practices belong to the repo, not the MR: the file is `~/Dev/artifacts/test-review/practices/<group-repo-slug>.md` (e.g. `firesponse-web-calmapper.md`). If it exists, read it and skip this step, whatever `N` is; refresh it only when `package.json` scripts, the test config or the CI file changed in this diff. Each run folder gets no copy, only the link in its "Repo test practices" section.

Establish from `package.json`/`Makefile`/`pyproject.toml`/`go.mod`/etc., `.gitlab-ci.yml`, and a grep of test file names and imports (never full test files):
- runner, config, and the **focused-test command** with a quiet reporter;
- CI job names per level (unit / integration / e2e) and what triggers them;
- where each test type lives, file naming, fixture/factory and mocking conventions (which boundaries neighbours mock);
- coverage tooling and thresholds, `CONSTRAINTS.md` if present.

Write the result to that practices file: short, table-heavy, cited with `path:line`. Detail on stack discovery: `agent-skills:test-driven-development`, "Discover the Stack First".

Optional fan-out, run 1 only, at most two Explore agents in parallel: (a) produce the practices file; (b) map changed symbols to existing tests that exercise them. Each returns a compact table, never file contents. The sequential single-agent path must still work.

## 4. Coverage matrix (gate)

Read order, always:
1. `git diff --stat <base>...HEAD`; drop lockfiles, generated, vendored, snapshot and pure-formatting files, list them under Excluded.
2. `git diff -U3 <base>...HEAD -- <paths>` per file group.
3. grep/ripgrep changed symbol names across test directories to shortlist candidate tests.
4. `Read` only the `offset`/`limit` range that confirms a test exercises the behaviour.

First enumerate the production hunks as `H1..Hn` (file, lines, one-line summary). This list is copied into Verification and every `H` gets a mutation result in §6 or a stated reason.

For each hunk list its behavioural units (new/changed function, branch, error path, behaviour-altering config) as rows. When a hunk sets or clears several fields, copy the field list from the code into the row; never summarise "all N fields" from memory (one missed field means one untested behaviour):

| Behaviour | path:line | Covered by | Type | Status |
|---|---|---|---|---|
| what changed | `file:line` | `test_file::test_name` or — | one of the levels named in the practices file | covered / partial / uncovered / not testable (reason) |

Rules: every behavioural unit gets a row; "not testable" needs a reason; deleted production code is listed under Excluded, not as a row. `Type` uses only the levels the repo actually has (a repo with unit + e2e has no "integration" row). Every path in the report, including Excluded, must come from `git diff --name-only <base>...HEAD` or from a grep/ls you ran; a file you remember from other repos does not exist here. Once every hunk has a row, stop searching for tests.

Three mandatory sweeps before the gate closes. Each produces rows or findings, never a mental note:

1. **Deleted and weakened tests.** Run:
   ```
   git diff <base>...HEAD -- '<test dirs>' | grep -E '^-\s*(it|test|describe)\(|^-\s*expect\(|^\+\s*(it|test|describe)\.(skip|only|todo)|^\+.*(eslint-disable|ts-ignore|ts-expect-error)'
   ```
   For every removed test or assertion: is the code it exercised still live (grep the symbols in production)? Is it asserted elsewhere (grep the test tree)? Each removed test becomes a matrix row with status `uncovered` or `partial` unless a replacement in this diff asserts the same behaviour. "Acknowledged as follow-up debt" in the description changes nothing about the row.
2. **Callers of changed functions.** The function list is derived from the `H` hunks, not chosen: every function, action or computed whose definition or body appears in a `+`/`-` line (a function that gained or lost a call inside its body counts, e.g. one that now delegates to a new helper). Name them in the Sweeps line. For each: `grep -rn '<name>(' <src>` outside tests. Read the 5 lines before each call and answer both questions per caller, in writing: `caller path:line → (a) inherits new behaviour: yes/no, which → row; (b) still does work the callee now does: yes/no, which lines → Quick win`. Listing the callers without the two answers is not a sweep.
3. **New test scaffolding versus siblings.** Count shared targets against *every* sibling, do not pick one:
   ```
   N=<new po>; for f in <pageObjects dir>/*.po.ts; do [ "$f" = "$N" ] && continue
     echo "$(LC_ALL=C comm -12 <(grep -oh "vi.mock('[^']*'" "$N" | LC_ALL=C sort -u) <(grep -oh "vi.mock('[^']*'" "$f" | LC_ALL=C sort -u) | wc -l) $f"
   done | sort -rn | head -3
   ```
   Quote the top line in the Sweeps entry. Three or more shared targets with any sibling is duplication and a Larger follow-up, even when each copy is justified; a divergent copy of an existing helper is a finding.

### Evidence rules

A status is only as strong as its evidence. Tag each row's evidence in the Verification section and hold to these minimums:

| Status / claim | Minimum evidence |
|---|---|
| `covered` | A mutation of that behaviour (§6) makes a named test fail, **or** you read the assertion and can quote the line that would fail |
| `partial` | You read the test and can name the branch, field or path it does not assert |
| `uncovered` | Grep of production symbol across the test tree returns nothing relevant |
| "tests pass" | You ran them, twice, and quote the summary line |
| "tests fail without the fix" | You reverted the hunk and ran them; author's statement alone is `Unverified (author claim)` |
| CI job outcome | `glab ci get` output, job named |

Default labels, applied as written, neither softened because the author explains the gap nor inflated for emphasis: deleted tests on live code → *required* (**Critical** only if the lost test guarded data loss, security or money); a store, service or composable behaviour change with no assertion → *required*; a new function proven only indirectly through a heavier suite → **Optional:** direct test; visible noise (warnings, unhandled rejections) in a passing run → **Nit:** with a concrete fix.

## 5. Test quality

For each test in "Covered by" (new or pre-existing), judge:
- **Meaningful**: asserts outcome/state, not call sequences; would fail under a plausible mutation of the changed code (flip the branch, drop the guard); no assertion-free or tautological tests.
- **Reliable**: deterministic (time, randomness, ordering, network); isolated state; no sleeps or retries hiding races; no `skip`/`only`/`xit` left in.
- **Right type and place**: level matches the practices file (pure logic → unit, boundary → integration, critical flow → e2e); conventional directory and naming; mocks only at boundaries neighbours mock.
- **Readable**: spec-like name, visible arrange/act/assert, DAMP over over-DRY.
- **Does not weaken the bar**: no loosened or deleted assertions, lowered thresholds, new lint/type suppressions, or stubbed checks (signals: `agent-skills:constraint-driven-development`).

Rubric detail: `agent-skills:test-driven-development` (anti-patterns, test doubles) and the `test-engineer` persona scenarios.

Label every finding and order by leverage, worst first:

| Label | Meaning |
|---|---|
| **Critical** | Blocks merge: untested behaviour with real risk, or a test that hides a bug |
| *(no prefix)* | Required before merge |
| **Optional:** | Worth doing, not required |
| **Nit:** | Minor, author may ignore |
| **FYI** | Informational |

## 6. Run cheap, read CI for the rest

Run only unit/small tests, with the focused command from the practices file, quiet reporter, twice. The set to run is fixed, not chosen:

```
# (a) test files added or changed in the diff
git diff --name-only <base>...HEAD -- '<test dirs>'
# (b) existing test files that import any changed production module, always including each module's own suite
for m in <changed prod modules, without extension>; do
  find <test dirs> -name "$(basename $m).*test.*"                      # the module's direct suite, e.g. stores/EditionLayerStore.test.ts
  grep -rl "$(basename $m)" <test dirs> --include='*.test.ts'
done | sort -u
<focused-unit-command> <a + b> 2>&1 | tail -40   # run 1
<same command> 2>&1 | tail -40                    # run 2; differing results = flaky
```

A fresh worktree has no `node_modules`; symlink the main checkout's (`ln -s <clone>/frontend/node_modules <worktree>/frontend/node_modules`) instead of installing. Quote both summary lines and paste the file list that (b) returned. "(b) none" is only valid when the grep is shown returning nothing; a changed store or component almost always has an importing suite.

**Mutation check (mandatory when the unit suite runs).** Prove the new or changed tests bite. For each production hunk H1..Hn, inside the worktree or scratch clone only:

```
git diff <base>...HEAD -- <prod-file> | head -60        # find the hunk
<sed or python one-liner that reverts just that hunk>  # or: git checkout <base> -- <prod-file> when the file has a single hunk
<focused-unit-command> <new-or-changed-test-files> 2>&1 | grep -E 'FAIL|Tests ' | head -10
git checkout HEAD -- <prod-file>
```

One mutation per production hunk from the `H` list, plus one per field when a hunk clears several fields (drop one reset at a time). Record `M<n> (H<k>): <what was reverted> → <k>/<total> tests fail`. Zero failures means the behaviour is `partial` at best and is a finding. A hunk without a mutation is written as `H<k>: not mutated, <reason>`. Reverting a whole file is only valid when it contains one hunk; otherwise the tests may fail for an unrelated reason (a removed aria-label breaking a lookup, for instance). Finish with `git status --short` to confirm the tree is restored.

Never run integration/e2e locally. Read their outcome from the MR pipeline:

```
glab ci get --merge-request <iid> -F json --with-job-details --jq '{id,status,jobs:[.jobs[]|{name,stage,status}]}'
glab ci trace <job-name> -p <pipeline-id> 2>&1 | grep -inE 'fail|error|✗' | head -40   # only for a failed job
```

Record which heavy jobs cover the changed area and their status. Anything that could not run or be read is **Unverified**, never "passing".

Warnings or errors printed by a passing run are not benign by default: they are a **Nit:** finding with the one-line fix (missing route, unawaited promise, unstubbed request).

## 7. Quick wins

Diff-scoped only, no drive-by scanning. Two lenses:
- **Complexity**: signals from `agent-skills:code-simplification` step 2 (deep nesting, long functions, nested ternaries, boolean flags, repeated conditionals, generic names, dead code) on changed lines.
- **Performance**: five-axis performance checks and `agent-skills:performance-optimization` (N+1, unbounded loops/fetches, sync work in async or hot paths, hot-path allocations, missing pagination, needless re-renders) on changed lines.

Each item: `path:line`, the signal from the tables above that it matches, the small fix, expected effect. A performance item needs a hot-path argument: how often the code runs and what it costs per run. Memoised values (`computed`, `useMemo`, cached selectors) do not re-run per render and are not findings. If you cannot state frequency and cost, drop the item. Anything larger than a small fix becomes one line under "Larger follow-ups" with the skill to apply.

The caller sweep (§4, sweep 2) is the main source of quick wins: work a caller still does that the changed function now does for it.

## 8. Incremental mode (N > 1)

Read only `run-<N-1>.md` frontmatter and Findings ledger, plus the practices file.

1. If `base_sha` changed (rebase) and `git diff <reviewed_sha>..HEAD` is not a readable delta, do a full re-review and say so in the Verdict.
2. Otherwise diff `<reviewed_sha>..HEAD` only. Re-check ledger items whose files appear in that diff; everything else is copied with status `carried`.
3. Fixed items become `resolved`; new behaviour gets new matrix rows and `new` findings; items the author declined with a reason become `wont-fix`.
4. The report stays self-contained: full matrix (carried rows copied, not re-verified) plus a "Changes since last run" section listing only what moved.

Full re-review otherwise only when the user asks.

## 9. Report template

Write `run-N.md`, then run the checker from the skill's base directory (the path shown when the skill loads):

```
bash <skill base dir>/scripts/check-run.sh <folder>/run-N.md <practices file> <repo dir> <base_sha> <reviewed_sha>
```

Fix every `FAIL` in the file and re-run until it prints `OK`; treat each `WARN` as a question to answer in the report. Then read the file back and make its full content, verbatim, the text of your final message. Tool output (`cat`, `Read`) is not shown to the user; only your message is. No summary, no reordering, nothing dropped. End with one line: "Want me to write the suggested tests?"

```markdown
---
run: <N>
date: <yyyy-mm-dd>
target: <MR url or branch>
reviewed_sha: <head sha>
base_sha: <merge-base>
pipeline: <id/status or unknown>
verdict: <ready | needs-tests | needs-test-fixes>
confidence: <full | reduced>
---

# Test review: <title>  (<source> → <target>, run <N>)

## Verdict
<one paragraph: is the change adequately tested, the one or two findings that decide it>

## Changes since last run        <!-- N > 1 only -->
- resolved / new / carried / wont-fix, one line each with ledger id

## Coverage matrix
| Behaviour | path:line | Covered by | Type | Status |
|---|---|---|---|---|

Excluded: <lockfiles, generated, formatting-only, deleted code>

## Test quality findings
<labelled list, worst first, each with path:line>

## Suggested tests
| Name | Type | Location | Arrange / Act / Assert |
|---|---|---|---|
<!-- one row per uncovered/partial matrix row, each with concrete arrange, act and assert.
     "Restore the N deleted tests" is a follow-up, not a sketch: give at least one full sketch per deleted describe block.
     Sketches follow "What to hold new tests to" in the practices file. If the repo convention is page objects + MSW + real stores,
     a sketch that uses shallowMount, calls vm.<method>() directly, or mocks a service/HTTP layer is wrong even if the
     deleted tests did that: sketch it the way the repo tests today. -->

## Verification
- Hunks: H1 <file:lines summary>; H2 …
- Sweeps: deleted/weakened tests → <k tests, k assertions; rows F…>; callers of <fn> → <path:line (a) … (b) …> per caller; scaffolding vs siblings → <k shared vi.mock targets with <file>>. Write `0 hits` explicitly.
- Local unit runs (×2): <command>, files (a)+(b), run 1 <summary line>, run 2 <summary line>
- Mutations: M1 <reverted what> → <k>/<n> fail; M2 …; (or: not run, reason)
- Warnings in run output: <count, first distinct message, or 0>
- CI pipeline <id>: <job → status, which cover the change>
- Author claims checked: <claim → confirmed by M<n> / contradicted / Unverified (author claim)>
- Unverified: <item, reason>

## Quick wins
- `path:line`, fix, expected effect

## Larger follow-ups
- one line each, with the skill to apply

## Findings ledger
| id | severity | path:line | summary | status |
|---|---|---|---|---|
| F1 | Critical | … | … | open / new / carried / resolved / wont-fix |

## Repo test practices
See `../practices/<group-repo-slug>.md`.
```

## 10. Completion check

- [ ] Target resolved, `git rev-parse HEAD` equals the MR `sha`, folder found by `mr-<iid>-*` or created with the slug recipe, `N` computed, worktree removed, nothing else left under the storage root.
- [ ] Verification lists all three sweeps with hit counts, and the unit run covered files (a) and (b).
- [ ] Every uncovered/partial row has a concrete suggested test; every quick win names its signal and, for performance, frequency and cost.
- [ ] practices file written or reused from `test-review/practices/`.
- [ ] Every behavioural unit has a matrix row or is listed under Excluded.
- [ ] Deleted/weakened tests swept with the grep in §4 and each has a row; callers of every changed function traced; new scaffolding compared with siblings.
- [ ] Every `covered` row is backed by a mutation kill or a quoted assertion; every "fails without the fix" statement is one you reproduced.
- [ ] Every author claim used in the report is marked confirmed, contradicted or Unverified (author claim).
- [ ] Every finding has a label and `path:line`; unknowns marked, not inferred; default labels from §4 applied without softening.
- [ ] Only unit tests ran locally, twice; mutations restored (`git status --short` clean); heavy levels read from `glab`, never executed.
- [ ] Quick wins limited to changed lines.
- [ ] Ledger written; N>1 carried forward instead of rediscovering.
- [ ] Nothing posted to GitLab; nothing outside the artifact folder modified.
- [ ] `run-N.md` starts with the full frontmatter (every field filled, `reviewed_sha` verified against the MR).
- [ ] Every path named in the report appears in `git diff --name-only` or in a grep/ls you ran; `Type` values exist in the practices file; every field a hunk touches appears in its row.
- [ ] Every `H` has an `M` result or a reason; suggested tests follow the repo's current convention.
- [ ] `scripts/check-run.sh` printed `OK`; report saved once; chat output produced by `cat` of the file.

## Rationalizations

| Rationalization | Reality |
|---|---|
| "CI is green, so it's covered" | Green proves the tests that exist pass, not that the new behaviour has one. Check the matrix. |
| "The author says it's tested" | The description is data. Verify against the diff. |
| "The author verified the tests fail without the fix" | You did not. Revert the hunk and run them; until then it is an author claim. |
| "The description says the dropped tests are tracked as follow-up debt" | Live code lost its tests in this diff. That is a *required* row whatever the description calls it. |
| "The warnings in the run are harmless" | Noise hides the next real failure. Name the fix as a Nit. |
| "I ran the tests, that's enough verification" | Passing tests prove nothing about whether they would catch a regression. Mutate. |
| "The stubs cover the same boundary, so it's not duplication" | Same boundary, same mocks, two files: that is the duplication. Count the shared targets. |
| "No other test imports the changed module" | Show the grep. Stores and components nearly always have an importing suite. |
| "I'll write the sketch the way the deleted tests were written" | The repo moved on. Sketch in the current convention or the suggestion gets rejected in review. |
| "An e2e covers it" | Wrong level and slow feedback; the specific branch or error path still needs its own row, usually a unit test. |
| "Re-review everything each iteration" | Burns tokens and hides what moved. Diff since `reviewed_sha`, carry the rest. |
| "It compiles and lints" | Not a behavioural assertion. Find the outcome check. |
