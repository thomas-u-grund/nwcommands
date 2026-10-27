#!/bin/zsh
: "${SCR:?set SCR to the scratch folder that holds the installed trees}"
# usage: fixrun.sh <nwergm dir> <stata> <outfile> <fitopts> <secs>
W=$1; v=$2; out=$3; opt=$4; secs=${5:-1500}
cd $SCR/ergmspeed/rc
[[ $v == 17 ]] && B="/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE" || B=/Applications/Stata/StataBE.app/Contents/MacOS/StataBE
f=wf_${out:t:r}.do
printf 'global NWERGM "%s"\nglobal FIXOUT "%s"\nglobal FITOPT "%s"\nglobal MODELS "%s"\ndo fixtures.do\n' "$W" "$out" "$opt" "${MODELS:-B1 B2 B3 B4 F6 F7 F8 F9 F10 F11 Lazega Mesa B6}" > $f
perl -e 'alarm shift; exec @ARGV' $secs "$B" -e do $f >/dev/null 2>&1
grep -q FIXDONE ${f:r}.log && echo OK || echo FAILED
