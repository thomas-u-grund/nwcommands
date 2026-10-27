* The X1-X8 models of the article's benchmark_extra (nwsaom side); command strings and data builders copied
* from benchmark_extra/nwsaom_extra.do. Include after bench_models.do. Needs global XDIR = folder with the data CSVs.
local cmd_X1 "waves(tm1 tm2 tm3) outdegree indegpopularity cycle4 unconditional"
local cmd_X2 "waves(tm1 tm2 tm3) outdegree indegpopularity outactivity cycle4 outiso antiiniso2 unconditional"
local cmd_X3 "multinet, net1(glasgow1 glasgow2 glasgow3) net2(nb1 nb2 nb3) eff1(outdegree reciprocity) eff2(outdegree reciprocity) cross1(crprod) k0(100) k3(1000)"
local cmd_X4 "multinet, net1(glasgow1 glasgow2 glasgow3) net2(nb1 nb2 nb3) behavior(smoke1 smoke2 smoke3) beheff1(linear quadratic avalt) beheff2(avalt) k0(100) k3(1000)"
local cmd_X5 "multinet, net1(glasgow1 glasgow2 glasgow3) net2(nb1 nb2 nb3) behavior(smoke1 smoke2 smoke3) eff1(outdegree reciprocity behegox behaltx behsim) cross1(samewwclosure:behavior) beheff1(linear quadratic avalt) k0(100) k3(1000)"
local cmd_X6 "multinet, net1(ma1 ma2 ma3) net2(mb1 mb2 mb3) sym1 cross1(crprod) k0(100) k3(1000)"
local w3x "waves(glasgow1 glasgow2 glasgow3)"
local cmd_X7 "`w3x' outdegree reciprocity gwesp(.69) samextranstrip(smoke1) altxoutact(alcohol1) egoplusaltsqx(alcohol1)"
local cmd_X8 "`w3x' outdegree reciprocity ownx(transtrip1 transrectrip2 jout)"

capture program drop _x_data
program define _x_data
	args m
	nwclear
	if inlist("`m'", "X1", "X2") {
		local pfx = cond("`m'" == "X1", "saom_twomode_w", "saom_rsiena_v21_tm2_w")
		local ne  = cond("`m'" == "X1", 20, 30)
		forvalues w = 1/3 {
			qui import delimited "$XDIR/`pfx'`w'.csv", clear varnames(1)
			mkmat v1-v`ne', matrix(T`w')
		}
		clear
		forvalues w = 1/3 {
			qui nwset, mat(T`w') bipartite name(tm`w') nooutput
		}
	}
	else if inlist("`m'", "X3", "X4", "X5") {
		qui nwwebuse glasgow, nwclear
		mata: _x_net2()
		forvalues w = 1/3 {
			qui nwset, mat(__B`w') directed name(nb`w') nooutput
		}
	}
	else if "`m'" == "X6" {
		forvalues w = 1/3 {
			qui import delimited "$XDIR/saom_rsiena_symmulti_w`w'.csv", clear varnames(1) case(preserve)
			mkmat V1-V50, matrix(A`w')
			qui import delimited "$XDIR/saom_mn_b`w'.csv", clear varnames(1) case(preserve)
			mkmat V1-V50, matrix(B`w')
		}
		clear
		forvalues w = 1/3 {
			qui nwset, mat(A`w') undirected name(ma`w') nooutput
			qui nwset, mat(B`w') directed name(mb`w') nooutput
		}
	}
	else {
		qui nwwebuse glasgow, nwclear
	}
end

mata:
void _x_net2()
{
	real matrix A, F
	real scalar n, w
	rseed(99)
	n = 50
	A = (runiform(n, n) :< 0.08)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__B" + strofreal(w), A)
		F = (runiform(n, n) :< 0.04)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
end
