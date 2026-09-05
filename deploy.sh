#!/usr/bin/env bash
# deploy.sh -- the nwcommands publish pipeline, end to end. Run this
# instead of hand-rolling "rebuild the mlib, regenerate the .pkg files,
# commit, push" every time, since every one of those steps has silently
# gone stale in the past (see the commit history around 2026-09-02:
# unw_dynam.do was never in lib/build.do; nw_syntax.ado and 9 other real,
# documented commands were never in any package manifest at all).
#
# What it does, in order:
#   1. Rebuild lib/lnwcommands.mlib from every unw_*.do source file.
#   2. Regenerate the package manifests (nwcommands-ado*.pkg/-hlp*.pkg/
#      -dlg*.pkg, stata.toc, nwcommands.sthlp) from _pkg_ado.txt/
#      _pkg_hlp.txt (both Stata steps live in deploy_nw_build.do).
#   3. A consistency check (this file, below): does every unw_*.do appear
#      in lib/build.do; does every DOCUMENTED command (.ado with a
#      matching .sthlp) and every native plugin file appear in some
#      nwcommands*.pkg. Aborts before touching git if anything fails,
#      other than the known, already-triaged exceptions below.
#   4. Stage: `git add -u` (modifications to already-tracked files) plus
#      the known build-artifact paths this script itself just
#      regenerated. Untracked files are NOT auto-staged (see --help) -
#      this project has a real, currently-uncommitted `website/`
#      directory sitting in the working tree that must never get swept
#      into an unrelated commit by accident.
#   5. Commit (message required) and push to develop.
#   6. If the push is rejected non-fast-forward (the CI plugin-rebuild
#      bot commits back to develop on its own after any native/ push -
#      hit twice in the same session this script was written for),
#      fetch + rebase once and retry. A second rejection, or any actual
#      conflict, stops and hands control back rather than guessing.
#
# Usage:
#   ./deploy.sh "commit message"
#   ./deploy.sh --include-untracked "commit message"   (git add -A instead)
#   ./deploy.sh --check-only                            (steps 1-3 only)

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

STATA="/Applications/Stata/StataBE.app/Contents/MacOS/StataBE"
INCLUDE_UNTRACKED=0
CHECK_ONLY=0
MSG=""

for arg in "$@"; do
  case "$arg" in
    --include-untracked) INCLUDE_UNTRACKED=1 ;;
    --check-only) CHECK_ONLY=1 ;;
    -h|--help)
      sed -n '2,32p' "$0"
      exit 0
      ;;
    *) MSG="$arg" ;;
  esac
done

if [ "$CHECK_ONLY" = 0 ] && [ -z "$MSG" ]; then
  echo "error: a commit message is required (or pass --check-only)." >&2
  echo "usage: ./deploy.sh [--include-untracked] \"commit message\"" >&2
  exit 1
fi

echo "== 1-2. Rebuilding lib/lnwcommands.mlib and package manifests =="
rm -f deploy_nw_build.log
"$STATA" -e do deploy_nw_build.do
if ! grep -q "DEPLOY_NW_BUILD_DONE" deploy_nw_build.log; then
  echo "error: Stata build step did not complete - see deploy_nw_build.log" >&2
  grep -n "^r([0-9]*)" deploy_nw_build.log >&2 || true
  exit 1
fi
if grep -qn "^r([0-9]*)" deploy_nw_build.log; then
  echo "error: Stata build step reported an error - see deploy_nw_build.log" >&2
  grep -n "^r([0-9]*)" deploy_nw_build.log >&2
  exit 1
fi
echo "   ok."

echo "== 3. Consistency check =="
# Known, already-triaged exceptions - kept as an empty array (rather than
# removed) so the mechanism stays ready for the next genuinely-deferred
# case. nw_datasync/nw_tomata/nw_unab used to live here (found
# 2026-09-02, genuinely resolved 2026-09-05: they were real, live,
# documented commands just missing from the manifest by oversight, not
# legacy duplicates - added to _pkg_ado.txt/_pkg_hlp.txt for real
# instead).
KNOWN_EXCEPTIONS=(
)
is_known_exception() {
  local f="$1"
  # ${arr[@]+...} guards against "unbound variable" under `set -u` when
  # KNOWN_EXCEPTIONS is genuinely empty (no items currently deferred).
  for e in "${KNOWN_EXCEPTIONS[@]+"${KNOWN_EXCEPTIONS[@]}"}"; do
    [ "$e" = "$f" ] && return 0
  done
  return 1
}

