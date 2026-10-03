#!/usr/bin/env bash
# Mechanical checks for a test-review run-N.md. Prints FAIL/WARN lines; exit 1 on any FAIL.
# Usage: check-run.sh <run-N.md> <practices.md> [<repo dir>] [<base_sha>] [<head_sha>]
set -u
RUN=${1:?run-N.md}; PRACT=${2:?practices.md}; REPO=${3:-}; BASE=${4:-}; HEAD_SHA=${5:-}
fail=0; f(){ echo "FAIL: $*"; fail=1; }; w(){ echo "WARN: $*"; }

# 1. Frontmatter: first line ---, required keys, no placeholders
[ "$(sed -n 1p "$RUN")" = "---" ] || f "file does not start with frontmatter"
FM=$(awk 'NR==1{next} /^---$/{exit} {print}' "$RUN")
for k in run date target reviewed_sha base_sha pipeline verdict confidence; do
  echo "$FM" | grep -qE "^$k: *[^ <]" || f "frontmatter missing or placeholder: $k"
done
echo "$FM" | grep -qE '^reviewed_sha: *[0-9a-f]{40}$' || f "reviewed_sha is not a full 40-char sha"
if [ -n "$HEAD_SHA" ]; then
  echo "$FM" | grep -q "^reviewed_sha: *$HEAD_SHA" || f "reviewed_sha differs from MR sha $HEAD_SHA"
fi
echo "$FM" | grep -qE '^verdict: *(ready|needs-tests|needs-test-fixes)$' || f "verdict not one of ready|needs-tests|needs-test-fixes"

# 2. Mandatory sections
for h in "Verdict" "Coverage matrix" "Test quality findings" "Suggested tests" "Verification" "Quick wins" "Larger follow-ups" "Findings ledger" "Repo test practices"; do
  grep -qE "^## $h" "$RUN" || f "missing section: ## $h"
done
grep -q '<!--' "$RUN" && w "template comments left in the report"
grep -qE '^\| *<|<one paragraph|<yyyy-mm-dd>|<k>/<n>' "$RUN" && f "template placeholders left in the report"

# 3. Verification lines
for l in "Hunks:" "Sweeps:" "Local unit runs" "Mutations:" "Warnings in run" "CI pipeline" "Author claims" "Unverified"; do
  n=$(grep -cE "^- $l" "$RUN")
  [ "$n" -ge 1 ] || f "Verification missing line: - $l"
  [ "$n" -le 1 ] || f "Verification line duplicated: - $l ($n times)"
done

# 4. Every hunk has a mutation or a reason
VER=$(awk '/^## Verification/{p=1;next} /^## /{p=0} p' "$RUN")
HUNKS=$(echo "$VER" | grep -oE '\bH[0-9]+\b' | sort -u)
[ -z "$HUNKS" ] && f "no H<n> hunks enumerated"
MUT=$(echo "$VER" | grep -E '^- Mutations')
for h in $HUNKS; do
  echo "$MUT" | grep -qE "\($h\)|$h: *not mutated|$h[^0-9].*not mutated" || f "$h has no mutation result and no 'not mutated' reason"
done
echo "$MUT" | grep -qE '[0-9]+/[0-9]+[^.;]{0,40}fail' || f "Mutations line has no k/n fail counts"

# 5. Two local runs with identical totals
RUNS=$(echo "$VER" | grep -E '^- Local unit runs')
NUMS=$(echo "$RUNS" | grep -oE 'Tests +[0-9]+ passed \(([0-9]+)\)|[0-9]+/[0-9]+' | grep -oE '\(([0-9]+)\)|/[0-9]+' | tr -d '(/)' )
CNT=$(echo "$NUMS" | grep -c . || true)
[ "$CNT" -ge 2 ] || f "Local unit runs: fewer than two summary totals quoted"
[ "$(echo "$NUMS" | sort -u | grep -c .)" -le 2 ] || w "Local unit runs: totals differ across quoted runs; same set must run twice"
echo "$RUNS" | grep -qE '\(b\)' || f "Local unit runs: files (b) (tests importing changed modules) not listed"
echo "$RUNS" | grep -qiE '\(b\)[^;.]*none' && f "(b) reported as none; paste the grep output instead"

