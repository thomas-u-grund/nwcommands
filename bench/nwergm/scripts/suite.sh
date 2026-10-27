#!/bin/zsh
# usage: suite.sh <nwergm dir> <17|18> <outdir> <jobs> [tests...]   (library mode if LIBMODE=1: no cd-sourced mlib removal)
W=$1; v=$2; OUT=$3; jobs=${4:-2}; shift 4
S=/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad
CORE=$S/r391
[[ $v == 17 ]] && STATA="/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE" || STATA=/Applications/Stata/StataBE.app/Contents/MacOS/StataBE
mkdir -p $OUT/plus $OUT/logs
export NWCORE=$CORE
tests=($@)
[[ ${#tests} -eq 0 ]] && tests=($(cd $W/cscripts; ls test_*.do | sed 's/\.do$//'))
run_one() {
  local b=$1 d=$OUT/work_$1
  rm -rf $d; mkdir -p $d
  printf 'capture program drop nwinstall\nsysdir set PLUS "%s/plus"\nadopath ++ "%s"\nadopath ++ "%s/lib"\nadopath ++ "%s/lib/plugins/macos"\nadopath ++ "%s/lib/plugins/macos"\nadopath ++ "%s/lib"\nadopath ++ "%s"\ncd "%s"\ndo "%s/cscripts/%s.do"\n' $OUT $CORE $CORE $CORE $W $W $W $W $W $b > $d/run.do
  (cd $d && PWD=$d perl -e 'alarm 1500; exec @ARGV' "$STATA" -e do run.do >/dev/null 2>&1 </dev/null)
  if [[ -s $d/run.log ]]; then cp $d/run.log $OUT/logs/$b.log; r=$(grep -E '^r\([0-9]+\);' $OUT/logs/$b.log | head -1); n=$(grep -c -E 'PASS|ALL OK|ALL TESTS PASSED' $OUT/logs/$b.log); echo "$b | pass-lines=$n | ${r:-no-error}" > $OUT/logs/$b.sum
  else echo "$b | NOT RUN" > $OUT/logs/$b.sum; fi
}
running=0
for t in $tests; do
  run_one $t &
  running=$((running + 1))
  if (( running >= jobs )); then wait -n 2>/dev/null || wait; running=$((running - 1)); fi
done
wait
cat $OUT/logs/*.sum > $OUT/summary.txt
echo "suite done $(date +%T)" >> $OUT/summary.txt
