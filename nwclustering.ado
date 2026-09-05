capture program drop nwclustering
program nwclustering
	version 9
	syntax [anything(name=netname)][, measure(string) SYMmetrize GENerate(string) replace silent]
	set more off

	unw_defs

	_nwsyntax `netname', max(1)
	_nwdatasync `netname'
	local original "`netname'"

	tempname symnet
	local symnet_created = 0
	if "`symmetrize'" != ""  {
		nwsym `netname', generate(`symnet') mode(max)
		_nwsyntax
		local symnet_created = 1
	}

	// Auto-detect from the network's own stored valued/unvalued state
	// rather than always defaulting to "binary" regardless - matching
	// the netmeasure auto-detection convention already established in
	// nwcommunity.ado/nwconcor.ado/nwcoreperiphery.ado/nwmodularity.ado/
	// nwspectral.ado. Previously, a valued network would silently get
	// dichotomized (measure(binary)) unless the caller explicitly asked
	// for a weighted formula - not wrong exactly (binary is a
	// legitimate, still-available choice), but surprising: the same
	// network's clustering coefficient would otherwise ignore tie
	// strength entirely by default with no indication anything was
	// being discarded.
	// A weighted measure is only meaningful for an undirected network
	// (see the "not defined for networks that are both weighted and
	// directed" guard just below) - auto-defaulting to "arithmetic" for
	// a directed+valued network would turn a previously-working call
	// (silently dichotomized, matching the pre-existing default) into
	// a hard error by default, which is a regression, not a fix.
	if "`measure'" == "" {
		if "`valued'" == "true" & "`directed'" != "true" {
			local measure "arithmetic"
		}
		else {
			local measure "binary"
		}
	}

	_opts_oneof "binary arithmetic geometric maximum minimum" "measure" "`measure'" 6556

	if "`is2mode'" == "true" {
		di "{err}{pstd}Network is a two-mode network. Automatically, switched to command {bf:nw2clustering}."
		nw2clustering `netname', measure(`measure') generate(`generate')
		exit
	}

	if ("`directed'" == "true" & "`measure'" != "binary") {
		di "{err}{pstd}Clustering coefficient not defined for networks that are both weighted and directed."
		di "{err}Either choose {bf:measure(binary)} or symmetrize the network."
		// BUGFIX: was a bare `exit' (no error code), so _rc reported 0
		// (success) even though the printed message says the command
		// failed and no generate() variable was ever created - a
		// silent-success bug that would fool any caller checking _rc.
		exit 198
	}

	// generate() is required (suite-wide generate()-required style
	// decision, 2026-09-05): nwclustering's whole purpose is producing
	// this variable, so - matching Stata's own egen/predict convention -
	// there is no default name to silently fall back to.
	if "`generate'" == "" {
		di "{err}option {bf:generate()} required."
		error 198
	}

	// Consistency (moderate-severity pass, positions_equivalence group):
	// every sibling command with a generate() option (nwconcor/
	// nwcoreperiphery/nwburt/nwbrokerage) already requires an explicit
	// replace before overwriting an existing variable; nwclustering had
	// no such guard at all and silently clobbered any pre-existing
	// variable of the target name.
	capture confirm variable `generate', exact
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; specify {bf:replace}"
		err 99
	}
	capture drop `generate'
	qui gen `generate' = .

	_nwsyntax `netname'
	_nwdatasync `netname'

	// PERFORMANCE FIX (this unit): this command used to implement its own
	// independent Stata-level pipeline here - nwtoedge, three separate
	// reshape wide/long round-trips, and two merge m:m string-keyed joins -
	// to enumerate every length-2 path in the graph via dataset operations.
	// calculate_clustering() in unw_core.do already implements the exact
	// same computation natively in Mata using sparse neighbor enumeration
	// (has_edge()/edge_weight(), no dense N-by-N matrix), but nothing ever
	// called it - confirmed empirically that this reshape/merge pipeline
	// took 459 SECONDS on a 10,000-node network (docs/PERFORMANCE_
	// BENCHMARKS.md), against a small fraction of a second for the Mata
	// equivalent. Mode order below matches calculate_clustering()'s own
	// documented convention exactly (0=binary/unvalued union-of-neighbors,
	// 1=arithmetic, 2=geometric, 3=maximum, 4=minimum).
	if "`measure'" == "binary" local __mode 0
	else if "`measure'" == "arithmetic" local __mode 1
	else if "`measure'" == "geometric" local __mode 2
	else if "`measure'" == "maximum" local __mode 3
	else local __mode 4

	qui if _N < `nodes' {
		set obs `nodes'
	}
	_nwsyntax `netname'

	tempname __nw_clust
	mata: `__nw_clust' = `netobj'->calculate_clustering(`__mode')
	mata: st_store((1::`nodes'), "`generate'", `__nw_clust'[.,1])
	mata: st_numscalar("clust_global", sum(`__nw_clust'[.,2]) / sum(`__nw_clust'[.,3]))
	mata: mata drop `__nw_clust'

	local cluster_global = clust_global
	capture scalar drop clust_global

	qui summarize `generate'
	local C_avg = r(mean)

	mata: st_rclear()
	mata: st_numscalar("r(cluster_global)", `cluster_global')
	mata: st_global("r(measure)", "`measure'")
	mata: st_numscalar("r(cluster_avg)", `C_avg')

	if "`symmetrize'" != "" {
		local netname "`original'"
	}

	// Consistency: nwconcor/nwcoreperiphery/nwburt/nwbrokerage/nwsimindex
	// all already offer `silent' to suppress this same display block;
	// nwclustering had no such option at all.
	if "`silent'" == "" {
		noi di "{hline 40}"
		noi di "{txt}  Network name: {res}`netname'"
		if "`symmetrize'" != "" {
			noi di "{txt}  Symmetrized: {res}true"
		}
		noi di "{hline 40}"
		noi di "{txt}    Measure: {res}`measure'"
		noi di "{txt}    Average clustering coefficient: {res}`=round(`r(cluster_avg)',0.001)'"
		noi di "{txt}    Global clustering coefficient: {res}`=round(`r(cluster_global)',0.001)'"
		noi di " "
	}
	if "`symmetrize'" != "" {
		mata: st_global("r(symmetrized)", "false")
	}
	_return hold rcluster
	// BUGFIX: `symnet' is only ever actually created (tempname just
	// reserves a name, it doesn't create anything) when `symmetrize' was
	// given - the overwhelming common case (a plain "nwclustering
	// netname, generate(x)" call, no symmetrize) never creates it at
	// all, so this "capture nwdrop `symnet'" legitimately failed
	// ("network not found") on every single ordinary call. `capture'
	// swallows the failure, but "_return restore" (a low-level command
	// for restoring held r()-class results, not an ordinary Stata
	// command) does not itself reset `_rc' the way a normal successful
	// command would - so the stale nonzero `_rc' from the failed nwdrop
	// silently leaked out as this command's own return code on every
	// plain call. Confirmed directly: "nwclustering mynet, generate(x)"
	// on an already-undirected network returned _rc==482 despite
	// completing correctly and printing its own results - the exact
	// same bug class (a `capture'd cleanup on a conditionally-created
	// temp object, nothing afterward resetting `_rc') already found and
	// fixed repeatedly elsewhere this session. Fixed by only attempting
	// the drop when `symnet' was actually created, guarded by the same
	// condition that created it - not just wrapping it more, since that
	// would still print the correct results while returning a
	// misleading nonzero code to any caller that checks `_rc'.
	if `symnet_created' {
		capture nwdrop `symnet'
	}
	_return restore rcluster
end

