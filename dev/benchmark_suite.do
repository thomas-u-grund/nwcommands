* Performance benchmark suite - stress-tests representative analysis
* commands at N = 100, 1000, 10000 nodes on a standard sparse random
* network (average degree ~10, held constant across sizes so timing
* differences reflect algorithmic scaling with N, not density changes).
* Two-mode commands additionally get a bipartite network sized the same
* way (N ego nodes, N/10 alter nodes). Written for the harmonisation
* phase's user-requested performance study (feeding both a future
* optimization pass and a Stata Journal writeup) - see
* docs/PERFORMANCE_BENCHMARKS.md for the resulting report.
*
* Deliberately excluded: nwergm (already has its own dedicated R-vs-Stata
* benchmark suite, dev/ergm_benchmark_r_vs_stata/ - re-running it here
* would duplicate published numbers, not add new ones); nwplot/nwmovie/
* nwmoviexy (rendering-bound, not a node-count-scaling question);
* nwimport/nwexport/nwuse/nwwebuse (I/O-bound, not algorithmic).
*
* Methodology note: single-rep timing per command per size (not a
* median of several reps) - a deliberate scope tradeoff to keep total
* runtime tractable across ~45 commands x 3 sizes. Permutation-based
* commands (nwcug/nwqap/nwpermute/nwmixing) use a reduced rep count
* (50, noted in the results) rather than their own defaults (500-1000),
* since their own cost is reps x per-rep-cost and the per-rep cost is
* what this suite is actually trying to measure.

* NOT "clear all" - that also clears Mata's compiled state, which would
* wipe out unw_core.do's own classes/functions if this script is run
* (as intended) right after `do unw_core.do` in the same session.
clear
set more off
set graphics off

tempname results
tempfile resultsfile
postfile `results' str24 command str16 category long nodes double seconds long rc using `resultsfile', replace
* `program bench' below is its own local-macro scope - it cannot see
* `results' from this outer scope directly (confirmed directly: without
* this, `post `results'' silently expanded to a blank name inside
* bench, producing a bare "post (...)" and an "( invalid name" crash
* that ended the whole script on the very first call). Copied into a
* global instead of threading it through every single bench() call's
* own argument list.
global benchresults_g "`results'"

capture program drop bench
program bench
	args cmdname category n stmt
	timer clear 99
	timer on 99
	cap noi `stmt'
	local rc = _rc
	timer off 99
	qui timer list 99
	local t = r(t99)
	post $benchresults_g ("`cmdname'") ("`category'") (`n') (`t') (`rc')
	di as txt "  `cmdname' (n=`n'): " as res %9.4f `t' as txt " sec, rc=" as res `rc'
	timer clear 99
end

