* nwsaom bayes: (1) the Metropolis-Hastings steps on the unobserved ministep sequence are checked against exact enumeration of a 4-actor model
* (expected total number of ministeps with theta and the rates fixed); (2) a short run on the Glasgow data finishes, returns the documented
* results and its posterior is close to the method of moments fit.
cscript
adopath ++ "."
do unw_core.do
do unw_saom.do
nwclear

* --- 2. Glasgow s501-s503
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(G`w')
	nwset, mat(G`w') directed name(gl`w') nooutput
}
nwsaom, waves(gl1 gl2 gl3) outdegree reciprocity transtrip k3(500) seed(1)
matrix MOM = e(b)

* exact enumeration check on the 3 effects is not possible for 50 actors; the 4-actor check uses fixed theta and rates on this model
nwsaom bayes, nprewarm(20) nwarm(20) nmain(100) nrunmh(5) seed(7) notable
assert "`e(cmd)'" == "nwsaom_bayes"
assert e(ndraws) == 100
assert colsof(e(b)) == 3
assert colsof(e(rates)) == 2
assert e(accept_effects) > 0.02 & e(accept_effects) < 0.9
assert e(accept_diag) > 0.2
assert e(mean_chain_length) > 100
assert abs(el(e(b),1,1) - el(MOM,1,1)) < 0.5
assert abs(el(e(b),1,2) - el(MOM,1,2)) < 1.0
assert abs(el(e(b),1,3) - el(MOM,1,3)) < 0.4
assert el(e(rates),1,1) > 3 & el(e(rates),1,1) < 10
frame nwsaom_bayes_draws: assert _N == 100
* it can be re-run from its own results, and fixed rates stay fixed
nwsaom bayes, nprewarm(5) nwarm(5) nmain(10) nrunmh(2) fixrates rate0(6 5) seed(3) notable
frame nwsaom_bayes_draws: assert abs(rate1 - 6) < 1e-9 & abs(rate2 - 5) < 1e-9
* the dispatch as a subcommand and the direct program name
nwsaom_bayes, nprewarm(2) nwarm(2) nmain(5) nrunmh(2) seed(3) notable
assert e(ndraws) == 5

* --- exact check of the moves on the ministep sequence: replace the stored waves by three 4-actor networks and fix theta and the rates;
* the expected total number of ministeps given the two transitions is 29.831 (rate 4, outdegree -2, reciprocity 1.5, no transitive triplets),
* from the matrix power series of the 4096-state one-ministep transition matrix (dev/saom_bayes_exact.R)
matrix W1 = (0,1,0,0\0,0,1,0\1,0,0,0\0,0,0,0)
matrix W2 = (0,1,0,1\1,0,1,0\1,0,0,0\0,0,1,0)
matrix W3 = (0,0,1,1\1,0,0,0\0,1,0,1\1,0,0,0)
mata:
mata set matastrict off
class SaomGraph scalar tb_graph(real matrix Wm) {
	class SaomGraph scalar Gt
	real scalar i, j
	Gt = SaomGraph()
	Gt.init(4, 1)
	for (i=1; i<=4; i++) for (j=1; j<=4; j++) if (Wm[i,j] != 0) Gt.toggle(i, j)
	return(Gt)
}
__nwsaom_last_G1 = tb_graph(st_matrix("W1"))
__nwsaom_last_G2 = tb_graph(st_matrix("W2"))
__nwsaom_last_G3 = tb_graph(st_matrix("W3"))
end
nwsaom bayes, nprewarm(0) nwarm(20) nmain(15000) nrunmh(3) nimprovemh(0) theta0(-2 1.5 0) rate0(4 4) fixrates nsampconst(0) seed(11) notable
di "mean number of ministeps: " e(mean_chain_length) " (exact 29.831)"
assert abs(e(mean_chain_length) - 29.831) < 0.6
di "PASS nwsaom bayes: Glasgow run, results, fixed rates, dispatch"
