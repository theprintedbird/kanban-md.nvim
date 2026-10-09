#!/bin/sh
# jj-bump-submodule.sh
#
# Move a Git submodule to the tip of a branch and record the new gitlink in
# the parent repository. Run from the parent project's root directory.
#
# The parent is a colocated Jujutsu repo (it has .git next to .jj). jj does
# not snapshot submodule pointer changes, so the commit is made with plain Git
# and jj imports it on its next command. The submodule is assumed to be a
# plain Git checkout (no .jj).
#
# Usage: jj-bump-submodule.sh <submodule-path> <branch>

set -eu

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

info() {
    printf '==> %s\n' "$*"
}

[ "$#" -eq 2 ] || {
    printf 'Usage: %s <submodule-path> <branch>\n' "$0" >&2
    exit 2
}

sub=${1%/}
branch=$2
[ -z $branch ] || branch="master"

# --- Sanity checks on the parent -------------------------------------------

top=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a Git repository"
here=$(pwd -P)
top_real=$(cd "$top" && pwd -P)
[ "$here" = "$top_real" ] || die "run this from the project root ($top_real)"

[ -e .git ] || die "no .git here; for a jj repo run 'jj git colocation enable' first"

# Is it really a submodule (gitlink, mode 160000) in the current index?
mode=$(git ls-files -s -- "$sub" | awk 'NR == 1 { print $1 }')
[ "$mode" = "160000" ] || die "'$sub' is not a submodule recorded in this repository"

# Make sure it is initialised.
if ! git -C "$sub" rev-parse --git-dir >/dev/null 2>&1; then
    info "Initialising submodule"
    git submodule update --init -- "$sub"
fi

# --- Resolve the target commit in the submodule ----------------------------

old=$(git rev-parse "HEAD:$sub" 2>/dev/null || true)

info "Fetching in $sub"
git -C "$sub" fetch --quiet --tags origin ||
    printf 'warning: fetch failed; continuing with what is available locally\n' >&2

# Prefer the remote-tracking branch, fall back to a local branch.
if new=$(git -C "$sub" rev-parse --verify --quiet "refs/remotes/origin/$branch^{commit}"); then
    ref="origin/$branch"
elif new=$(git -C "$sub" rev-parse --verify --quiet "refs/heads/$branch^{commit}"); then
    ref="$branch (local)"
else
    die "branch '$branch' not found in $sub (neither origin/$branch nor a local branch)"
fi

short=$(git -C "$sub" rev-parse --short "$new")
info "Target: $ref -> $short"

# --- Point the submodule at it ---------------------------------------------

# Detached, like 'git submodule update' leaves it. This also undoes whatever
# the earlier checkout or the parent's recorded commit left in place.
git -C "$sub" checkout --quiet --detach "$new"

# --- Record the new gitlink in the parent ----------------------------------

if git diff --quiet HEAD -- "$sub"; then
    info "Parent already records $short for $sub; nothing to commit"
    exit 0
fi

name=$(basename "$sub")
msg_file=$(mktemp "${TMPDIR:-/tmp}/bump-submodule.XXXXXX")
trap 'rm -f "$msg_file"' EXIT INT TERM

{
    printf 'Bump %s to %s\n\n' "$name" "$short"
    printf 'Branch: %s\n' "$ref"
    if [ -n "$old" ] && git -C "$sub" cat-file -e "$old^{commit}" 2>/dev/null; then
        printf '\n'
        git -C "$sub" log --oneline --max-count=20 "$old..$new"
        count=$(git -C "$sub" rev-list --count "$old..$new")
        if [ "$count" -gt 20 ]; then
            printf '... and %s more\n' "$((count - 20))"
        fi
    fi
} >"$msg_file"

# Stage the gitlink, then commit only that path so any other index state
# (which jj manages in a colocated repo) is left out of the commit.
git add -- "$sub"
git commit --quiet --only -F "$msg_file" -- "$sub"

info "Committed:"
git log --oneline -1

# --- Verify ----------------------------------------------------------------

recorded=$(git rev-parse "HEAD:$sub")
[ "$recorded" = "$new" ] || die "recorded gitlink ($recorded) differs from target ($new)"

git submodule status -- "$sub"

cat <<EOF

Done. Git has the new commit; jj will import it on its next command.
Next steps:
  jj log                              # check @ sits on top of the new commit
  jj bookmark set <name> -r @-        # if you want a bookmark to follow it
EOF
