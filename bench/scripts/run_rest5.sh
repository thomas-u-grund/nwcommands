#!/bin/zsh
cd $BENCH/logs
while pgrep -f scripts/plan_dynam.py > /dev/null; do sleep 30; done
echo "[$(date +%T)] ergm sanity"; python3 -u $BENCH/scripts/plan_ergm.py > $BENCH/logs/ergm_run.log 2>&1
echo "[$(date +%T)] nwsaom N1 profile"; python3 -u $BENCH/scripts/prof_sample.py nwsaom N1 400 12 > $BENCH/logs/prof_n1.log 2>&1
echo "[$(date +%T)] rem counts"; python3 -u $BENCH/scripts/run_counts.py > $BENCH/logs/counts_run.log 2>&1
echo "[$(date +%T)] ALL5 DONE"
