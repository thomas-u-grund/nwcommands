/*
	Fits edges + mutual on the shared benchmark network via nwergm, using
	nwergm's own DEFAULT control settings (method auto-selects mcmle
	since mutual is dyad-dependent; mcmcburnin=3000, mcmcinterval=50,
	mcmcsamplesize=3000, mcmleiterations=20, proposal=tnt) - i.e. exactly
	how a typical user would invoke it, with no special tuning for this
	benchmark. Times the WHOLE nwergm call (MPLE starting value + full
	MCMLE outer loop) with Stata's own timer.
*/
adopath + "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/lib"
adopath + "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016"
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_core.do"
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_ergm.do"
run "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/nwergm.ado"

// nwset's own mat() option cannot accept a bare Stata matrix NAME, only
// a literal parenthesized expression - and at n=30 (900 cells) that
// literal-expression workaround itself hits Stata's own "too many
// tokens" command-line limit (a genuine, pre-existing nwset.ado bug
// found while building nwergm's own estat gof - see
// docs/CERTIFICATION.md's own Pending list; the smaller test networks
// used everywhere else in this package's own test suite never scaled
// up far enough to hit this SECOND-order limit). Side-stepped here via
// nwset's OTHER input path entirely: a full dyad-census edgelist
// (every ordered pair, value 0/1), which every other cscripts/ test in
// this package already uses successfully at small scale.
import delimited using "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata/bench_net.csv", clear varnames(nonames)
gen ego = _n
reshape long v, i(ego) j(alter)
rename v value
drop if ego == alter
nwset ego alter value, edgelist directed name(bench30)

timer clear 1
set seed 999
timer on 1
nwergm bench30, edges mutual
timer off 1
timer list 1

di
di "======================================"
di "STATA nwergm: edges + mutual"
di "======================================"
di "Wall time: " %8.3f r(t1) " seconds"
di "Converged: " e(converged)
di "MCMLE iterations: " e(mcmle_iterations)
matrix list e(b)
matrix list e(V)
