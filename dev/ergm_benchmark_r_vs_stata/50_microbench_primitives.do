/*
	50_microbench_primitives.do -- isolates the per-call Mata cost of the
	individual primitives the MCMC hot loop exercises millions of times,
	as requested for the C/C++-backend decision (harmonisation unit 83).
	Not a head-to-head vs R (R has no equivalently-isolated public API for
	these primitives) - this measures nwergm's OWN Mata implementation
	only, at two realistic sparse sizes, to see where time actually goes
	before deciding what (if anything) to move to native code.

	Timing: Mata has no built-in sub-second stopwatch, so each timed block
	calls out to Stata's own `timer` via stata("timer on/off N") and reads
	the elapsed seconds back with st_numscalar("r(tN)") - confirmed this
	read path works (Mata's st_numscalar() can read r-class scalars by
	name, not just user scalars). All state is kept in ONE function's own
	locals (no file-scope "global" class variables - those are NOT valid
	as bare top-level declarations in a mata: block outside a function
	body, confirmed by direct trial while writing this).

	Run: /Applications/Stata/StataBE.app/Contents/MacOS/StataBE -e do \
	  "dev/ergm_benchmark_r_vs_stata/50_microbench_primitives.do"
*/

do "unw_ergm.do"

mata:
mata set matastrict off

void build_net(class ErgmGraph G, real scalar n, real scalar deg) {
	real scalar i, e, j
	for (i=1; i<=n; i++) {
		for (e=1; e<=deg; e++) {
			j = mod(i + e*7 + 3, n) + 1
			if (j != i & !G.has_edge(i,j)) G.toggle(i,j)
		}
	}
}

real scalar mb_time(string scalar label) {
	stata("timer off 9")
	stata("timer list 9")
	return(st_numscalar("r(t9)"))
}

void microbench(real scalar n, real scalar deg, real scalar directed, real scalar seed, real scalar reps) {
	class ErgmGraph scalar G
	class ErgmTermData scalar td_e, td_m, td_nm, td_g
	real scalar t, i, j, dummy
	real rowvector nb, dummyv
	real colvector attr
	real matrix dyads
	real scalar us_has_edge, us_toggle, us_tnt, us_edges, us_mutual, us_nodematch, us_gwesp, us_cn, us_nbout

	rseed(seed)
	G = ErgmGraph()
	G.init(n, directed)
	build_net(G, n, deg)

	attr = J(n,1,0)
	for (i=1; i<=n; i++) attr[i] = mod(i,2)

	td_e = ErgmTermData()
	td_m = ErgmTermData()
	td_nm = ErgmTermData()
	td_nm.attr = attr
	td_g = ErgmTermData()
	td_g.decay = 0.5

	dyads = J(reps, 2, 0)
	for (t=1; t<=reps; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		while (j==i) j = ceil(runiform(1,1)*n)
		dyads[t,.] = (i,j)
	}

	stata("timer clear 9")
	stata("timer on 9")
	for (t=1; t<=reps; t++) dummy = G.has_edge(dyads[t,1], dyads[t,2])
	us_has_edge = mb_time("has_edge") * 1000000 / reps

	stata("timer clear 9")
	stata("timer on 9")
	for (t=1; t<=reps; t++) {
		i = dyads[t,1]; j = dyads[t,2]
		G.toggle(i,j)
		G.toggle(i,j)
	}
	us_toggle = mb_time("toggle") * 1000000 / (2*reps)

	stata("timer clear 9")
	stata("timer on 9")
	for (t=1; t<=reps; t++) dummyv = ergm_propose_tnt(G)
	us_tnt = mb_time("tnt") * 1000000 / reps

	stata("timer clear 9")
	stata("timer on 9")
	for (t=1; t<=reps; t++) dummyv = change_edges(G, dyads[t,1], dyads[t,2], td_e)
	us_edges = mb_time("edges") * 1000000 / reps

	if (directed) {
		stata("timer clear 9")
		stata("timer on 9")
		for (t=1; t<=reps; t++) dummyv = change_mutual(G, dyads[t,1], dyads[t,2], td_m)
		us_mutual = mb_time("mutual") * 1000000 / reps
	}
	else us_mutual = .

	stata("timer clear 9")
	stata("timer on 9")
	for (t=1; t<=reps; t++) dummyv = change_nodematch(G, dyads[t,1], dyads[t,2], td_nm)
	us_nodematch = mb_time("nodematch") * 1000000 / reps

	stata("timer clear 9")
	stata("timer on 9")
	for (t=1; t<=reps; t++) dummyv = change_gwesp(G, dyads[t,1], dyads[t,2], td_g)
	us_gwesp = mb_time("gwesp") * 1000000 / reps

	stata("timer clear 9")
	stata("timer on 9")
	for (t=1; t<=reps; t++) dummy = G.common_neighbors(dyads[t,1], dyads[t,2])
	us_cn = mb_time("cn") * 1000000 / reps

	stata("timer clear 9")
	stata("timer on 9")
	for (t=1; t<=reps; t++) nb = G.neighbors_out(dyads[t,1])
	us_nbout = mb_time("nbout") * 1000000 / reps

	printf("n=%g deg=%g directed=%g reps=%g  final_degree_avg=%g\n", n, deg, directed, reps, 2*G.nties/n * (directed?0.5:1) + (directed? G.nties/n : 0))
	printf("  has_edge          %8.2f us/call\n", us_has_edge)
	printf("  toggle            %8.2f us/call\n", us_toggle)
	printf("  tnt_propose       %8.2f us/call\n", us_tnt)
	printf("  change_edges      %8.2f us/call\n", us_edges)
	if (directed) printf("  change_mutual     %8.2f us/call\n", us_mutual)
	printf("  change_nodematch  %8.2f us/call\n", us_nodematch)
	printf("  change_gwesp      %8.2f us/call\n", us_gwesp)
	printf("  common_neighbors  %8.2f us/call\n", us_cn)
	printf("  neighbors_out     %8.2f us/call\n", us_nbout)
	printf("\n")
}

microbench(100, 4, 1, 7001, 100000)
microbench(500, 6, 1, 7002, 100000)
microbench(100, 4, 0, 7003, 100000)
microbench(500, 6, 0, 7004, 100000)
end
