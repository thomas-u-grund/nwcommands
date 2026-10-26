#!/bin/bash
# make_net_dir.sh <out_dir> [repo_dir]
# Copies the starter package (stata.toc reduced to the starter entry, nwcommands.pkg and every file the .pkg lists with an 'f'/'F' line) into <out_dir>,
# so that `net install nwcommands, from(https://nwcommands.org/net/) replace` works. Used by the deploy workflow
# (.github/workflows/deploy-site.yml) AFTER the Jekyll build (Jekyll would drop underscore-prefixed files) and locally by
# tools/test_net_dir.sh. Fails (exit 1) when a listed file is missing.
set -eu
OUT="${1:?usage: make_net_dir.sh <out_dir> [repo_dir]}"
REPO="$(cd "${2:-$(dirname "$0")/..}" && pwd)"
mkdir -p "$OUT"
n=0
for f in stata.toc nwcommands.pkg $(awk '$1=="f" || $1=="F" {print $2}' "$REPO/nwcommands.pkg"); do
  [ -f "$REPO/$f" ] || { echo "make_net_dir: missing $f" >&2; exit 1; }
  if [ "$f" = stata.toc ]; then
    # only the starter is served here: the other packages of stata.toc (nwcommands-ado1 ...) are not in net/
    awk '$1=="p"{skip=($2!="nwcommands")} !skip' "$REPO/stata.toc" > "$OUT/stata.toc"
  else
    cp -p "$REPO/$f" "$OUT/$f"
  fi
  n=$((n+1))
done
echo "make_net_dir: $n files copied to $OUT"
