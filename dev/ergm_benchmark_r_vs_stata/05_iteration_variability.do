/*
	Characterizes how much the 30-node edges+mutual benchmark's own
	MCMLE iteration count (and hence wall time) varies across seeds,
	motivated by the observed spread (1 iteration/1.8s on one seed, 7
	iterations/6.6-7.0s on another). Runs the fit 20 times at different
	seeds and tabulates niter/converged.
*/
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_ergm.do"

mata:
mata set matastrict off

void run_variability() {
	class ErgmGraph scalar gD0, gD
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	struct ErgmMCMLEFit scalar fit
	real scalar fh, i, j, s, k
	string scalar line
	real rowvector row, theta0, niters, convs
	real matrix ties0

	gD0 = ErgmGraph()
	gD0.init(30, 1)

	fh = fopen("/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata/bench_net.csv", "r")
	for (i=1; i<=30; i++) {
		line = fget(fh)
		row = strtoreal(tokens(subinstr(line, ",", " ", .)))
		for (j=1; j<=30; j++) {
			if (row[j]==1 & !gD0.has_edge(i,j)) gD0.toggle(i,j)
		}
	}
	fclose(fh)

	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), td1, ("edges"))
	td2 = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), td2, ("mutual"))

	theta0 = (-1.9, -0.2)

	niters = J(1, 20, 0)
	convs = J(1, 20, 0)
	for (s=1; s<=20; s++) {
		gD = ErgmGraph()
		gD.init(30, 1)
		ties0 = gD0.all_ties()
		for (k=1; k<=rows(ties0); k++) gD.toggle(ties0[k,1], ties0[k,2])

		rseed(8000+s)
		fit = ErgmMCMLE(M, gD, theta0, 20, 3000, 50, 3000, &ergm_propose_tnt(), 0)
		niters[s] = fit.niter
		convs[s] = fit.converged
	}

	printf("niter across 20 seeds: ")
	for (s=1; s<=20; s++) printf("%g ", niters[s])
	printf("\n")
	printf("converged across 20 seeds: ")
	for (s=1; s<=20; s++) printf("%g ", convs[s])
	printf("\n")
	printf("mean niter=%5.2f  min=%g  max=%g  sd=%5.2f  #converged=%g/20\n", mean(niters'), min(niters), max(niters), sqrt(variance(niters')), sum(convs))
}

run_variability()
end
