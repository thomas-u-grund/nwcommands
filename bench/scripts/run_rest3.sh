#!/bin/zsh
cd $BENCH/logs
until grep -q "FIX DONE" $BENCH/logs/chain2.log; do sleep 30; done
while pgrep -f plan_saom3.py > /dev/null; do sleep 20; done
echo "[$(date +%T)] second pass big cells"; python3 -u $BENCH/scripts/plan_saom4.py > $BENCH/logs/saom4_run.log 2>&1
echo "[$(date +%T)] dynam"; python3 -u $BENCH/scripts/plan_dynam.py > $BENCH/logs/dynam_run.log 2>&1
echo "[$(date +%T)] DYNAM DONE"
