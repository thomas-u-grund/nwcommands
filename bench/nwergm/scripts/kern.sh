#!/bin/zsh
# usage: kern.sh <nwergm dir> <csv> models...
W=$1; csv=$2; shift 2
cd /private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/ergmspeed/rc
for m in $@; do
  f=wk_${m}.do
  printf 'global NWERGM "%s"\nglobal MODEL "%s"\nglobal OUT "%s"\ndo kern.do\n' "$W" "$m" "$csv" > $f
  perl -e 'alarm shift; exec @ARGV' 600 /Applications/Stata/StataBE.app/Contents/MacOS/StataBE -e do $f >/dev/null 2>&1
done
