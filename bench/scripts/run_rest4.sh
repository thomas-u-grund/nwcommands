#!/bin/zsh
# Final sequence (each plan takes the machine lock, so nothing can overlap).
cd $BENCH/logs
echo "[$(date +%T)] versions"; python3 -u $BENCH/scripts/plan_saom3.py > $BENCH/logs/saom3_run.log 2>&1
echo "[$(date +%T)] second pass big cells"; python3 -u $BENCH/scripts/plan_saom4.py > $BENCH/logs/saom4_run.log 2>&1
echo "[$(date +%T)] dynam"; python3 -u $BENCH/scripts/plan_dynam.py > $BENCH/logs/dynam_run.log 2>&1
echo "[$(date +%T)] DYNAM DONE"
