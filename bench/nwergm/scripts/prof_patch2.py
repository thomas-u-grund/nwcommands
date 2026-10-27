import sys
d=sys.argv[1]
p=d+'/unw_ergm.do'
s=open(p).read()
i=s.index('real matrix ErgmNativeSampleCore(')
j=s.index('return(out)',i)
seg=s[i:j+11]
seg=seg.replace('	n = G.n\n','	stata("timer on 21")\n	n = G.n\n',1)
seg=seg.replace('	rc_pl = _stata(cmd)\n','	stata("timer on 22")\n	rc_pl = _stata(cmd)\n	stata("timer off 22")\n',1)
seg=seg.replace('	nties_out = st_numscalar("__ergm_native_nties_out")\n','	nties_out = st_numscalar("__ergm_native_nties_out")\n	st_numscalar("__prof_steps", (rows(st_numscalar("__prof_steps")) * cols(st_numscalar("__prof_steps")) == 1 ? st_numscalar("__prof_steps") : 0) + burnin + st_numscalar("__ergm_native_ntried"))\n',1)
seg=seg.replace('	return(out)','	stata("timer off 21")\n	return(out)')
s=s[:i]+seg+s[j+11:]
open(p,'w').write(s)
p=d+'/nwergm.ado'
s=open(p).read()
def rep(a,b):
    global s
    assert s.count(a)>=1,(a)
    s=s.replace(a,b,1)
rep('\t\tmata: __nwergm_last_G = ErgmGraph()\n','\t\ttimer on 31\n\t\tmata: __nwergm_last_G = ErgmGraph()\n')
rep('\tmata: __nwergm_last_M = ErgmModel()\n','\ttimer off 31\n\ttimer on 32\n\tmata: __nwergm_last_M = ErgmModel()\n')
rep('\tif "`nonative\'" == "" {\n\t\tmata: __ergm_mple_native_setup_rc','\ttimer off 32\n\ttimer on 33\n\tif "`nonative\'" == "" {\n\t\tmata: __ergm_mple_native_setup_rc')
rep('\t\tmata: __nwergm_ties0 = __nwergm_last_G.all_ties()\n','\t\ttimer off 33\n\t\ttimer on 34\n\t\tmata: __nwergm_ties0 = __nwergm_last_G.all_ties()\n')
s=s.replace("mata: `__fit' = ErgmMCMLE(","timer off 34\n\t\ttimer on 35\n\t\t\tmata: `__fit' = ErgmMCMLE(")
rep('\t\tnwergm_display "`netname\'" "`nodes\'" "`directed\'" "`=cond("`method\'"=="cd","CD",cond("`mainmethod\'"=="sa","SA","MCMLE"))\'"','\t\ttimer off 35\n\t\tnwergm_display "`netname\'" "`nodes\'" "`directed\'" "`=cond("`method\'"=="cd","CD",cond("`mainmethod\'"=="sa","SA","MCMLE"))\'"')
rep("\t\t_nwergm_fitstats, dmat(`__nw_D') method(mcmle)","\t\ttimer on 37\n\t\t_nwergm_fitstats, dmat(`__nw_D') method(mcmle)")
rep("dcomp(`__dcname') `nologlik'\n","dcomp(`__dcname') `nologlik'\n\t\ttimer off 37\n")
open(p,'w').write(s)
