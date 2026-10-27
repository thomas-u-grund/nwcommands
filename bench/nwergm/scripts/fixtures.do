* fixtures: results under fixed seeds. globals: NWERGM, FIXOUT
do hdr.do
do loadnet.do
do models.do
set linesize 200
capture erase "$FIXOUT"
file open fx using "$FIXOUT", write replace
foreach m in $MODELS {
    setupmodel `m'
    netname `m'
    capture quietly nwergm `nn', `cmd' method(mple)
    if _rc {
        file write fx "`m' MPLE_ERROR " (_rc) _n
        continue
    }
    matrix b0 = e(b)
    mata: th = st_matrix("b0") * 0.9
    set seed 11
    mata: s = ErgmMCMCSample(__nwergm_last_M, __nwergm_last_G, th, 500, 50, 200, &ergm_propose_tnt())
    mata: st_matrix("ssum", colsum(s))
    mata: st_numscalar("nt", __nwergm_last_G.nties)
    file write fx "`m' sample_colsum"
    forvalues i = 1/`=colsof(ssum)' {
        file write fx " " %21.12g (ssum[1,`i'])
    }
    file write fx " nties " (nt) _n
    set seed 12
    mata: s = ErgmMCMCSample(__nwergm_last_M, __nwergm_last_G, th, 200, 50, 200, &ergm_propose_uniform())
    mata: st_matrix("ssum", colsum(s))
    file write fx "`m' sample_uniform_colsum"
    forvalues i = 1/`=colsof(ssum)' {
        file write fx " " %21.12g (ssum[1,`i'])
    }
    file write fx _n
    * full legacy-algorithm fit
    capture quietly nwergm `nn', `cmd' seed(5) $FITOPT
    if _rc {
        file write fx "`m' FIT_ERROR " (_rc) _n
        continue
    }
    matrix b = e(b)
    matrix V = e(V)
    file write fx "`m' fit iter " (e(mcmle_iterations)) " conv " (e(converged)) " ll " %21.14g (e(ll)) " llse " %21.14g (e(ll_se)) _n
    file write fx "`m' b"
    forvalues i = 1/`=colsof(b)' {
        file write fx " " %21.14g (b[1,`i'])
    }
    file write fx _n "`m' Vdiag"
    forvalues i = 1/`=colsof(b)' {
        file write fx " " %21.14g (V[`i',`i'])
    }
    file write fx _n
}
file close fx
di "FIXDONE"
