capture program drop nw2clustering
program nw2clustering
	syntax [anything(name=netname)][, measure(string) level(int 1) GENerate(string) replace]

	unw_defs

	if "`generate'" == "" {
		local generate = "_clustering2_lev`level'"
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
	if _rc == 0 & "`replace'" == "" {
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
		di "{err}nw2clustering requires a two-mode network; see {help nwclustering} for one-mode networks."
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
	capture drop `generate'
	qui gen `generate' = .
	mata: _nw2c_run(`netobj', `nodes', `level', "`measure'", "`generate'")
	local C_avg = r(C_avg)
	mata: st_global("r(measure)", "`measure'")
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








