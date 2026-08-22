/*
	Coarse time-breakdown of a real nwergm MCMLE run on the shared
	30-node benchmark network (edges + mutual), decomposing the ~6-7
	second wall time into: data prep (bridging + MPLE), one MCMC
	simulation call at default settings (burnin/interval/samplesize),
	the full MCMLE outer loop, and (by subtraction) the outer-loop's own
	controller/variance overhead beyond the MCMC simulation itself.

	Does NOT modify any shipped function - times whole calls from
	outside, using the same theta/settings the real fit uses.
*/
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_ergm.do"

mata:
mata set matastrict off

gD = ErgmGraph()
gD.init(30, 1)

fh = fopen("/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata/bench_net.csv", "r")
for (i=1; i<=30; i++) {
	line = fget(fh)
	row = strtoreal(tokens(subinstr(line, ",", " ", .)))
	for (j=1; j<=30; j++) {
		if (row[j]==1 & !gD.has_edge(i,j)) gD.toggle(i,j)
	}
}
fclose(fh)
printf("network loaded: n=%g nties=%g\n", gD.n, gD.nties)

M = ErgmModel()
M.init()
td1 = ErgmTermData()
M.addterm("edges", 1, &stat_edges(), &change_edges(), td1, ("edges"))
td2 = ErgmTermData()
M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), td2, ("mutual"))

// MPLE-ish starting theta (close to the real MPLE for this network -
// exact value doesn't matter for a TIMING breakdown, only that it's a
// realistic starting point).
theta0 = (-1.9, -0.2)

st_matrix("theta0", theta0)
end

timer clear
* --- one MCMC simulation call at default settings, at theta0 - this is
* the cost of ONE MCMLE outer-loop iteration's own simulation phase.
timer on 1
mata: st_matrix("dummy1", ErgmMCMCSample(M, gD, theta0, 3000, 50, 3000, &ergm_propose_tnt()))
timer off 1

* --- the FULL ErgmMCMLE() call (verbose, so we can also read off the
* actual iteration count achieved).
set seed 999
timer on 2
mata: fit = ErgmMCMLE(M, gD, theta0, 20, 3000, 50, 3000, &ergm_propose_tnt(), 1)
timer off 2

timer list
mata: st_local("niter", strofreal(fit.niter))
mata: st_local("converged", strofreal(fit.converged))

di
di "======================================"
di "Profiling breakdown: 30-node edges+mutual"
di "======================================"
di "One ErgmMCMCSample() call (default burnin/interval/samplesize): " %7.3f r(t1) " sec"
di "Full ErgmMCMLE() call (niter=`niter', converged=`converged'):    " %7.3f r(t2) " sec"
di "Implied per-iteration MCMC-simulation time (t1 * niter):         " %7.3f (r(t1)*`niter') " sec"
di "Implied controller/variance/other overhead (t2 - t1*niter):      " %7.3f (r(t2) - r(t1)*`niter') " sec"
di "  (this overhead also includes ONE extra final ErgmMCMCSampleDiag() call for the variance estimate)"