# 6. Sweeps: three sweeps, per-caller (a)/(b) answers, counted duplication
SW=$(awk '/^- Sweeps:/{p=1;print;next} /^- /{p=0} p' "$RUN")
echo "$SW" | grep -qiE 'deleted|weakened' || f "Sweeps: deleted/weakened tests sweep missing"
echo "$SW" | grep -qiE 'callers? of' || f "Sweeps: caller sweep missing"
echo "$SW" | grep -qE '\(a\)' && echo "$SW" | grep -qE '\(b\)' || f "Sweeps: caller sweep lacks per-caller (a)/(b) answers"
echo "$SW" | grep -qiE 'shared (vi\.mock )?targets|scaffolding|siblings' || f "Sweeps: scaffolding-vs-siblings sweep missing"
echo "$SW" | grep -qiE '0 shared|no duplication' && w "Sweeps: zero duplication claimed; the comm command output must be quoted right after it"

# 7. Warnings line (noise in a passing run)
echo "$VER" | grep -qiE '^- Warnings in run' || f "Verification missing line: - Warnings in run output: <count or 0>"

# 8. Type column values must exist in practices.md
TYPES=$(awk '/^## Coverage matrix/{p=1;next} /^## /{p=0} p && /^\|/ && !/^\| *Behaviour/ && !/^\|-/' "$RUN" | awk -F'|' 'NF>=6{gsub(/^ +| +$/,"",$5); print tolower($5)}' | sort -u)
for t in $TYPES; do
  case "$t" in "") ;; *) grep -qi -- "$t" "$PRACT" || f "matrix Type '$t' is not a level named in practices.md";; esac
done
grep -qiE '\| *not testable *\(no assertion target' "$RUN" && f "'not testable (no assertion target)' is not a valid reason; accessible names are testable via role queries"

# 9. Ledger covers every finding id
IDS=$(grep -oE '\bF[0-9]+\b' "$RUN" | sort -u)
LED=$(awk '/^## Findings ledger/{p=1;next} /^## /{p=0} p' "$RUN")
for i in $IDS; do echo "$LED" | grep -q "| *$i *|" || f "finding $i missing from Findings ledger"; done
echo "$LED" | grep -qE '\| *\(?(Critical|required|Optional|Nit|FYI)\)? *\|' || f "ledger has no severity labels"

# 10. Paths named in the report exist (basename check against git ls-files or diff)
if [ -n "$REPO" ] && git -C "$REPO" rev-parse >/dev/null 2>&1; then
  FILES=$(git -C "$REPO" ls-files | sed 's#.*/##' | sort -u)
  for p in $(grep -oE '[A-Za-z0-9_./-]+\.(ts|tsx|vue|js|py|cs|json|lockb)\b' "$RUN" | sed 's#.*/##' | sort -u); do
    echo "$FILES" | grep -qx -- "$p" || f "path named in report not in repo: $p"
  done
  if [ -n "$BASE" ] && [ -n "$HEAD_SHA" ]; then
    EXC=$(awk '/^Excluded:/{print}' "$RUN" | grep -oE '[A-Za-z0-9_./-]+\.[a-z]+' | sed 's#.*/##' | sort -u)
    DIFF=$(git -C "$REPO" diff --name-only "$BASE" "$HEAD_SHA" | sed 's#.*/##' | sort -u)
    for p in $EXC; do echo "$DIFF" | grep -qx -- "$p" || f "Excluded names a file not in the diff: $p"; done
    # 11. Each changed production module's own test suite must be in the local run set
    RUNLINE=$(grep -E '^- Local unit runs' "$RUN")
    for src in $(git -C "$REPO" diff --name-only "$BASE" "$HEAD_SHA" | grep -vE '__tests__|\.test\.|\.spec\.|/e2e/'); do
      stem=$(basename "$src"); stem=${stem%.*}
      for t in $(git -C "$REPO" ls-files | grep -E "(^|/)${stem}\.[a-zA-Z.]*test\.[a-z]+$"); do
        echo "$RUNLINE" | grep -q -- "$(basename "$t")" || f "direct suite of changed module not in local run set: $t"
      done
    done
  fi
fi

[ $fail -eq 0 ] && echo "OK: all checks passed"
exit $fail
