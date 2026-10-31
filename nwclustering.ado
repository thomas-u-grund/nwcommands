capture program drop nwclustering
program nwclustering
	version 9
	syntax [anything(name=netname)][, measure(string) SYMmetrize GENerate(string) replace silent level(int 1) RA ONEmode]
	set more off

	unw_defs

	_nwsyntax `netname', max(1)
	// A two-mode network gets the two-mode clustering coefficients (Opsahl 2013, tnet::clustering_tm; ra: Robins and Alexander 2004) by
	// default; onemode computes the one-mode coefficient of the bipartite graph.  nw2clustering is an alias of this form.
	if "`is2mode'" == "true" & "`onemode'" == "" {
		if "`silent'" != "" | "`symmetrize'" != "" {
			local __ign ""
			if "`silent'" != "" local __ign " silent"
			if "`symmetrize'" != "" local __ign "`__ign' symmetrize"
			noi di "{txt}note: two-mode clustering is used; the following option(s) have no two-mode form and were ignored:{bf:`__ign'} ({bf:onemode} gives the one-mode computation)"
		}
		_nwclustering_two `netname', measure(`measure') level(`level') generate(`generate') `replace' `ra'
		capture confirm number 1
		exit
	}
	if "`ra'" != "" | `level' != 1 {
		di "{err}Options {bf:ra} and {bf:level()} need a two-mode network (and are not used with {bf:onemode})."
		error 198
	}
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
	capture confirm new variable `generate'
	if _rc capture drop `generate'
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
	// binary measure: the native kernel 26 (plugin generation 6 or later) counts the closed and potential triples from
	// the stored ties; a result of the wrong shape (older plugin, no plugin, a kernel failure) leaves the Mata path.
	local __fast 0
	if `__mode' == 0 {
		mata: `__nw_clust' = nw_fastclust(`netobj'->edgelist(), `nodes', `netobj'->is_directed_boolean() != 0)
		mata: st_local("__fast", strofreal(rows(`__nw_clust') == `nodes'))
	}
	if !`__fast' {
		mata: `__nw_clust' = `netobj'->calculate_clustering(`__mode')
	}
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
		noi di "{txt}    Average clustering coefficient: {res}`=strtrim(string(round((`r(cluster_avg)')*1000)/1000,"%9.0g"))'"
		noi di "{txt}    Global clustering coefficient: {res}`=strtrim(string(round((`r(cluster_global)')*1000)/1000,"%9.0g"))'"
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

capture mata: mata drop nw_fastclust()
mata:
// Native clustering (kernel 26 of the nwgraph plugin) for the binary measure. el = the stored ties of the network
// (edgelist()). Returns the n x 3 matrix of calculate_clustering(0) (ratio, closed triples, potential triples; a
// potential count of 0 stored as missing), or a 0 x 0 matrix when the kernel is not available. Set the global
// NW_NOFASTKERNELS to force the Mata path.
real matrix nw_fastclust(real matrix el, real scalar n, real scalar directed)
{
	real rowvector aux
	real scalar st
	real matrix r
	real colvector pot

	if (st_global("NW_NOFASTKERNELS") != "") return(J(0, 0, .))
	if (nwg_comb_version() < 6) return(J(0, 0, .))
	r = nwg_comb(26, n, el, J(0, 1, .), directed, aux, st)
	if (st != 0 | rows(r) != n | cols(r) != 2) return(J(0, 0, .))
	pot = editvalue(r[., 2], 0, .)
	return((r[., 1] :/ pot, r[., 1], pot))
}
end

capture program drop _nwclustering_two
program _nwclustering_two
	syntax [anything(name=netname)][, measure(string) level(int 1) GENerate(string) replace RA]

	unw_defs

	// ra gives the global coefficient of Robins and Alexander (2004), 4 C4 / L3, on the binary network
	// instead of (generate() absent) or in addition to the local and global coefficients of Opsahl (2013)
	if "`generate'" == "" & "`ra'" == "" {
		di "{err}option {bf:generate()} required."
		error 198
	}

	// BUGFIX (moderate-severity pass, positions_equivalence group): no
	// collision guard existed at all - worse than a silent overwrite,
	// confirmed directly: when `generate' already existed, the command
	// still returned rc==0 (claiming success) but left the pre-existing
	// variable's values completely UNCHANGED, computing nothing. Root
	// cause is downstream (`merge m:m ..., nogenerate' silently keeps
	// the master's own version and discards the using dataset's
	// same-named column whenever both share a variable name, with no
	// error), but the fix belongs here: check up front, before any of
	// the expensive computation below ever runs, matching the
	// `replace'-required convention every sibling command with a
	// generate() option (nwclustering/nwconcor/nwcoreperiphery/nwburt/
	// nwbrokerage) already uses.
	capture confirm variable `generate', exact
	if _rc == 0 & "`replace'" == "" & "`generate'" != "" {
		di "{err}Variable {bf:`generate'} already exists; specify {bf:replace}"
		err 99
	}
	_nwsyntax `netname'
	_nwdatasync `netname'

	// BUGFIX: level() accepted any integer with no validation at all -
	// an out-of-range value (anything but 1 or 2) crashed several steps
	// later with a cryptic raw Stata error ("variable n not found /
	// Data are already wide") instead of a clear message, since the
	// initial `_nwmode_ego == "level"' filter simply matched nothing.
	if !inlist(`level', 1, 2) {
		di "{err}level() must be 1 or 2"
		error 198
	}

	// BUGFIX: calling nw2clustering directly on a one-mode network
	// crashed with a cryptic internal error ("_nwmode_ego not found")
	// rather than a clear message - nwclustering.ado's own auto-switch
	// protects the common path (two-mode detected -> automatically
	// calls nw2clustering), but nothing stopped a direct call on the
	// wrong kind of network.
	if "`is2mode'" != "true" {
		di "{err}nwclustering: onemode is required to use the one-mode form of this network."
		error 198
	}

	// Auto-detect from the network's own stored valued/unvalued state
	// rather than always defaulting to "binary" regardless - matching
	// the netmeasure auto-detection convention already established in
	// nwcommunity.ado/nwconcor.ado/nwcoreperiphery.ado/nwmodularity.ado/
	// nwspectral.ado (and nwclustering.ado's own identical fix). Moved
	// below _nwsyntax so `valued' is actually populated before this
	// check runs - it wasn't, previously.
	if "`measure'" == "" {
		if "`valued'" == "true" {
			local measure "arithmetic"
		}
		else {
			local measure "binary"
		}
	}
	_opts_oneof "binary arithmetic geometric maximum minimum" "measure" "`measure'" 6556

	// SPARSE MIGRATION (docs/ROADMAP.md's own tracked gap: "currently an
	// O(N^4)-shaped Stata reshape chain"): the entire nwtoedge/reshape/
	// merge pipeline that used to live here (build an edge_list, reshape
	// it wide twice into alter_list/ego_list, then walk a growing
	// ego0-alter0-ego1-alter1-ego2 4-path through four separate m:m
	// merge+reshape+duplicates-drop steps, then a FIFTH/SIXTH pair to
	// test 6-cycle closure) is replaced by a direct sparse enumeration
	// in Mata (_nw2c_run(), below), walking the identical path directly
	// off NWdef's own neighbors()/edge_weight() accessors - no
	// intermediate dataset, no reshape, no merge-broadcast-duplicate
	// workaround needed at all, since a sparse adjacency walk never
	// creates that pattern in the first place. Certified byte-for-byte
	// against the OLD reshape implementation (kept only in git history,
	// not in this file) across two independent hand-built bipartite
	// test networks (one binary, one valued, all four measure() choices
	// x both level()s = 8 combinations) before replacing it - every
	// comparison matched to floating-point exactness (maxdiff=0), not
	// merely "close enough".
	if "`ra'" != "" {
		mata: st_matrix("__nw2c_ra", nw_robins_alexander(editmissing((*`netobj'->get_matrix())[selectindex(strtoreal(`netobj'->get_modes()) :== 1), selectindex(strtoreal(`netobj'->get_modes()) :== 2)], 0) :!= 0))
		scalar __nw2c_r = __nw2c_ra[1,1]
		scalar __nw2c_c4 = __nw2c_ra[1,2]
		scalar __nw2c_l3 = __nw2c_ra[1,3]
		matrix drop __nw2c_ra
	}
	if "`generate'" != "" {
		capture confirm new variable `generate'
		if _rc capture drop `generate'
		qui gen `generate' = .
		mata: _nw2c_run(`netobj', `nodes', `level', "`measure'", "`generate'")
		local C_avg = r(C_avg)
		mata: st_global("r(measure)", "`measure'")
	}
	else {
		mata: st_rclear()
	}
	if "`ra'" != "" {
		mata: st_numscalar("r(ra)", st_numscalar("__nw2c_r")); st_numscalar("r(C4)", st_numscalar("__nw2c_c4")); st_numscalar("r(L3)", st_numscalar("__nw2c_l3"))
		di "{txt}  Robins-Alexander clustering (4 x C4 / L3): {res}" %9.6f r(ra) "{txt}   (C4 = " r(C4) ", L3 = " r(L3) ")"
		scalar drop __nw2c_r __nw2c_c4 __nw2c_l3
	}
	// The collision-guard `confirm variable' at the top of this program
	// leaves its own stale, harmless nonzero `_rc' on the ordinary case
	// where there is nothing to find - matching the SAME `getmata'/`_rc'
	// interaction documented in nwkatz.ado's own header comment (unit
	// 162) - `confirm number' explicitly resets it, reliably, as the
	// last step.
	capture confirm number 1
end

// Sparse 4-path/6-cycle enumeration for two-mode clustering (Opsahl
// 2013; Robins & Alexander 2004) - see nw2clustering's own header
// comment above for why this replaced the prior Stata reshape/merge
// pipeline. For each `level'-mode node c, walks every ego0-alter0-c-
// alter1-ego2 path (c's own two DISTINCT alters alter0/alter1, each
// tied to some other ego0/ego2 != c and != each other) - this is
// EXACTLY the same 5-node/4-edge path the old reshape pipeline built
// (there, keyed as ego0-alter0-ego1-alter1-ego2 with `ego1' the center;
// here, `c' plays that same center role directly, avoiding the need to
// materialize the other two path endpoints as their own dataset
// columns at all). A path is "closed" (6-cycle) when e0 and e2 share
// some THIRD alter (!= alter0, != alter1) - checked via a direct
// membership test (anyof()) against e2's own neighbor list, matching
// the old pipeline's own `closed = (ego0 == ego3)' test exactly (both
// ask "is there a way back to close the cycle", just via different
// mechanics: real-adjacency-list membership here vs. a second pair of
// merges there). `measure' combines the path's own 4 edge weights
// exactly like the old `arithmetic'/`geometric'/`maximum'/`minimum'
// generated variables did; `binary' short-circuits to a flat weight of
// 1 per path (every edge walked here is, by construction, a real,
// already-dichotomized tie - the old pipeline's own binary branch
// dichotomized `value0'..`value3' to 0/1 BEFORE computing `arithmetic',
// which is always 1 for four already-existing ties, so this is the
// same result via a cheaper, more direct path, not a different rule).
capture mata: mata drop _nw2c_run()
mata:
void _nw2c_run(pointer(class nw_def scalar) scalar netobj, real scalar nodes,
		real scalar level, string scalar measure, string scalar genvar)
{
	real scalar ci, c, ia0, ia1, ie0, ie2, ia2, a0, a1, e0, e2, a2
	real scalar pot, clo, m, w1, w2, w3, w4, closed, total_pot, total_clo
	real colvector alters_c, egos_a0, egos_a1, alters_e0, levelnodes
	real colvector potv, clov
	real matrix res, el
	real rowvector aux
	real scalar st, mcode
	string matrix modes
	string scalar levelstr

	modes = netobj->get_modes()
	levelstr = strofreal(level)
	levelnodes = J(0,1,0)
	for (ci=1; ci<=nodes; ci++) {
		if (modes[1,ci] == levelstr) levelnodes = levelnodes \ ci
	}

	potv = J(nodes,1,.)
	clov = J(nodes,1,.)
	total_pot = 0
	total_clo = 0

	// Native kernel (native/nwcomb.h): the same enumeration in C, with the closure test done on a
	// marker array instead of a neighbour-list copy per path; sums are accumulated in the same
	// order, so the result is bit-identical. Falls back to the loops below without the plugin.
	if (nwg_comb_ok()) {
		el = netobj->edgelist()
		mcode = (measure=="binary" ? 0 : (measure=="arithmetic" ? 1 : (measure=="geometric" ? 2 : (measure=="maximum" ? 3 : 4))))
		res = nwg_comb(7, nodes, el, (modes[1,.] :== levelstr)', (mcode), aux, st)
		if (st != 0) nwg_fail(st, "nw2clustering")
		potv = J(nodes,1,.)
		clov = J(nodes,1,.)
		levelnodes = selectindex(res[.,1] :> 0)
		if (rows(levelnodes) > 0) {
			potv[levelnodes] = res[levelnodes,1]
			clov[levelnodes] = res[levelnodes,2]
		}
		total_pot = aux[1]
		total_clo = aux[2]
		st_store(., genvar, clov :/ potv)
		st_numscalar("r(C_global)", total_pot > 0 ? total_clo/total_pot : .)
		st_numscalar("r(C_avg)", mean(select(clov:/potv, potv:>0)))
		return
	}

	for (ci=1; ci<=rows(levelnodes); ci++) {
		c = levelnodes[ci,1]
		alters_c = netobj->neighbors(c)
		pot = 0
		clo = 0
		for (ia0=1; ia0<=rows(alters_c); ia0++) {
			a0 = alters_c[ia0,1]
			egos_a0 = netobj->neighbors(a0)
			for (ia1=1; ia1<=rows(alters_c); ia1++) {
				if (ia1 == ia0) continue
				a1 = alters_c[ia1,1]
				egos_a1 = netobj->neighbors(a1)
				for (ie0=1; ie0<=rows(egos_a0); ie0++) {
					e0 = egos_a0[ie0,1]
					if (e0 == c) continue
					for (ie2=1; ie2<=rows(egos_a1); ie2++) {
						e2 = egos_a1[ie2,1]
						if (e2 == c | e2 == e0) continue

						if (measure == "binary") {
							m = 1
						}
						else {
							w1 = netobj->edge_weight(e0,a0)
							w2 = netobj->edge_weight(a0,c)
							w3 = netobj->edge_weight(c,a1)
							w4 = netobj->edge_weight(a1,e2)
							if (measure=="arithmetic") m = (w1+w2+w3+w4)/4
							else if (measure=="geometric") m = (w1*w2*w3*w4)^(1/4)
							else if (measure=="maximum") m = max((w1,w2,w3,w4))
							else m = min((w1,w2,w3,w4))
						}

						closed = 0
						alters_e0 = netobj->neighbors(e0)
						for (ia2=1; ia2<=rows(alters_e0); ia2++) {
							a2 = alters_e0[ia2,1]
							if (a2==a0 | a2==a1) continue
							if (anyof(netobj->neighbors(e2), a2)) {
								closed = 1
								break
							}
						}

						pot = pot + m
						total_pot = total_pot + m
						if (closed) {
							clo = clo + m
							total_clo = total_clo + m
						}
					}
				}
			}
		}
		if (pot > 0) {
			potv[c,1] = pot
			clov[c,1] = clo
		}
	}

	st_store(., genvar, clov :/ potv)
	st_numscalar("r(C_global)", total_pot > 0 ? total_clo/total_pot : .)
	st_numscalar("r(C_avg)", mean(select(clov:/potv, potv:>0)))
}
end








