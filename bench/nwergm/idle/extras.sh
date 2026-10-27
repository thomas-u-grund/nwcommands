#!/bin/zsh
: "${SCR:?set SCR to the scratch folder that holds the installed trees}"
cd $SCR/idle/exrun
S18=/Applications/Stata/StataBE.app/Contents/MacOS/StataBE
export NWCORE=$SCR/r3100 NWERGM=$SCR/ergm130t NWPLUS=$SCR/idle/plus
st() { echo "$1 start $(date +%T) load $(uptime | sed 's/.*averages: //')" >> extras_progress.txt; perl -e 'alarm shift; exec @ARGV' 600 $S18 -e do $1.do >/dev/null 2>&1; echo "$1 end $(date +%T)" >> extras_progress.txt; }
rm -f r/timing_nonative.csv
st t_main
for s in 1 2 3; do cp t_nonative.do t_nn$s.do; sed -i '' "s/\$S/$s/g" t_nn$s.do; st t_nn$s; done
echo "R start $(date +%T) load $(uptime | sed 's/.*averages: //')" >> extras_progress.txt
(cd r && perl -e 'alarm shift; exec @ARGV' 900 /usr/local/bin/Rscript timing.R > timing_R.log 2>&1)
echo "R end $(date +%T)" >> extras_progress.txt
export TAG=2000; st sc2000
export TAG=10000; st sc10000
st ex9d_bdtime
echo EXTRASDONE >> extras_progress.txt
