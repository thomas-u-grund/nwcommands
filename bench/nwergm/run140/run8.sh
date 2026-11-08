#!/bin/bash
# in turn: R, nwergm 1.3.7 (base), new; seeds 1..7; one process per fit
cd "$(dirname "$0")"
SEL=${SEL:-"B1 B2 B3 B4 B5 B6 Lazega Mesa"}
for r in 1 2 3 4 5 6 7; do for id in $SEL; do
  echo "load $(sysctl -n vm.loadavg)" >> load.txt
  Rscript b8.R $id $r 2>/dev/null | grep "^@@B8" | sed 's/^/R /' >> res.txt
  for v in base new; do
    printf 'do "hdr.do"\ndo "%s" %s %s\n' ../b8.do $id $r > $v/run_${id}_$r.do
    ( cd $v; /Applications/Stata/StataBE.app/Contents/MacOS/StataBE -e do run_${id}_$r.do >/dev/null 2>&1 )
    l=$(grep "^@@B8" $v/run_${id}_$r.log); [ -z "$l" ] && l="@@B8 $id $r ERR"
    echo "$v $l" >> res.txt
  done
done; done
echo DONE >> res.txt
