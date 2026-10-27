#!/bin/zsh
: "${SCR:?set SCR to the scratch folder that holds the installed trees}"
# R, nwergm 1.2.3 and nwergm speed130 run at the same time on the same 8 models (equal outside load); kill switches per model
cd $SCR/ergmspeed/rc
P=$PWD/..
OLD=$SCR/r370m/nwergm
M=(B1 B2 B3 B4 B5 B6 Lazega Mesa)
rm -f cb_R.csv cb_old.csv cb_new.csv cb_*.status concb.done
( echo "R start $(date +%T) load $(uptime | sed 's/.*averages: //')" >> cb_R.status; for m in $M; do perl -e 'alarm shift; exec @ARGV' 1500 Rscript bench_r.R cb_R.csv $m > /dev/null 2>&1 || echo "$m,0,TIMEOUT,,,," >> cb_R.csv; done; echo "R done $(date +%T) load $(uptime | sed 's/.*averages: //')" >> cb_R.status ) &
( ./benchrun.sh $OLD 18 cbold cb_old.csv 2400 "" $M ) &
( ./benchrun.sh $P/nwergm 18 cbnew cb_new.csv 900 "" $M ) &
wait
echo done > concb.done
