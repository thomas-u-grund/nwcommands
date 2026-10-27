* nwergm side of the equivalence study (globals NWERGM, OUT)
do hdr.do
do loadnet.do
do models.do
set linesize 200
capture erase "$OUT"
file open fh using "$OUT", write replace
file write fh "model,seed,term,b,se,ll,iter,ss,secs" _n
capture program drop dofit
program dofit
    args name seed
    setupmodel `name'
    netname `name'
    timer clear 3
    timer on 3
    quietly nwergm `nn', `cmd' seed(`seed')
    timer off 3
    quietly timer list 3
    matrix b = e(b)
    matrix V = e(V)
    local nm : colnames b
    forvalues i = 1/`=colsof(b)' {
        local t : word `i' of `nm'
        file write fh "`name',`seed',`t'," (b[1,`i']) "," (sqrt(V[`i',`i'])) "," (e(ll)) "," (e(mcmle_iterations)) "," (e(mcmc_samplesize)) "," (r(t3)) _n
    }
end
* Florentine
nwwebuse florentine, nwclear
forvalues s = 1/20 {
    quietly nwergm flomarriage, edges nodematch(seat) gwesp(.5) seed(`s')
    matrix b = e(b)
    matrix V = e(V)
    local nm : colnames b
    forvalues i = 1/`=colsof(b)' {
        local t : word `i' of `nm'
        file write fh "flo,`s',`t'," (b[1,`i']) "," (sqrt(V[`i',`i'])) "," (e(ll)) "," (e(mcmle_iterations)) "," (e(mcmc_samplesize)) ",0" _n
    }
}
foreach m in Lazega Mesa B3 B4 {
    forvalues s = 1/20 {
        dofit `m' `s'
    }
}
file close fh
di "STATDONE"
