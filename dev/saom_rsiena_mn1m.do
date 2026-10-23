* nwsaom multinet, two one-mode networks (directed F, H and non-directed S, 30 actors, 3 waves) against RSiena: dev/saom_rsiena_mn1m.R (same data).
* Environment variables: EFFS (our names), DEP and OTH in {F,H,S} (the dependent network that gets the cross effect, the other one), MODE = targets | est, NSEEDS, PARM (":..." suffix of the
* cross effect), EFF1/EFF2 (own effects of the dependent / the other network).
cscript
set linesize 255
quietly do unw_core.do
quietly do unw_ergm.do
quietly do unw_saom.do
nwclear
clear
foreach nm in F H S {
	forvalues w = 1/3 {
		if "`nm'" == "F" import delimited using "dev/saom_mn2m_F`w'.csv", clear varnames(nonames)
		else import delimited using "dev/saom_mn1m_`nm'`w'.csv", clear varnames(nonames)
		mkmat v*, matrix(__`nm'`w')
	}
}
import delimited using "dev/saom_mn2m_cov.csv", clear varnames(nonames)
mkmat v1, matrix(__cv)
import delimited using "dev/saom_mn2m_dy.csv", clear varnames(nonames)
mkmat v*, matrix(__dy)
clear
foreach nm in F H S {
	forvalues w = 1/3 {
		if "`nm'" == "S" nwset, mat(__`nm'`w') undirected name(n`nm'`w') nooutput
		else nwset, mat(__`nm'`w') directed name(n`nm'`w') nooutput
	}
}
gen double cv = .
mata: st_store(., "cv", st_matrix("__cv"))
foreach v in EFFS DEP OTH MODE NSEEDS EFF1 EFF2 PARM {
	local __e : environment `v'
	global `v' "`__e'"
}
if "$MODE" == "" global MODE targets
if "$NSEEDS" == "" global NSEEDS 2
if "$MODE" == "targets" {
	global NSEEDS 1
	global K0 10
	global K3 60
}
else {
	global K0 50
	global K3 1000
}
foreach ef of global EFFS {
	forvalues sd = 1/$NSEEDS {
		local cmd nwsaom multinet, net1(n${DEP}1 n${DEP}2 n${DEP}3) net2(n${OTH}1 n${OTH}2 n${OTH}3) cross1(`ef'$PARM)
		if "$DEP" == "S" local cmd `cmd' sym1
		if "$OTH" == "S" local cmd `cmd' sym2
		local e1 = cond("$EFF1" != "", "$EFF1", cond("$DEP" == "S", "outdegree", "outdegree reciprocity"))
		local e2 = cond("$EFF2" != "", "$EFF2", cond("$OTH" == "S", "outdegree", "outdegree reciprocity"))
		local cmd `cmd' eff1(`e1') eff2(`e2') k0($K0) k3($K3) seed(`sd')
		if "$MODE" == "targets" local cmd `cmd' fix(_all)
		capture noisily `cmd'
		if _rc {
			di "NWSAOM $DEP $OTH `ef' ERROR rc=" _rc
		}
		else {
			matrix __tg = e(target)
			mata: st_local("tg", invtokens(strofreal(colsum(st_matrix("__tg")), "%12.4f")))
			di "NWSAOM $DEP $OTH `ef' seed `sd' : targets(sum over periods) `tg'"
			matrix __b = e(b)
			matrix __r = e(rates)
			mata: st_local("bs", invtokens(strofreal(st_matrix("__b"), "%9.3f")))
			mata: st_local("rs", invtokens(strofreal((st_matrix("__r")[1,.], st_matrix("__r")[2,.]), "%9.3f")))
			mata: st_local("ses", invtokens(strofreal(sqrt(diagonal(st_matrix("e(V)")))', "%9.3f")))
			di "NWSAOM $DEP $OTH `ef' seed `sd' : est `bs' | rates(net1 periods, net2 periods) `rs' | se `ses'"
		}
	}
}
