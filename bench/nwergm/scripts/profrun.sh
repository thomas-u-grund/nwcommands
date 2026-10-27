#!/bin/zsh
# usage: profrun.sh <nwergm dir> <stata> <tag> <secs> <extra> <csv> <models...>
W=$1; v=$2; tag=$3; secs=$4; extra=$5; csv=$6; shift 6
cd /private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/ergmspeed/rc
[[ $v == 17 ]] && B="/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE" || B=/Applications/Stata/StataBE.app/Contents/MacOS/StataBE
for m in $@; do
  seed=${m#*:}; mm=${m%%:*}; [[ $seed == $m ]] && seed=1
  f=wp_${tag}_${mm}_${seed}.do
  printf 'global NWERGM "%s"\nglobal MODEL "%s"\nglobal SEED %s\nglobal EXTRA "%s"\nglobal OUT "%s"\ndo prof_model.do\n' "$W" "$mm" "$seed" "$extra" "$csv" > $f
  perl -e 'alarm shift; exec @ARGV' $secs "$B" -e do $f >/dev/null 2>&1
  grep -q "PROFDONE" ${f:r}.log || echo "$mm,$seed,TIMEOUT_OR_ERROR" >> $csv
done
