/*
	dev/ergm_benchmark.do -- development-only benchmark script (never
	shipped, not part of any _pkg_*.txt manifest, matching
	dev/ergm_reference/'s own established convention).

	Measures the specific hot paths Part XXV of the governing nwergm
	task named explicitly: edge lookup (has_edge), toggle, degree update
	(bundled into toggle - ErgmGraph maintains degree incrementally, not
	as a separate pass), common-neighbor calculation, the GWESP change
	statistic, and ~1M simple MCMC proposals. Purely measurement - "do
	not optimize unprofiled code prematurely" - the point is to know
	where time actually goes before deciding whether a C/C++ plugin is
	ever warranted, not to optimize speculatively. Results are recorded
	in docs/CERTIFICATION.md's own harmonisation-unit entry for this
	benchmarking pass, not just left in this script's own output.

	Timing uses Stata's own `timer on/off/list` around each Mata call -
	Mata itself has no built-in elapsed-time function, so each bench_*()
	function below purely performs the work and Stata measures wall time
	around the call.

	Run: /Applications/Stata/StataBE.app/Contents/MacOS/StataBE -e do "dev/ergm_benchmark.do"
*/

do "unw_ergm.do"

mata:
mata set matastrict off

void bench_toggle(real scalar n, real scalar reps){
	class ErgmGraph scalar G
	real scalar i, j
	G = ErgmGraph()
	G.init(n, 0)
	for (i=1; i<=reps; i++) {
		j = mod(i, n) + 1
		if (j==1) j = 2
		G.toggle(1, j)
	}
}

void bench_has_edge(real scalar n, real scalar reps){
	class ErgmGraph scalar G
	real scalar i, j, dummy
	G = ErgmGraph()
	G.init(n, 0)
	for (i=2; i<=n; i++) G.toggle(1, i)
	dummy = 0
	for (i=1; i<=reps; i++) {
		j = mod(i, n) + 1
		dummy = dummy + G.has_edge(1, j)
	}
}

void bench_common_neighbors(real scalar n, real scalar reps){
	class ErgmGraph scalar G
	real scalar i, j, dummy, e
	G = ErgmGraph()
	G.init(n, 0)
	// build a moderately dense network (every node tied to ~10 others)
	// so common_neighbors() has real work to do.
	for (i=1; i<=n; i++) {
		for (e=1; e<=10; e++) {
			j = mod(i+e*7, n) + 1
			if (j != i & !G.has_edge(i,j)) G.toggle(i,j)
		}
	}
	dummy = 0
	for (i=1; i<=reps; i++) {
		j = mod(i, n) + 1
		if (j==1) j = 2
		dummy = dummy + G.common_neighbors(1, j)
	}
}

void bench_gwesp_change(real scalar n, real scalar reps){
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar i, j, e
	real rowvector dummy
	G = ErgmGraph()
	G.init(n, 0)
	for (i=1; i<=n; i++) {
		for (e=1; e<=10; e++) {
			j = mod(i+e*7, n) + 1
			if (j != i & !G.has_edge(i,j)) G.toggle(i,j)
		}
	}
	td.decay = 0.5
	for (i=1; i<=reps; i++) {
		j = mod(i, n) + 1
		if (j==1) j = 2
		dummy = change_gwesp(G, 1, j, td)
	}
}

void bench_mcmc_proposals_tnt(real scalar n, real scalar nsteps){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	G = ErgmGraph()
	G.init(n, 0)
	M = ErgmModel()
	M.init()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), td, ("edges"))
	ErgmMCMCSample(M, G, (-1.0), 0, 1, nsteps, &ergm_propose_tnt())
}

void bench_mcmc_proposals_uniform(real scalar n, real scalar nsteps){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	G = ErgmGraph()
	G.init(n, 0)
	M = ErgmModel()
	M.init()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), td, ("edges"))
	ErgmMCMCSample(M, G, (-1.0), 0, 1, nsteps, &ergm_propose_uniform())
}
end

local n = 200
local reps = 200000
local nsteps = 20000

timer clear
timer on 1
mata: bench_toggle(`n', `reps')
timer off 1

timer on 2
mata: bench_has_edge(`n', `reps')
timer off 2

timer on 3
mata: bench_common_neighbors(`n', `reps')
timer off 3

timer on 4
mata: bench_gwesp_change(`n', `reps')
timer off 4

timer on 5
mata: bench_mcmc_proposals_tnt(`n', `nsteps')
timer off 5

timer on 6
mata: bench_mcmc_proposals_uniform(`n', `nsteps')
timer off 6

timer list

di
di "n=`n' reps=`reps' nsteps=`nsteps' (all timer values r(t#) are in SECONDS; converting to microseconds/call below via *1e6)"
di "toggle():            " %8.3f (r(t1)*1000000/`reps') " us/call  (total " %6.3f r(t1) " sec)"
di "has_edge():          " %8.3f (r(t2)*1000000/`reps') " us/call  (total " %6.3f r(t2) " sec)"
di "common_neighbors():  " %8.3f (r(t3)*1000000/`reps') " us/call  (total " %6.3f r(t3) " sec)"
di "change_gwesp():      " %8.3f (r(t4)*1000000/`reps') " us/call  (total " %6.3f r(t4) " sec)"
di "MCMC proposals (TNT):" %8.3f (r(t5)*1000000/`nsteps') " us/step (total " %6.2f r(t5) " sec for `nsteps' steps)"
di "MCMC proposals (unif):" %7.3f (r(t6)*1000000/`nsteps') " us/step (total " %6.2f r(t6) " sec for `nsteps' steps)"
