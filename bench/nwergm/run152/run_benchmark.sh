#!/bin/bash
# Table 3 and Figure 6: times ergm and nwergm in turn on the eight benchmark models, seeds 1 to 7, one process per
# fit (R/03_benchmark_fit.R, stata/03_benchmark_fit.do). Writes results/benchmark_raw.txt and results/load.txt.
# Run from the folder replication/. Set STATA to your Stata executable, for example
#   STATA="/Applications/Stata/StataBE.app/Contents/MacOS/StataBE" tools/run_benchmark.sh
# Run time: about 45 minutes. Timings depend on the machine; the ratios are more stable than the seconds.
set -u
STATA=${STATA:?set STATA to the Stata executable}
SEEDS=${SEEDS:-"1 2 3 4 5 6 7"}
MODELS=${MODELS:-"B1 B2 B3 B4 B5 B6 Lazega Mesa"}
OUT=results/benchmark_raw.txt
mkdir -p results; : > $OUT; : > results/load.txt
tmp=$(mktemp -d)
for r in $SEEDS; do for id in $MODELS; do
  echo "$(sysctl -n vm.loadavg 2>/dev/null || cat /proc/loadavg)" >> results/load.txt
  Rscript R/03_benchmark_fit.R $id $r 2>/dev/null | grep "^@@B8" | sed 's/^/R /' >> $OUT
  printf 'cd "%s"\ndo stata/03_benchmark_fit.do %s %s\n' "$PWD" $id $r > $tmp/b_${id}_$r.do
  ( cd $tmp && "$STATA" -e do b_${id}_$r.do >/dev/null 2>&1 )
  l=$(grep "^@@B8" $tmp/b_${id}_$r.log); [ -z "$l" ] && l="@@B8 $id $r ERR"
  echo "nwergm $l" >> $OUT
done; done
rm -rf $tmp
echo "written $OUT"
