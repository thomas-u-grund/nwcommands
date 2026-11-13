#!/bin/bash
# run_core_suite.sh <17|18|19> <core_dir> <out_dir> [jobs]
# Runs every cscripts/test_*.do and xt_*.do of the core (not test_external_links, not helpers) with one Stata process per test and writes
# <out_dir>/s<version>/summary.txt (one line per test: "no error", the first r() line, NOT RUN, NO END or CRASH(signal)); logs in .../logs.
# Env LIST="test_a test_b" runs only those tests. Scratch PLUS per test; the test's work dir is private, so two versions may run side by side
# ONLY from separate core copies and with a separate TMPDIR per version (the script sets TMPDIR=<out_dir>/s<version>/tmp).
# A failure that vanishes when the test is run alone is a collision on shared files (the viewer tests kill viewer processes of every
# version): re-run it alone before calling it a failure (RELEASING.md C0).
V=$1; W=$2; OUT=$3/s$1; J=${4:-3}
case $V in 17) ST="/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE";; 18) ST="/Applications/Stata/StataBE.app/Contents/MacOS/StataBE";; 19) ST="${STATA19:-/Applications/StataNow/StataMP.app/Contents/MacOS/StataMP}";; *) echo "version 17, 18 or 19"; exit 1;; esac
mkdir -p "$OUT/logs" "$OUT/tmp"; export NWCORE=$W TMPDIR="$OUT/tmp"
one() { t=$1; b=$(basename "$t" .do); d="$OUT/work_$b"; rm -rf "$d"; mkdir -p "$d/plus"
  printf 'capture program drop nwinstall\nsysdir set PLUS "%s/plus"\nadopath ++ "%s"\nadopath ++ "%s/lib"\nadopath ++ "%s/lib/plugins/macos"\ncd "%s"\ndo "%s"\n' "$d" "$W" "$W" "$W" "$W" "$t" > "$d/run.do"
  (cd "$d" && perl -e 'alarm 1800; exec @ARGV' "$ST" -e do run.do >/dev/null 2>&1 </dev/null); xs=$?
  if [ ! -s "$d/run.log" ]; then r="NOT RUN"; else cp "$d/run.log" "$OUT/logs/$b.log"
    e=$(grep -E '^r\([0-9]+\);' "$d/run.log" | head -1); ok=$(grep -c "end of do-file" "$d/run.log"); r="${e:-no error}"
    [ -z "$e" ] && [ "$ok" = 0 ] && r="NO END"; [ "$xs" -ge 128 ] && r="CRASH($((xs-128)))"; fi
  printf '%-45s %s\n' "$b" "$r" >> "$OUT/summary.txt"; rm -rf "$d"; }
export -f one; export OUT W ST
[ -z "$LIST" ] && rm -f "$OUT/summary.txt"
if [ -n "$LIST" ]; then for x in $LIST; do echo "$W/cscripts/$x.do"; done
else ls "$W"/cscripts/test_*.do "$W"/cscripts/xt_*.do | grep -v "test_external_links\|xt_common\|xt_data_00_helpers"; fi | xargs -P "$J" -I{} bash -c 'one {}'
echo DONE >> "$OUT/summary.txt"
