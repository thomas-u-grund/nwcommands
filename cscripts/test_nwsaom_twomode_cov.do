* more covariate effects in two-mode networks (protocol 56 plugin; netx / egosqx / altsqx / tvcov on the embedded two-mode graph), siena07 agreement
* (observed statistics equal, estimates within noise): dev/saom_rsiena_tmx.R / .do (40 actors x 20 events); here: every effect fits natively, refusals
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
mata:
mata set matastrict off
void tc_data() {
	na = 24
	ne = 10
	rseed(8642)
	X = (runiform(na, ne) :< 0.15)
	for (w=1; w<=3; w++) {
		st_matrix("__T" + strofreal(w), X)
		F = (runiform(na, ne) :< 0.12)
		X = abs(X - F)
	}
	st_matrix("__CA", rnormal(na, 1, 0, 1))
	st_matrix("__CB", rnormal(ne, 1, 0, 1))
	st_matrix("__TA", rnormal(na, 2, 0, 1))
	st_matrix("__TB", rnormal(ne, 2, 0, 1))
}
tc_data()
mata: CAm = st_matrix("__CA"); CBm = st_matrix("__CB"); TAm = st_matrix("__TA"); TBm = st_matrix("__TB")
end
clear
forvalues w = 1/3 {
	nwset, mat(__T`w') bipartite name(tm`w') nooutput
}
foreach v in ega altb ia ib ta1 ta2 tb1 tb2 {
	gen double `v' = .
}
mata: md = st_sdata(., "_nwmode"); ia = selectindex(md :== "2"); ie = selectindex(md :== "1")
mata: st_store(ia, "ega", CAm); st_store(ie, "altb", CBm); st_store(ia, "ia", (CAm :> -0.5) :+ (CAm :> 0.5)); st_store(ie, "ib", (CBm :> -0.5) :+ (CBm :> 0.5))
mata: st_store(ia, ("ta1", "ta2"), TAm); st_store(ie, ("tb1", "tb2"), TBm)
local specs "egosqx(ega) altsqx(altb) netx(altindist2:ega) netx(totindist2:ega) netx(simegoindist2:ega) netx(sameegoindist2:ia) netx(crossxoutact:ia) netx(samexcycle4:ia) netx(sameinxcycle4:ib)"
foreach sp of local specs {
	capture nwsaom, waves(tm1 tm2 tm3) outdegree `sp' k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 301)
	if _rc == 0 assert "`e(engine)'" == "native" & e(twomode) == 1 & colsof(e(b)) == 2
}
capture nwsaom, waves(tm1 tm2 tm3) outdegree netx(homxoutact2:ib) xparam(3) k0(10) k3(40) seed(3)
assert inlist(_rc, 0, 498, 301)
* changing covariates
local tspecs "egosqx(ta) nodeocov(ta) altsqx(tb) nodeicov(tb) netx(totindist2:ta) netx(simegoindist2:ta) netx(crossxoutact:ta) netx(samexcycle4:ta) netx(avgroupegox:ta) netx(totgroupegox:ta) netx(sameinxcycle4:tb)"
foreach sp of local tspecs {
	capture nwsaom, waves(tm1 tm2 tm3) outdegree `sp' tvcov(ta1 ta2 | tb1 tb2) k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 301)
	if _rc == 0 assert "`e(engine)'" == "native" & e(twomode) == 1 & colsof(e(b)) == 2
}
* refusals: effects RSiena cannot evaluate in a two-mode network (sameXOutAct / diffXOutAct crash siena07) or that make no sense there
capture nwsaom, waves(tm1 tm2 tm3) outdegree samexoutact(ega) k3(30)
assert _rc == 198
capture nwsaom, waves(tm1 tm2 tm3) outdegree netx(homxtransrectrip:ega) k3(30)
assert _rc == 198
* a co-evolving behavior of the actors in a two-mode network (events are absent actors); network effects with the behavior as covariate (siena07: dev/saom_rsiena_tmbeh.R)
gen double zb1 = 0
gen double zb2 = 0
gen double zb3 = 0
mata: st_store(ia, "zb1", 1 :+ mod(1::rows(ia), 4)); st_store(ia, "zb2", 1 :+ mod((1::rows(ia)) :+ (mod(1::rows(ia), 5) :== 0), 4)); st_store(ia, "zb3", 1 :+ mod(1::rows(ia), 4))
foreach sp in "" behegox "netbeh(egosqx)" "netbeh(altindist2)" "netbeh(totindist2)" "netbeh(simegoindist2)" "netbeh(sameegoindist2)" "netbeh(samexcycle4)" {
	capture nwsaom, waves(tm1 tm2 tm3) outdegree behavior(zb1 zb2 zb3 : linear) `sp' k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505, 301)
	if _rc == 0 assert "`e(engine)'" == "native" & e(twomode) == 1
}
capture nwsaom, waves(tm1 tm2 tm3) outdegree behavior(zb1 zb2 zb3 : linear) netbeh(crossxoutact) k3(30)
assert _rc == 198
di "PASS twomode covariate effects"
