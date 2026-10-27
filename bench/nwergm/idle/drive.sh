#!/bin/zsh
# strictly sequential, interleaved R / 1.2.3 / 1.3.0
cd /private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/idle/../idle
OUT=${OUT:-idle_all.csv}
S18=/Applications/Stata/StataBE.app/Contents/MacOS/StataBE
MODELS=(${=MODELS:-B1 B2 B3 B4 B5 B6 Lazega Mesa})
[[ -f $OUT ]] || echo "impl,model,rep,load1,secs,converged,iter,samplesize,directed,N,rc,estimates" > $OUT
ld() { uptime | sed 's/.*averages: //' | awk '{print $1}' | tr -d ,; }
for m in $MODELS; do
  nrep=7; r=1
  while (( r <= nrep )); do
    for impl in R v123 v130; do
      L=$(ld); n0=$(wc -l < $OUT)
      if [[ $impl == R ]]; then
        perl -e 'alarm shift; exec @ARGV' 600 /usr/local/bin/Rscript one_r.R $m $r $L $OUT > /dev/null 2>>err_R.log
      else
        [[ $impl == v123 ]] && W=/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/idle/../ergm123 || W=/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/idle/../ergm130t
        printf 'global NWERGM "%s"\nglobal MODEL "%s"\nglobal REP %s\nglobal LOAD %s\nglobal OUT "%s"\nglobal IMPL "%s"\ndo one.do\n' $W $m $r $L $OUT $impl > run_$impl.do
        perl -e 'alarm shift; exec @ARGV' 600 $S18 -e do run_$impl.do > /dev/null 2>&1
        mv run_$impl.log log_${impl}_${m}_$r.log 2>/dev/null
      fi
      n1=$(wc -l < $OUT)
      (( n1 == n0 )) && echo "$impl,$m,$r,$L,TIMEOUT_OR_ERROR,,,,,,1," >> $OUT
    done
    # five fits only if one took over 60 s
    if (( r == 1 )) && awk -F, -v m=$m '$2==m && $5+0>60 {f=1} END{exit !f}' $OUT; then nrep=5; fi
    echo "$m round $r done $(date +%T) load $(uptime | sed 's/.*averages: //')" >> progress.txt
    (( r++ ))
  done
done
echo ALLDONE >> progress.txt
