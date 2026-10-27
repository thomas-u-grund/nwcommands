#!/bin/zsh
: "${SCR:?set SCR to the scratch folder that holds the installed trees}"
# usage: kern.sh <nwergm dir> <csv> models...
W=$1; csv=$2; shift 2
cd $SCR/ergmspeed/rc
for m in $@; do
  f=wk_${m}.do
  printf 'global NWERGM "%s"\nglobal MODEL "%s"\nglobal OUT "%s"\ndo kern.do\n' "$W" "$m" "$csv" > $f
  perl -e 'alarm shift; exec @ARGV' 600 /Applications/Stata/StataBE.app/Contents/MacOS/StataBE -e do $f >/dev/null 2>&1
done
