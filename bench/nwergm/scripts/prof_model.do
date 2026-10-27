* globals: MODEL, NOLL (0/1), SEED, OUT (csv)
do hdr.do
do loadnet.do
do models.do
set linesize 200
setupmodel $MODEL
netname $MODEL
timer clear
timer on 8
quietly nwergm `nn', `cmd' seed($SEED) $EXTRA
timer off 8
quietly timer list
local tt ""
foreach k in 31 32 33 34 35 37 {
    local tt "`tt',`r(t`k')'"
}
local it = e(mcmle_iterations)
local conv = e(converged)
matrix b = e(b)
local bs ""
forvalues i = 1/`=colsof(b)' {
    local bs "`bs' `=b[1,`i']'"
}
file open fh using "$OUT" , write append
file write fh "$MODEL,$SEED,`r(t8)',`r(t21)',`r(nt21)',`r(t22)'`tt',`it',`conv',`bs'" _n
file close fh
di "PROFDONE $MODEL"
