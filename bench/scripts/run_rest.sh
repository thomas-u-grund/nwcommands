#!/bin/zsh
# Sequential chain after the nwsaom comparison: data generation, nwrem, nwdynam, nwsaom extras, profiles, nwergm sanity.
# Strictly one R or Stata process at a time.  env SCR, BENCH required.
set -u
cd $BENCH/logs
while pgrep -f plan_saom.py > /dev/null; do sleep 20; done
echo "[$(date +%T)] gen data"; BENCH=$BENCH Rscript $BENCH/scripts/gen_rem.R && BENCH=$BENCH Rscript $BENCH/scripts/gen_dynam.R > $BENCH/logs/gen_dynam.out 2>&1
echo "[$(date +%T)] rem"; python3 -u $BENCH/scripts/plan_rem.py > $BENCH/logs/rem_run.log 2>&1
echo "[$(date +%T)] dynam"; python3 -u $BENCH/scripts/plan_dynam.py > $BENCH/logs/dynam_run.log 2>&1
echo "[$(date +%T)] saom more"; python3 -u $BENCH/scripts/plan_saom2.py all > $BENCH/logs/saom2_run.log 2>&1
echo "[$(date +%T)] profiles"; python3 -u $BENCH/scripts/run_profiles.py > $BENCH/logs/prof_run.log 2>&1
echo "[$(date +%T)] ergm sanity"; python3 -u $BENCH/scripts/plan_ergm.py > $BENCH/logs/ergm_run.log 2>&1
echo "[$(date +%T)] ALL DONE"
