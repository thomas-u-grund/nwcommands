#!/usr/bin/env bash
# promote.sh -- release the current `develop` to the release branch `main`.
#
#   ./promote.sh            merge develop into main and push main
#   ./promote.sh --tag      the same, and tag the version in VERSION (vX.Y.Z)
#
# `main` is the branch users install from. The workflow .github/workflows/
# sync-master.yml then fast-forwards `master` (kept for older links), and the
# workflow deploy-site.yml publishes the website from `main`.
# Work and commits happen on `develop` only. Run from a clean checkout of
# `develop` (a git worktree is fine). See RELEASING.md.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
[ "$(git branch --show-current)" = develop ] || { echo "run this on the develop branch" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "the working tree is not clean" >&2; exit 1; }
python3 tools/check_version.py
git fetch origin
git merge --no-edit origin/develop
git push origin develop
# a temporary worktree for main, so the develop checkout stays as it is
tmp=$(mktemp -d)
git worktree add --detach "$tmp" origin/main
(
  cd "$tmp"
  git switch -C main origin/main
  git merge --no-ff -m "Merge develop into main" develop
  git push origin main
)
git worktree remove --force "$tmp"
if [ "${1:-}" = "--tag" ]; then
  v="v$(head -1 VERSION)"
  git tag -a "$v" -m "nwcommands $v"
  git push origin "$v"
  echo "tagged $v; create the GitHub release with: gh release create $v --notes-file <changelog excerpt>"
fi
echo "main pushed; master follows through the sync workflow; the site deploys from main."
