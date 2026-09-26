#!/usr/bin/env bash
# Four installation scenarios: catalog skills repo / standalone git repo, with and without skills CLI.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
NAME=git-github-gitlab
PASS=0
SKIP=0

make_source() {
    local layout="$1"
    local dir="$WORK/$layout"
    local skill="$dir"
    if [[ "$layout" == catalog ]]; then skill="$dir/skills/$NAME"; fi
    mkdir -p "$skill/scripts"
    cp "$ROOT/SKILL.md" "$skill/SKILL.md"
    cp "$ROOT/scripts/git-router.sh" "$skill/scripts/git-router.sh"
    chmod +x "$skill/scripts/git-router.sh"
    git -C "$dir" init -q
    git -C "$dir" -c user.name=Test -c user.email=test@example.com add .
    git -C "$dir" -c user.name=Test -c user.email=test@example.com commit -qm fixture
}

check_installed() {
    local path="$1"
    [[ -f "$path/SKILL.md" && -f "$path/scripts/git-router.sh" ]]
    grep -q '^name: git-github-gitlab$' "$path/SKILL.md"
    bash "$path/scripts/git-router.sh" version >/dev/null
}

manual_case() {
    local layout="$1"
    local source="$WORK/$1" dest="$WORK/manual-$1/.agents/skills/$NAME"
    if [[ "$layout" == catalog ]]; then source="$source/skills/$NAME"; fi
    mkdir -p "$(dirname "$dest")"
    cp -R "$source" "$dest"
    check_installed "$dest"
    echo "PASS: без CLI, $layout"
    PASS=$((PASS + 1))
}

cli_case() {
    local layout="$1"
    local project="$WORK/cli-$1"
    mkdir -p "$project"
    (cd "$project" && "$SKILLS_CLI" add "$WORK/$layout" --skill "$NAME" --agent codex --copy --yes >/dev/null)
    check_installed "$project/.agents/skills/$NAME"
    echo "PASS: skills CLI, $layout"
    PASS=$((PASS + 1))
}

make_source catalog
make_source standalone
manual_case catalog
manual_case standalone

if [[ -n "${SKILLS_CLI:-}" ]]; then
    [[ -x "$SKILLS_CLI" ]] || { echo "FAIL: SKILLS_CLI is not executable" >&2; exit 1; }
    cli_case catalog
    cli_case standalone
else
    echo 'SKIP: 2 CLI scenarios (set SKILLS_CLI to an installed skills executable)'
    SKIP=2
fi

echo "Installation scenarios: $PASS passed, $SKIP skipped"
