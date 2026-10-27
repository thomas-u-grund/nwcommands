#!/bin/zsh
# usage: benchrun.sh <nwergm dir> <stata> <tag> <csv> <secs per model> <extra opts> models...
W=$1; v=$2; tag=$3; csv=$4; secs=$5; extra=$6; shift 6
cd /private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/ergmspeed/rc
[[ $v == 17 ]] && B="/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE" || B=/Applications/Stata/StataBE.app/Contents/MacOS/StataBE
for m in $@; do
  f=wb_${tag}_${m}.do
  printf 'global NWERGM "%s"\nglobal MODEL "%s"\nglobal OUT "%s"\nglobal EXTRA "%s"\ndo bench_model.do\n' "$W" "$m" "$csv" "$extra" > $f
  echo "$m start $(date +%T) load $(uptime | sed 's/.*averages: //')" >> ${csv:r}.status
  perl -e 'alarm shift; exec @ARGV' $secs "$B" -e do $f >/dev/null 2>&1
  grep -q BENCHDONE ${f:r}.log || echo "$m,0,TIMEOUT,,,," >> $csv
done
echo "done $(date +%T) load $(uptime | sed 's/.*averages: //')" >> ${csv:r}.status
