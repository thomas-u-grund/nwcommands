* globals: NWERGM, MODEL, OUT, REPS (default 5)
do hdr.do
do loadnet.do
do models.do
set linesize 200
setupmodel $MODEL
netname $MODEL
local reps 5
if "$REPS" != "" local reps $REPS
forvalues r = 1/`reps' {
    timer clear 8
    timer on 8
    capture quietly nwergm `nn', `cmd' seed(`r') $EXTRA
    local rc = _rc
    timer off 8
    quietly timer list 8
    local secs = r(t8)
    local it = cond(`rc'==0, e(mcmle_iterations), .)
    local conv = cond(`rc'==0, e(converged), .)
    local ll = cond(`rc'==0, e(ll), .)
    file open fh using "$OUT", write append
    file write fh "$MODEL,`r',`secs',`it',`conv',`ll',`rc'" _n
    file close fh
}
di "BENCHDONE"
