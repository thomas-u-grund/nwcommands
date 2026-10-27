#!/bin/zsh
cd $BENCH/logs
until grep -q "ALL DONE" $BENCH/logs/chain.log; do sleep 30; done
echo "[$(date +%T)] saom fix"; python3 -u $BENCH/scripts/plan_saom_fix.py > $BENCH/logs/saom_fix.log 2>&1
echo "[$(date +%T)] FIX DONE"
