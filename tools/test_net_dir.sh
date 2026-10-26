#!/bin/bash
# test_net_dir.sh [repo_dir]
# Builds the net/ directory with make_net_dir.sh into a scratch folder, checks that every file of nwcommands.pkg is there and
# byte-identical to the repository file, serves it on localhost and runs `net install nwcommands, from(http://localhost:PORT/) replace`
# in an empty PLUS with Stata 17 and 18 (STATA17 / STATA18 override the paths; STATAS="17" runs only one), then runs `nwinstall`.
# Exit 1 on any failure; an empty log counts as NOT RUN (failure).
set -u
REPO="$(cd "${1:-$(dirname "$0")/..}" && pwd)"
S17="${STATA17:-/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE}"
S18="${STATA18:-/Applications/Stata/StataBE.app/Contents/MacOS/StataBE}"
T="$(mktemp -d "${TMPDIR:-/tmp}/netdir.XXXXXX")"
fail=0
bash "$REPO/tools/make_net_dir.sh" "$T/net" "$REPO" || exit 1
for f in stata.toc nwcommands.pkg $(awk '$1=="f"||$1=="F"{print $2}' "$REPO/nwcommands.pkg"); do
  [ "$f" = stata.toc ] && { grep -q '^p nwcommands$' "$T/net/stata.toc" && ! grep -q 'nwcommands-ado' "$T/net/stata.toc" && echo "PASS reduced: stata.toc" || { echo "FAIL stata.toc"; fail=1; }; continue; }
  cmp -s "$REPO/$f" "$T/net/$f" && echo "PASS identical: $f" || { echo "FAIL differs/missing: $f"; fail=1; }
done
PORT=$((20000 + RANDOM % 20000))
(cd "$T/net" && exec python3 -m http.server $PORT --bind 127.0.0.1 >"$T/http.log" 2>&1) &
HP=$!
sleep 2
for v in ${STATAS:-17 18}; do
  [ "$v" = 17 ] && ST="$S17" || ST="$S18"
  d="$T/s$v"; mkdir -p "$d/plus" "$d/personal" "$d/prof"
  cat > "$d/run.do" <<EOT
capture program drop nwinstall
sysdir set PERSONAL "$d/personal"
sysdir set PLUS "$d/plus"
net install nwcommands, from(http://localhost:$PORT/) replace
capture program drop nwinstall
which nwinstall
nwinstall, path("$d/prof")
nwversion
display "NETDIR_OK"
EOT
  (cd "$d" && env PWD="$d" perl -e 'alarm 240; exec @ARGV' "$ST" -e do run.do >/dev/null 2>&1)
  log="$d/run.log"
  if [ ! -s "$log" ]; then echo "NOT RUN Stata $v"; fail=1
  elif grep -q "NETDIR_OK" "$log" && ! grep -q "^r([0-9]*);" "$log"; then echo "PASS Stata $v: net install from localhost, nwinstall, nwversion"
  else echo "FAIL Stata $v (see $log)"; fail=1; fi
done
kill $HP 2>/dev/null
echo "scratch: $T"
exit $fail
