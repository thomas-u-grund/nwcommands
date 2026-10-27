#!/bin/zsh
cd /private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/idle/../idle/exrun
S18=/Applications/Stata/StataBE.app/Contents/MacOS/StataBE
export NWCORE=/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/idle/../r3100 NWERGM=/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/idle/../ergm130t NWPLUS=/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/idle/../idle/plus
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