foreach n in 100 1000 10000 {
	di as txt _n "{hline 60}" _n "N = `n'" _n "{hline 60}"

	local avgdeg = 10
	local p = `avgdeg' / (`n' - 1)

	nwclear
	set seed 20260823
	nwrandom `n', prob(`p') undirected name(bignet)
	qui nwsummarize bignet
	* undirected networks return r(edges), directed ones r(arcs)
	local nties = cond(missing(r(edges)), r(arcs), r(edges))
	di as txt "actual ties: `nties'"

	* Group/attribute variable needed by nwbrokerage/nwmixing. NOT built
	* via nwload+nwsync (tried first, and wrong): nwset's own bipartite
	* construction further below changes the active dataset's own
	* observation count to match ITS network's total node count
	* (n + nalter) - a later nwload'ed bignet-based command run against
	* that now-mismatched dataset then crashes ("rows of matrix != _N",
	* r459 - confirmed directly this way on nwkatz specifically before
	* this fix). Sidestepped entirely by keeping every bignet-only
	* benchmark call (below) strictly BEFORE the bipnet/bignet2
	* constructions further down, and building the group variable
	* directly (set obs + gen) rather than round-tripping through
	* nwload/nwsync at all.
	qui set obs `n'
	* a plain named variable, not a tempvar - nwmixing.ado derives its
	* own companion variable names by string-appending onto whatever
	* name attribute() is given, which doesn't work cleanly against a
	* tempvar's own auto-generated `__NNNNNN' name (confirmed directly:
	* "variable __000000_nwego not found").
	capture drop _grp
	gen _grp = mod(_n, 4)
	local grp "_grp"

	* --- centrality ---
	bench nwdegree      centrality `n' "nwdegree bignet, generate(_bd) replace"
	bench nwbetween     centrality `n' "nwbetween bignet, generate(_bb) replace silent"
	* nwcloseness/nwkatz/nwburt/nwconstraint/nwissymmetric/nwsimilar/
	* nwdissimilar/nwqap all confirmed (directly, during this benchmark
	* run) to depend on a dense N-by-N matrix somewhere internally
	* (several via nwtomata's own dense conversion; nwkatz via a direct
	* matrix-power operation on get_matrix(), already documented in
	* nw_intro.sthlp's own "needs the full adjacency matrix" category) -
	* not fixable the way vertex_connectivity() was (no sparse
	* equivalent for a genuine matrix-power/all-pairs operation the way
	* there was for max-flow), and not attempted here given time
	* constraints. Capped at n<=1000 (nwtomata's own dense conversion at
	* n=10000 is a 100M-cell/800MB materialization plus whatever
	* downstream all-pairs computation the caller does on top of it -
	* confirmed too slow to complete in a reasonable time directly).
	if `n' <= 1000 {
		bench nwcloseness   centrality `n' "nwcloseness bignet, generate(_bc) replace"
	}
	bench nwevcent      centrality `n' "nwevcent bignet, generate(_be) replace"
	if `n' <= 1000 {
		bench nwkatz        centrality `n' "nwkatz bignet, generate(_bk) replace"
	}
	bench nwbrokerage   centrality `n' "nwbrokerage bignet, group(`grp') generate(_bkg) replace"
	if `n' <= 1000 {
		bench nwburt        centrality `n' "nwburt bignet, replace"
	}
	bench nwego         centrality `n' "nwego bignet, replace"
	* nwaltergen excluded: it takes a statistical expression over an
	* alter-level attribute (e.g. "mean(alter.wealth)"), not a bare
	* network - doesn't fit this suite's generic "run the command on a
	* random network" methodology without a domain-specific attribute
	* to aggregate.
	if `n' <= 1000 {
		bench nwconstraint  centrality `n' "nwconstraint bignet"
	}

	* --- structural ---
	bench nwcomponents  structural `n' "nwcomponents bignet, generate(_comp) replace"
	bench nwclustering  structural `n' "nwclustering bignet, generate(_cl)"
	bench nwneighbor    structural `n' "nwneighbor bignet, ego(n1) generate(_nb) replace"
	* nwtriads confirmed dense-matrix-based too (calculate_triadcensus()
	* operates on get_matrix_unvalued(), the dense accessor, with
	* several chained dense-matrix operations) - same exclusion pattern
	* as the nwtomata/nwkatz-family commands above.
	if `n' <= 1000 {
		bench nwtriads      structural `n' "nwtriads bignet"
	}
	if `n' <= 1000 {
		bench nwissymmetric structural `n' "nwissymmetric bignet"
	}
	bench nwsym         structural `n' "nwsym bignet, generate(bignet_sym)"
	* nwkcomponents: fixed elsewhere this unit (vertex_connectivity()'s
	* O(n^2)->O(delta^2) rewrite - see docs/CERTIFICATION.md unit 102),
	* but the REMAINING dense max-flow representation still scales
	* worse than the package's genuinely sparse-native commands (100s
	* at n=100, 17.5s at n=1000, confirmed too slow to complete in a
	* reasonable time at n=10000 during this exact benchmark run) -
	* exactly the residual gap that unit's own write-up already
	* predicted and tracked as a Pending follow-on (a fully sparse
	* max-flow rewrite). Capped at n<=1000 here for that reason.
	if `n' <= 1000 {
		bench nwkcomponents structural `n' "nwkcomponents bignet, k(2) generate(_kcomp) replace"
	}
	bench nwkcore       structural `n' "nwkcore bignet, generate(_kcore) replace"

	* --- cohesive subgroups ---
	bench nwclique      cohesive `n' "nwclique bignet, generate(_cq) replace"
	* nwkplex (k>=2, a permissive relaxation of a clique - each member
	* may be missing up to k ties within the group) confirmed to blow up
	* combinatorially past n=100 on this test network (did not complete
	* in 2 minutes at n=1000) - a well-known property of k-plex
	* enumeration specifically (the count of maximal k-plexes can be far
	* larger than the count of maximal cliques on the same graph), not a
	* fixable implementation bug the way vertex_connectivity() was.
	* Benchmarked at n=100 only.
	if `n' <= 100 {
		bench nwkplex       cohesive `n' "nwkplex bignet, k(2) generate(_kp) replace"
	}
	* nwnclique/nwnclan (n>=2) excluded entirely from this sweep: both
	* reduce to maximal-clique enumeration (BronKerbosch) on the
	* "geodesic distance <= n" DERIVED graph, not the original network -
	* and this test network's own diameter is small (typical for a
	* dense-ish random graph at avg degree 10), so that derived graph is
	* itself near-complete. Maximal-clique counts on a near-complete
	* graph can blow up combinatorially (a well-known property of the
	* n-clique concept itself for n>=2, not specific to this
	* implementation) - confirmed directly: nwnclique with n(2) did not
	* complete even at n=20-30. See docs/PERFORMANCE_BENCHMARKS.md's own
	* methodology notes for a smaller, sparser dedicated scaling probe.
	*
	* nwcohesion (the full recursive, multi-level Moody-White cohesive
	* blocking hierarchy, built on top of the same vertex_connectivity()
	* fixed elsewhere this unit) confirmed to not complete in 2 minutes
	* at n=1000 either, even with that fix - the recursion itself visits
	* many node subsets, each paying its own (now much cheaper, but
	* still nonzero) vertex_connectivity()/KComponents() cost, and can
	* compound at this network's own density. Benchmarked at n=100 only.
	if `n' <= 100 {
		bench nwcohesion    cohesive `n' "nwcohesion bignet, generate(_coh) replace"
	}

	* --- path / distance ---
	bench nwgeodesic    distance `n' "nwgeodesic bignet, generate(_geo) nwreplace"
	bench nwpath        distance `n' "nwpath bignet, ego(n1) alter(n2)"
	bench nwreach       distance `n' "nwreach bignet"
	bench nwbridges     distance `n' "nwbridges bignet, nwreplace"

	* --- community detection ---
	bench nwcommunity   community `n' "nwcommunity bignet, generate(_comm) replace silent"
	bench nwmodularity  community `n' "nwmodularity bignet, group(_comm)"

	* --- equivalence / similarity ---
	bench nwsimindex     equivalence `n' "nwsimindex bignet, measure(jaccard) name(_sim) replace"
	if `n' <= 1000 {
		bench nwsimilar      equivalence `n' "nwsimilar bignet"
		bench nwdissimilar   equivalence `n' "nwdissimilar bignet"
	}
	bench nwconcor       equivalence `n' "nwconcor bignet, generate(_concor) splits(1) replace silent"
	bench nwcoreperiphery equivalence `n' "nwcoreperiphery bignet, generate(_cp) replace silent"

	* --- spectral ---
	* nwspectral needs a full Laplacian eigendecomposition (symeigensystem)
	* - already documented (nw_intro.sthlp) as a deliberate dense-by-
	* necessity exception, since it needs the whole eigenspectrum, not
	* just a dominant pair (unlike nwevcent, migrated to sparse power
	* iteration elsewhere this unit). O(n^3) at n=10000 excluded here on
	* the same grounds as the other dense exceptions, without spending
	* further time confirming empirically given the well-established
	* complexity class.
	if `n' <= 1000 {
		bench nwspectral    spectral `n' "nwspectral bignet, generate(_spec) replace silent"
	}

	* --- dyad-level (still bignet-only - kept before bipnet/bignet2
	* construction below, which change the active dataset's own
	* observation count; see the note above `grp''s own construction) ---
	* nwmixing excluded: consistently fails ("variable X_nwego not
	* found", r111) even against a plain named attribute variable on a
	* freshly nwload'ed network - nwmixing.ado's own internal
	* `nwtoedge ..., egovars(attribute) altervars(attribute)' call
	* apparently doesn't materialize the companion variable it then
	* immediately expects to exist. Not root-caused further given time
	* constraints; tracked in docs/CERTIFICATION.md's Pending list as a
	* possible real bug rather than assumed to be this suite's own
	* setup mistake, since a plain nwload-then-gen precondition is
	* about as standard as this package's own conventions get.
	bench nwdyads       dyad `n' "nwdyads bignet"

	* --- two-mode --- a bipartite network for these specifically (N
	* ego, N/10 alter) - nwrandom has no two-mode mode, so built
	* directly via a random incidence matrix and nwset's own bipartite
	* input shape. mat() evaluates its argument as a bare Mata
	* expression (a documented, pre-existing limitation - see
	* docs/CERTIFICATION.md's own Pending entry on nwset.ado - a bare
	* STATA matrix name does not work, but a Mata variable name
	* genuinely holding a matrix does), so this uses a plain Mata
	* variable, not st_matrix().
	local nalter = max(5, floor(`n'/10))
	mata: bipmat = (runiform(`n', `nalter') :< 0.1)
	nwset, mat(bipmat) bipartite name(bipnet)
	bench nw2degree      twomode `n' "nw2degree bipnet, generate(_2deg) replace"
	* nw2clustering excluded: found broken during this benchmark's own
	* validation pass (a "Type reshape error", r9) on ANY random
	* bipartite network tried, including small ones (n=20) - not an
	* artifact of this suite's own construction. The error message
	* itself ("...i(ego0 alter0 ego1 alter1 ego2 alter)...") shows a
	* malformed i()-varlist missing a numeric suffix on its last
	* variable, pointing at a string-construction bug in the command's
	* own reshape call. A real, previously-undiscovered correctness bug,
	* not a performance issue - out of scope to fix under this same
	* benchmark-driven pass; tracked in docs/CERTIFICATION.md's Pending
	* list instead.
	bench nw2project     twomode `n' "nw2project bipnet, project(1) name(bipnet_proj)"

	* --- structural-equivalence / permutation stats (reduced reps) ---
	* a second, independent same-size network, needed only here (QAP)
	nwrandom `n', prob(`p') undirected name(bignet2)
	bench nwcug        permutation `n' "nwcug bignet, stat(nwcomponents ##net##, replace) rname(components) reps(50) silent"
	if `n' <= 1000 {
		bench nwqap        permutation `n' "qui nwqap bignet bignet2, permutations(50)"
	}
	bench nwpermute    permutation `n' "nwpermute bignet, generate(bignet_perm)"

	* --- generators (construction cost itself) ---
	bench nwrandom_gen  generator `n' "nwrandom `n', prob(`p') name(gentest)"
	bench nwsmall_gen   generator `n' "nwsmall `n', k(4) prob(0.1) name(gentest2)"
	bench nwpref_gen    generator `n' "nwpref `n', m(3) name(gentest3)"
	bench nwlattice_gen generator `n' "nwlattice `n' 1, name(gentest4)"
	bench nwring_gen    generator `n' "nwring `n', k(2) name(gentest5)"

	* --- misc ---
	bench nwsummarize   misc `n' "nwsummarize bignet"
	bench nwvalue       misc `n' "nwvalue bignet, egoid(1) alterid(2)"
}

postclose `results'
use `resultsfile', clear
export delimited using "dev/benchmark_results.csv", replace
save "dev/benchmark_results.dta", replace
di as txt _n "Done. Results in dev/benchmark_results.csv / .dta"
