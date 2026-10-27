#!/bin/zsh
: "${SCR:?set SCR to the scratch folder that holds the installed trees}"
# usage: mkprof.sh <src nwergm dir> <dest prof dir>
S=$1; D=$2
cd $SCR/ergmspeed
rm -rf $D; mkdir -p $D
(cd $S; tar cf - --exclude=.git .) | (cd $D; tar xf -)
python3 prof_patch.py $D
cd $D
export NWCORE=$SCR/r391
perl -e 'alarm 600; exec @ARGV' "/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE" -e do lib/build.do >/dev/null 2>&1
rm -f build.log
