* nwsaom multinet with a two-mode member against RSiena: a two-mode network B (30 actors x 12 events) and a one-mode network F (same actors), 3 waves.
* RSiena side: dev/saom_rsiena_mn2m.R (same data, dev/saom_mn2m_*.csv). Environment variables: EFFS (cross effects of the dependent network DEP, our names), RS (RSiena
* shortNames in the same order, only for the log), DEP = B or F, MODE = targets | est, NSEEDS, EFF1/EFF2 (own effects, default outdegree / outdegree reciprocity).
cscript
set linesize 255
quietly do unw_core.do
quietly do unw_ergm.do
quietly do unw_saom.do
nwclear
clear
forvalues w = 1/3 {
	import delimited using "dev/saom_mn2m_B`w'.csv", clear varnames(nonames)
	mkmat v*, matrix(__B`w')
	import delimited using "dev/saom_mn2m_F`w'.csv", clear varnames(nonames)
	mkmat v*, matrix(__F`w')
}
import delimited using "dev/saom_mn2m_cov.csv", clear varnames(nonames)
mkmat v1, matrix(__cv)
import delimited using "dev/saom_mn2m_dy.csv", clear varnames(nonames)
mkmat v*, matrix(__dy)
import delimited using "dev/saom_mn2m_dyE.csv", clear varnames(nonames)
mkmat v*, matrix(__dyE)
clear
forvalues w = 1/3 {
	nwset, mat(__B`w') bipartite name(nb`w') nooutput
	nwset, mat(__F`w') directed name(nf`w') nooutput
}
gen double cv = .
mata: md = st_sdata(., "_nwmode"); st_store(selectindex(md :== "2"), "cv", st_matrix("__cv"))
foreach v in EFFS DEP MODE NSEEDS EFF1 EFF2 PARM {
	local __e : environment `v'
	global `v' "`__e'"
}
if "$EFF1" == "" global EFF1 outdegree
if "$EFF2" == "" global EFF2 outdegree reciprocity
if "$DEP" == "" global DEP B
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
		if "$DEP" == "B" {
			local cmd nwsaom multinet, net1(nb1 nb2 nb3) net2(nf1 nf2 nf3) cross1(`ef'$PARM)
		}
		else {
			local cmd nwsaom multinet, net1(nb1 nb2 nb3) net2(nf1 nf2 nf3) cross2(`ef'$PARM)
		}
		local cmd `cmd' eff1($EFF1) eff2($EFF2) k0($K0) k3($K3) seed(`sd')
		if "$MODE" == "targets" local cmd `cmd' fix(_all)
		capture noisily `cmd'
		if _rc {
			di "NWSAOM $DEP `ef' ERROR rc=" _rc
		}
		else {
			matrix __tg = e(target)
			mata: st_local("tg", invtokens(strofreal(colsum(st_matrix("__tg")), "%12.4f")))
			di "NWSAOM $DEP `ef' seed `sd' : targets(sum over periods) `tg'"
			matrix __b = e(b)
			matrix __r = e(rates)
			mata: st_local("bs", invtokens(strofreal(st_matrix("__b"), "%9.3f")))
			mata: st_local("rs", invtokens(strofreal((st_matrix("__r")[1,.], st_matrix("__r")[2,.]), "%9.3f")))
			mata: st_local("ses", invtokens(strofreal(sqrt(diagonal(st_matrix("e(V)")))', "%9.3f")))
			di "NWSAOM $DEP `ef' seed `sd' : est `bs' | rates(net1 periods, net2 periods) `rs' | se `ses'"
		}
	}
}
