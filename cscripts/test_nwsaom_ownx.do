* own-network effects without a covariate (ownx(): outinass inpopdya inisdegree instructeq densetriads, two-mode structural effects (protocol 56), jin jout transtrip1 transtrip2 transrectrip2 transtripfe transtripee outpopmore outpopsqrtmore outpopthreshold and the ego
* degree effects), plugin protocol 54; siena07 agreement (s50, symmetric waves for jout): dev/saom_rsiena_dg.{R,do}, dev/saom_rsiena_symdg.R
cscript
do unw_core.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void dg_data() {
	n = 40
	rseed(9191)
	A = (runiform(n, n) :< 0.10)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		st_matrix("__S" + strofreal(w), ((A + A') :> 0))
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
dg_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(dd`w') nooutput
	nwset, mat(__S`w') directed name(ds`w') nooutput
}
foreach ef in primary primcompress nonpcompress primdegact primdegactlog primdegactsqrt primdegactinv primdegactdiff primdegactdiffsqrt primdegact:2 outinass:1 outinass:2 outoutass outoutass:1 ininass ininass:1 inoutass inoutass:1 inpopdya inpopdya:2 inisdegree instructeq densetriads:5 densetriads:6 jin jout transtrip1 transtrip2 transrectrip2 transtripfr transtripfe transtripee outpopmore:2 outpopsqrtmore:2 outpopthreshold:2 outactego outactmoreego:2 outactsqrtmoreego:2 outmoreego:2 divoutego inactego divinego reciactego {
	capture nwsaom, waves(dd1 dd2 dd3) outdegree reciprocity ownx(`ef') k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 3
}
capture nwsaom, waves(ds1 ds2 ds3) symmetric outdegree ownx(jout) k0(10) k3(40) seed(3)
assert inlist(_rc, 0, 498, 505)
foreach ef in divoutego:1 inpopdya outinass:2 {
	capture nwsaom, waves(ds1 ds2 ds3) symmetric outdegree ownx(`ef') k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
}
* two-mode (protocol 56): the structural effects of a bipartite network
mata:
mata set matastrict off
void dg_tm() {
	na = 24
	ne = 10
	rseed(5151)
	X = (runiform(na, ne) :< 0.15)
	for (w=1; w<=3; w++) {
		st_matrix("__T" + strofreal(w), X)
		F = (runiform(na, ne) :< 0.12)
		X = abs(X - F)
	}
}
dg_tm()
end
forvalues w = 1/3 {
	nwset, mat(__T`w') bipartite name(dt`w') nooutput
}
foreach sp in "ownx(outactego)" "ownx(divoutego:1)" "ownx(outactmoreego:0)" "ownx(outactsqrtmoreego:0)" "ownx(outmoreego:0)" "ownx(outinass:2)" "gwdspfb(0.69)" "avdeg(2)" "outtrunc(5)" "outmore(1)" "outthreshold(1)" {
	capture nwsaom, waves(dt1 dt2 dt3) outdegree `sp' k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505, 301)
	if _rc == 0 assert "`e(engine)'" == "native" & e(twomode) == 1
}
* non-directed: the truncated / threshold out-degree effects
foreach sp in "outtrunc(5)" "outmore(1)" "outmore(2)" "outthreshold(1)" {
	capture nwsaom, waves(ds1 ds2 ds3) symmetric outdegree `sp' k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
}
capture noisily nwsaom, waves(dd1 dd2 dd3) outdegree ownx(nosuch) k3(30)
assert _rc == 198
di "PASS ownx"
