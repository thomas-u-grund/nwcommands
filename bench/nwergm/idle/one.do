* globals: NWERGM MODEL REP LOAD OUT IMPL
do hdr.do
do loadnet.do
do models.do
setupmodel $MODEL
netname $MODEL
quietly nwergm `nn', `cmd' seed(100)
timer clear 8
timer on 8
quietly nwergm `nn', `cmd' seed($REP)
timer off 8
quietly timer list 8
local secs = r(t8)
local dir = e(directed)
local nn_ = e(N)
local conv = e(converged)
local it = e(mcmle_iterations)
local ss = .
capture local ss = e(mcmc_samplesize)
matrix b = e(b)
local bs ""
forvalues j = 1/`=colsof(b)' {
    local bs "`bs'`=string(b[1,`j'],"%12.6f")';"
}
local bs = trim(substr("`bs'",1,length("`bs'")-1))
file open fh using "$OUT", write append
file write fh "$IMPL,$MODEL,$REP,$LOAD,`secs',`conv',`it',`ss',`dir',`nn_',0,`bs'" _n
file close fh
di "ONEDONE"
