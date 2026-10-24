* single-network effects of the dyadic / behavior kind in two-mode and non-directed networks: a bipartite dyadic covariate (dyadcov), interactions in a two-mode network,
* the actors' dependent behavior as the covariate of crossXOutAct / avGroupEgoX / totGroupEgoX in a two-mode network, degAbsDiffX / degPosDiffX / higher of the
* behavior and higher / XRecip with changing covariates in a non-directed network. The observed statistics are RSiena's siena07 targets (dev/saom_rsiena_netfx_*.R / .do:
* estimates for 2 seeds agree there). Run from the repository root.
cscript
adopath ++ "."
qui do unw_core.do
qui do unw_saom.do
nwclear

* ---------------------------------------------------------------------- two-mode, 40 actors x 20 events
forvalues w = 1/3 {
	import delimited "dev/saom_twomode_w`w'.csv", clear varnames(1)
	mkmat v1-v20, matrix(T`w')
}
import delimited "dev/saom_twomode_cvA.csv", clear varnames(1)
mkmat ega, matrix(CA)
import delimited "dev/saom_twomode_cvB.csv", clear varnames(1)
mkmat altb, matrix(CB)
import delimited "dev/saom_netfx_dyad.csv", clear varnames(1)
mkmat v1-v20, matrix(DY)
import delimited "dev/saom_netfx_tmbeh.csv", clear varnames(1)
mkmat z1 z2 z3, matrix(ZB)
mata: CAm = st_matrix("CA"); CBm = st_matrix("CB"); ZBm = st_matrix("ZB")
clear
forvalues w = 1/3 {
	nwset, mat(T`w') bipartite name(tm`w') nooutput
}
gen double ega = .
gen double altb = .
forvalues w = 1/3 {
	gen double zb`w' = 0
}
mata: md = st_sdata(., "_nwmode"); ia = selectindex(md :== "2"); ie = selectindex(md :== "1")
mata: st_store(ia, "ega", CAm); st_store(ie, "altb", CBm); st_store(ia, ("zb1", "zb2", "zb3"), ZBm)

* a bipartite dyadic covariate: RSiena's X target 176.77 (sum over the two periods, centred by the mean of all cells)
nwsaom, waves(tm1 tm2 tm3) outdegree indegpopularity dyadcov(DY) k0(10) k3(30) seed(3)
assert "`e(engine)'" == "native" & e(twomode) == 1 & colsof(e(b)) == 3
mata: st = __nwsaom_last_M.full_statistic(__nwsaom_last_G2) + __nwsaom_last_M.full_statistic(__nwsaom_last_G3); st_numscalar("__t", st[2])
assert reldif(scalar(__t), 176.77) < 1e-4
* interaction of egoX and altX: RSiena's targets 71.484 (altX), 103.142 (egoX), -25.783 (interaction)
nwsaom, waves(tm1 tm2 tm3) outdegree nodeocov(ega) nodeicov(altb) interact(nodeocov#nodeicov) k0(10) k3(30) seed(3)
assert "`e(engine)'" == "native" & e(twomode) == 1 & colsof(e(b)) == 4
mata: st = __nwsaom_last_M.full_statistic(__nwsaom_last_G2) + __nwsaom_last_M.full_statistic(__nwsaom_last_G3); st_numscalar("__t", st[4])
assert reldif(scalar(__t), -25.783) < 1e-3
* refusals: a matrix of the wrong size, dyadcovrecip, sameXOutAct / diffXOutAct (siena07 crashes), avGroupEgoX with a constant covariate (RSiena stops)
capture nwsaom, waves(tm1 tm2 tm3) outdegree dyadcov(CA) k3(20)
assert _rc == 198
capture nwsaom, waves(tm1 tm2 tm3) outdegree dyadcovrecip(DY) k3(20)
assert _rc == 198
capture nwsaom, waves(tm1 tm2 tm3) outdegree samexoutact(ega) k3(20)
assert _rc == 198
capture nwsaom, waves(tm1 tm2 tm3) outdegree netx(avgroupegox:ega) k3(20)
assert _rc == 198

* the actors' behavior as the covariate: RSiena's targets 800 (crossXOutAct), 6.0583 (avGroupEgoX), 121.1667 (totGroupEgoX)
local i = 0
foreach ef in crossxoutact avgroupegox totgroupegox {
	local ++i
	local want : word `i' of 800 6.058333333 121.1666667
	nwsaom, waves(tm1 tm2 tm3) outdegree behavior(zb1 zb2 zb3 : linear quadratic) netbeh(`ef') k0(10) k3(30) seed(3)
	assert "`e(engine)'" == "native" & e(twomode) == 1
	mata: SaomBehSimSync(__nwsaom_last_M, *__nwsaom_last_Behwaves[1]); st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2)
	mata: SaomBehSimSync(__nwsaom_last_M, *__nwsaom_last_Behwaves[2]); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3)
	mata: st_numscalar("__t", (st1 + st2)[2])
	assert reldif(scalar(__t), `want') < 1e-6
}
* sameXOutAct / diffXOutAct of the behavior: siena07 crashes in a two-mode network, so they are not offered
capture nwsaom, waves(tm1 tm2 tm3) outdegree behavior(zb1 zb2 zb3 : linear) netbeh(samexoutact) k3(20)
assert _rc == 198

* ---------------------------------------------------------------------- two-mode with more events than actors: the behavior effects need at least as many actors
mata:
rseed(77)
st_matrix("__E1", (runiform(6, 9) :< 0.3))
st_matrix("__E2", (runiform(6, 9) :< 0.35))
st_matrix("__E3", (runiform(6, 9) :< 0.3))
end
clear
forvalues w = 1/3 {
	nwset, mat(__E`w') bipartite name(em`w') nooutput
}
forvalues w = 1/3 {
	gen double eb`w' = 0
}
mata: md = st_sdata(., "_nwmode"); ia = selectindex(md :== "2"); st_store(ia, ("eb1", "eb2", "eb3"), (mod(1::6, 4) :+ 1, mod((1::6) :+ 1, 4) :+ 1, mod(1::6, 4) :+ 1))
capture nwsaom, waves(em1 em2 em3) outdegree behavior(eb1 eb2 eb3 : linear) netbeh(crossxoutact) k3(20)
assert _rc == 198

* ---------------------------------------------------------------------- non-directed, 50 actors, behavior 0 - 9
clear
forvalues w = 1/3 {
	import delimited "sym_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(S`w')
}
forvalues p = 1/2 {
	import delimited "dev/saom_netfx_symdy`p'.csv", clear varnames(1)
	mkmat v1-v50, matrix(sdy`p')
}
import delimited "_tv.csv", clear varnames(1)
tempfile tvd
save `tvd'
import delimited "dev/saom_netfx_symbeh.csv", clear varnames(1)
merge 1:1 _n using `tvd', nogen
tempfile bd
save `bd'
clear
forvalues w = 1/3 {
	nwset, mat(S`w') directed name(sk`w') nooutput
}
merge 1:1 _n using `bd', nogen
* degAbsDiffX / degPosDiffX of the behavior: RSiena's targets 814 and 812 (estimates: both programs give large standard errors, the effects are nearly collinear with density)
local i = 0
foreach ef in degabsdiffx degposdiffx {
	local ++i
	local want : word `i' of 814 812
	capture nwsaom, waves(sk1 sk2 sk3) symmetric outdegree behavior(b1 b2 b3 : linear quadratic avalt) netbeh(`ef') k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 505)
	mata: SaomBehSimSync(__nwsaom_last_M, *__nwsaom_last_Behwaves[1]); st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2)
	mata: SaomBehSimSync(__nwsaom_last_M, *__nwsaom_last_Behwaves[2]); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3)
	mata: st_numscalar("__t", (st1 + st2)[2])
	assert reldif(scalar(__t), `want') < 1e-6
}
* higher of the behavior counts every tie once (RSiena's target 389, the density statistic): not identified; RSiena's standard errors are missing too
capture nwsaom, waves(sk1 sk2 sk3) symmetric outdegree behavior(b1 b2 b3 : linear quadratic avalt) netbeh(higher) k0(10) k3(30) seed(3)
assert inlist(_rc, 0, 505)
mata: SaomBehSimSync(__nwsaom_last_M, *__nwsaom_last_Behwaves[1]); st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2)
mata: SaomBehSimSync(__nwsaom_last_M, *__nwsaom_last_Behwaves[2]); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3)
mata: st_numscalar("__t", (st1 + st2)[2])
assert reldif(scalar(__t), 389) < 1e-6
* homXOutAct2 of the behavior: RSiena stops ("not implemented for behavioral variables")
capture nwsaom, waves(sk1 sk2 sk3) symmetric outdegree behavior(b1 b2 b3 : linear) netbeh(homxoutact2) k3(20)
assert _rc == 198
* higher with a changing covariate and XRecip with a changing dyadic covariate: RSiena's targets 389 and -3.1763
capture nwsaom, waves(sk1 sk2 sk3) symmetric outdegree higher(v) tvcov(v1 v2) k0(10) k3(30) seed(3)
assert inlist(_rc, 0, 505)
mata: SaomTVSync(__nwsaom_last_M, 1); st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2)
mata: SaomTVSync(__nwsaom_last_M, 2); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3)
mata: st_numscalar("__t", (st1 + st2)[2])
assert reldif(scalar(__t), 389) < 1e-6
capture nwsaom, waves(sk1 sk2 sk3) symmetric outdegree tvdyadcovrecip(sdy) k0(10) k3(30) seed(3)
assert inlist(_rc, 0, 505)
mata: SaomTVSync(__nwsaom_last_M, 1); st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2)
mata: SaomTVSync(__nwsaom_last_M, 2); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3)
mata: st_numscalar("__t", (st1 + st2)[2])
assert reldif(scalar(__t), -3.176326531) < 1e-6
di as text "PASS netfx: two-mode dyadcov / interact / behavior effects and non-directed behavior / changing-covariate effects"
