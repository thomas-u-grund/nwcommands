#!/bin/bash
# smoke_fresh_install.sh [core_dir [model_parent_dir]]
# Installs nwcommands and the four model packages from LOCAL folders into an empty PLUS directory (Stata -e), then
# runs one real fit of each package in a NEW Stata process (a new session is what a user sees after a fresh install).
# Fails (exit 1) if any step returns an error or does not reach its end marker. A missing log counts as NOT RUN.
# core_dir: the nwcommands folder (default: the repository containing this script);
# model_parent_dir: a folder with the subfolders nwsaom nwergm nwdynam nwrem (default: the parent of core_dir).
# SMOKE_STALE=1 additionally makes every fit session start with a Mata library index that was built when only the core library was
# visible (what a user session can look like: Stata indexes the Mata libraries once, early in a session).
# The environment variable STATA overrides the Stata executable. nwergm needs internet access (nwwebuse reads the mesa data).
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CORE="$(cd "${1:-$HERE}" && pwd)"
MODELS="$(cd "${2:-$(dirname "$CORE")}" && pwd)"
STATA="${STATA:-/Applications/Stata/StataBE.app/Contents/MacOS/StataBE}"
T="$(mktemp -d "${TMPDIR:-/tmp}/nwsmoke.XXXXXX")"
mkdir -p "$T/plus" "$T/prof" "$T/personal"
echo "smoke test: core=$CORE models=$MODELS scratch=$T"

STALE="${SMOKE_STALE:-0}"
mkdir -p "$T/stalecore"
hdr() {  # common header of every do-file: scratch PLUS only, no repository on the adopath
  cat <<EOF
capture program drop nwinstall
sysdir set PERSONAL "$T/personal"
cd "$T"
EOF
  if [ "$STALE" = 1 ] && [ "${1:-}" != install ]; then
    echo "sysdir set PLUS \"$T/stalecore\""; echo "mata: mata mlib index"
  fi
  echo "sysdir set PLUS \"$T/plus\""
}

hdr install > "$T/s0_install.do"
cat >> "$T/s0_install.do" <<EOF
net install nwcommands, from("$CORE/") replace
capture program drop nwinstall
nwinstall, all models from("$CORE") modelsfrom("$MODELS") path("$T/prof")
display "SMOKE_OK"
EOF

hdr > "$T/s1_nwsaom.do"
cat >> "$T/s1_nwsaom.do" <<'EOF'
nwwebuse glasgow, nwclear
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip samex(smoke1) seed(1)
display "SMOKE_OK"
EOF

hdr > "$T/s2_nwergm.do"
cat >> "$T/s2_nwergm.do" <<'EOF'
nwwebuse mesa, nwclear
nwergm mesa, edges nodematch(grade)
display "SMOKE_OK"
EOF

for p in dynam rem; do
  hdr > "$T/s_nw$p.do"
  cat >> "$T/s_nw$p.do" <<EOF
import delimited "$CORE/website/nw$p/data/calls_events.csv", clear
levelsof sender, local(a) clean
levelsof receiver, local(b) clean
local all : list a | b
local miss
forvalues i = 1/84 {
    if !\`: list i in all' local miss \`miss',\`i'
}
local miss = substr("\`miss'", 2, .)
nwset sender receiver, directed eventtime(eventtime) name(calls)
nwaddnodes calls, nodenames(\`miss')
nwset
EOF
done
echo 'nwdynam calls' >> "$T/s_nwdynam.do"
echo 'nwrem calls, nodsnd nidrec' >> "$T/s_nwrem.do"
echo 'display "SMOKE_OK"' >> "$T/s_nwdynam.do"
echo 'display "SMOKE_OK"' >> "$T/s_nwrem.do"

fail=0
for f in s0_install s1_nwsaom s2_nwergm s_nwdynam s_nwrem; do
  ( cd "$T" && perl -e 'alarm 900; exec @ARGV' "$STATA" -e do "$f.do" >/dev/null 2>&1 )   # one Stata process at a time
  if [ "$f" = s0_install ] && [ "$STALE" = 1 ]; then   # the stale index knows the core library only
    mkdir -p "$T/stalecore/l"; cp "$T/plus/l/lnwcommands.mlib" "$T/stalecore/l/" 2>/dev/null
  fi
  log="$T/$f.log"
  if [ ! -s "$log" ]; then echo "NOT RUN  $f (no log)"; fail=1
  elif grep -qE '^r\([0-9]+\);' "$log"; then echo "FAIL     $f: $(grep -E -B3 '^r\([0-9]+\);' "$log" | tr '\n' ' ')"; fail=1
  elif ! grep -q '^SMOKE_OK' "$log"; then echo "FAIL     $f: end marker missing (see $log)"; fail=1
  else echo "PASS     $f"; fi
done
[ $fail = 0 ] && echo "smoke test passed" || echo "smoke test FAILED (logs in $T)"
exit $fail
