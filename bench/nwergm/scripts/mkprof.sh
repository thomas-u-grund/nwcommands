#!/bin/zsh
# usage: mkprof.sh <src nwergm dir> <dest prof dir>
S=$1; D=$2
cd /private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/ergmspeed
rm -rf $D; mkdir -p $D
(cd $S; tar cf - --exclude=.git .) | (cd $D; tar xf -)
python3 prof_patch.py $D
cd $D
export NWCORE=/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/r391
perl -e 'alarm 600; exec @ARGV' "/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE" -e do lib/build.do >/dev/null 2>&1
rm -f build.log