check_failed=0

for f in unw_*.do; do
  if ! grep -q "$f" lib/build.do; then
    echo "  MISSING FROM lib/build.do: $f"
    check_failed=1
  fi
done

for f in *.ado; do
  base="${f%.ado}"
  [ -f "${base}.sthlp" ] || continue
  is_known_exception "$f" && continue
  if ! grep -qh "^f ${f}\$" nwcommands*.pkg 2>/dev/null; then
    echo "  DOCUMENTED COMMAND MISSING FROM PACKAGE: $f"
    check_failed=1
  fi
done

for f in *.sthlp; do
  base="${f%.sthlp}"
  [ -f "${base}.ado" ] || continue
  is_known_exception "$f" && continue
  if ! grep -qh "^f ${f}\$" nwcommands*.pkg 2>/dev/null; then
    echo "  HELP FILE MISSING FROM PACKAGE: $f"
    check_failed=1
  fi
done

if [ -d lib/plugins ]; then
  while IFS= read -r f; do
    if ! grep -qh "^f ${f}\$" nwcommands*.pkg 2>/dev/null; then
      echo "  NATIVE PLUGIN FILE MISSING FROM PACKAGE: $f"
      check_failed=1
    fi
  done < <(find lib/plugins -type f)
fi

if [ "$check_failed" = 1 ]; then
  echo "error: consistency check failed - fix the items above (usually: add" >&2
  echo "  the missing 'f <file>' line(s) to _pkg_ado.txt/_pkg_hlp.txt, or add" >&2
  echo "  a known, deliberate exception to KNOWN_EXCEPTIONS in this script)" >&2
  echo "  and re-run. Nothing was committed or pushed." >&2
  exit 1
fi
echo "   ok."

if [ "$CHECK_ONLY" = 1 ]; then
  echo "== --check-only: stopping before git =="
  exit 0
fi

echo "== 4. Staging =="
git add -u
git add lib/lnwcommands.mlib nwcommands*.pkg stata.toc nwcommands.sthlp \
  _pkg_ado.txt _pkg_hlp.txt lib/plugins/ 2>/dev/null || true

untracked="$(git status --porcelain | grep '^??' | grep -v '^?? website/' || true)"
if [ "$INCLUDE_UNTRACKED" = 1 ]; then
  git add -A -- ':!website'
elif [ -n "$untracked" ]; then
  echo "  NOTE: untracked files exist and were NOT staged (pass --include-untracked to include them):"
  echo "$untracked" | sed 's/^/    /'
fi

if git diff --cached --quiet; then
  echo "  nothing to commit."
  exit 0
fi

echo "== Review =="
git status --short
echo
git diff --cached --stat

echo "== 5. Commit =="
git commit -m "$MSG

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"

echo "== 6. Push to develop =="
if ! git push origin HEAD:develop; then
  echo "  push rejected (likely CI's own plugin-rebuild bot) - fetching and rebasing once..."
  git fetch origin
  if git rebase origin/develop; then
    if ! git push origin HEAD:develop; then
      echo "error: push rejected again after one rebase - stopping for manual review." >&2
      exit 1
    fi
  else
    echo "error: rebase hit a real conflict - resolve manually (git status), then" >&2
    echo "  'git rebase --continue' and push yourself. Not attempting to auto-resolve." >&2
    exit 1
  fi
fi

git branch -f develop origin/develop 2>/dev/null || true

if git diff --name-only HEAD~1 HEAD | grep -qE '^native/|^\.github/workflows/build-plugins\.yml$'; then
  echo
  echo "  native/ or the plugin workflow changed - CI will build and commit binaries"
  echo "  back to develop shortly (watch with: gh run list --workflow=build-plugins.yml)."
fi

echo
echo "Done."
