#!/usr/bin/env bash
# Generates a project from the working tree of this template, then checks that
# it works: linting, tests, a real run of each specification, and copier update.
#
#   scripts/check-template.sh FLAVOR [--mlboard YAML_LIST] [--carbon] [--keep]
set -euo pipefail

flavor=${1:?usage: check-template.sh FLAVOR [--mlboard YAML_LIST] [--carbon] [--keep]}
shift
mlboard="[]"
carbon=false
keep=false
while [ $# -gt 0 ]; do
    case "$1" in
    --mlboard) mlboard=$2; shift 2 ;;
    --carbon) carbon=true; shift ;;
    --keep) keep=true; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
if [ "$keep" = true ]; then
    echo "Keeping $work"
else
    trap 'rm -rf "$work"' EXIT
fi

# The answer files and the commits need a git identity on CI
export GIT_AUTHOR_NAME=check GIT_AUTHOR_EMAIL=check@example.com
export GIT_COMMITTER_NAME=check GIT_COMMITTER_EMAIL=check@example.com

step() { printf '\n=== %s\n' "$*"; }
fail() { echo "FAILED: $*" >&2; exit 1; }

step "Snapshot of the template (committed and uncommitted changes)"
template=$work/template
mkdir "$template"
(cd "$root" && git ls-files -co --exclude-standard -z | xargs -0 tar cf - 2>/dev/null) | tar xf - -C "$template"
git -C "$template" init -q -b main
git -C "$template" add -A
git -C "$template" commit -qm "chore: snapshot" --no-verify
git -C "$template" tag v0.0.1

step "Generate ($flavor, mlboard=$mlboard, carbon=$carbon)"
project=$work/project
uvx copier copy --defaults --vcs-ref=HEAD \
    --data project_name=check-project \
    --data 'description=A generated project' \
    --data "flavor=$flavor" \
    --data "mlboard=$mlboard" \
    --data "carbon=$carbon" \
    --data experiment_name=first \
    --data 'specifications=[debug, small, full]' \
    "$template" "$project"
cd "$project"

for f in experiments/first/{run.py,common.yaml,debug.yaml,small.yaml,full.yaml} \
    src/check_project/tasks.py tests/test_experiment.py .copier-answers.yml; do
    [ -f "$f" ] || fail "$f was not generated"
done
if [ "$flavor" = basic ]; then
    [ ! -e experiments/first/pre_experiment.py ] || fail "pre_experiment.py in basic flavor"
else
    [ -f experiments/first/pre_experiment.py ] || fail "pre_experiment.py is missing"
fi

git init -q -b main
git add -A
git commit -qm "feat: generated project" --no-verify

step "Install"
uv sync

if [ "$flavor" = ir ]; then
    step "The IR packages can be imported"
    uv run python -c "import datamaestro_ir, xpmir"
fi

step "Lint"
uv run ruff check
uv run ruff format --check
uv run pre-commit run --all-files

step "Tests (dry run of each specification)"
uv run pytest

step "Run each specification with experimaestro"
# An empty configuration: the results must not depend on the local launchers.py
config=$work/xpm-config
mkdir "$config"
for spec in debug small full; do
    workdir=$work/xp-$spec
    uv run experimaestro run --xpm-config-dir "$config" --workdir "$workdir" "experiments/first/$spec.yaml"
    results=$(find "$workdir" -name results.csv | wc -l | tr -d ' ')
    if [ "$spec" = debug ]; then expected=1; else expected=3; fi
    [ "$results" = "$expected" ] || fail "$spec: $results results.csv file(s), expected $expected"
    grep -qx '2,4' <<<"$(find "$workdir" -name results.csv -exec cat {} +)" || fail "$spec: wrong results"
done

step "Run again: jobs that are done are not submitted again"
before=$(find "$work/xp-debug" -name results.csv -exec cat {} + | wc -l)
stamp=$(find "$work/xp-debug" -name results.csv -exec stat -c %Y {} + 2>/dev/null ||
    find "$work/xp-debug" -name results.csv -exec stat -f %m {} +)
sleep 1
uv run experimaestro run --xpm-config-dir "$config" --workdir "$work/xp-debug" experiments/first/debug.yaml
stamp2=$(find "$work/xp-debug" -name results.csv -exec stat -c %Y {} + 2>/dev/null ||
    find "$work/xp-debug" -name results.csv -exec stat -f %m {} +)
[ "$stamp" = "$stamp2" ] || fail "the job was run again"
[ "$before" = "$(find "$work/xp-debug" -name results.csv -exec cat {} + | wc -l)" ] || fail "results changed"

step "copier update changes the tooling only"
git add -A
git diff --cached --quiet || git commit -qm "chore: lock" --no-verify
echo "# my plan" >>experiments/first/run.py
git add -A
git commit -qm "feat: my experiment" --no-verify
plan=$(cat experiments/first/run.py)

echo "# template update" >>"$template/template/cliff.toml.jinja"
echo "# template update" >>"$template/template/experiments/{{ experiment_name }}/run.py.jinja"
git -C "$template" add -A
git -C "$template" commit -qm "chore: update" --no-verify
git -C "$template" tag v0.0.2

uvx copier update --defaults --vcs-ref=HEAD
grep -q "# template update" cliff.toml || fail "cliff.toml was not updated"
[ "$plan" = "$(cat experiments/first/run.py)" ] || fail "experiments/first/run.py was changed"
if git status --short | grep -q '\.rej$'; then fail "copier update left conflicts"; fi

step "All checks passed"
