* kernel speed: nwergm sampler at the MPLE, 1000 draws, interval 1024, burn-in 16384; writes theta and time
do hdr.do
do loadnet.do
do models.do
setupmodel $MODEL
netname $MODEL
quietly nwergm `nn', `cmd' method(mple)
matrix b0 = e(b)
mata: th = st_matrix("b0")
mata: s = ErgmMCMCSample(__nwergm_last_M, __nwergm_last_G, th, 2000, 100, 5, &ergm_propose_tnt())
timer clear 2
timer on 2
mata: s = ErgmMCMCSample(__nwergm_last_M, __nwergm_last_G, th, 16384, 1024, 1000, &ergm_propose_tnt())
timer off 2
quietly timer list 2
mata: st_numscalar("nt", __nwergm_last_G.nties)
mata: st_matrix("mm", mean(s))
file open fh using "$OUT", write append
file write fh "$MODEL," (r(t2)) "," (nt)
forvalues i = 1/`=colsof(mm)' {
    file write fh "," (mm[1,`i'])
}
file write fh _n
file close fh
mata: fh = fopen("th_$MODEL.csv", "w"); fput(fh, invtokens(strofreal(th, "%20.15g"), ",")); fclose(fh)
