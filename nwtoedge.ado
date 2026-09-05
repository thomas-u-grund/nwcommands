
capture program drop nwtoedge
program nwtoedge
	version 9
	syntax [anything(name=netname)][, isolates0 compress upper egovars(varlist) altervars(varlist) numeric ///
	ego(name) alter(name) full ignore2mode comparevars(varlist) comparemode(string)]

	unw_defs
	_nwsyntax `netname', max(9999)
	local nets `netname'

	// comparevars()/comparemode(): ego/alter comparison columns (e.g.
	// "does this dyad share the same category?", "how far apart are
	// ego's and alter's values?") - the Stage 5 roadmap item this adds.
	// Rather than duplicating nwexpand's own same/dist/absdist/distinv/
	// absdistinv/sender/receiver vocabulary, each compare variable is
	// expanded into its own dyadic network via nwexpand itself (already
	// certified, unmodified), auto-named "`comparemode'_`var'" (nwexpand's
	// own default naming when name() is omitted) - then simply appended
	// to `nets', so every downstream step (the directed/full check, tie
	// extraction, merging) needs no changes at all: it already treats
	// every entry in `nets' identically regardless of where it came from.
	// dist()/distinv()/sender()/receiver() networks are directed by
	// construction (ego's value minus alter's is not alter's minus
	// ego's) - nwtoedge's own pre-existing "any directed network in the
	// list forces full" rule already handles this correctly with no
	// extra logic, giving both (i,j) and (j,i) rows so the signed
	// comparison is preserved in both directions.
	if "`comparevars'" != "" {
		if "`comparemode'" == "" {
			local comparemode "same"
		}
		// network(): without it, nwexpand falls back to its own generic
		// "n1".."nK" node labels instead of the actual network's labels -
		// silently breaking the (ego,alter) merge below, since it then
		// treats the comparison network's dyads as an entirely different
		// node set from every real network in `nets' (confirmed via a
		// direct probe: the merge produced the union of both label sets
		// instead of matching them, before this fix).
		local firstnet : word 1 of `netname'
		foreach cvar of varlist `comparevars' {
			qui nwexpand `cvar', mode(`comparemode') network(`firstnet') nodes(`nodes')
			local nets "`nets' `comparemode'_`cvar'"
		}
	}

	if "`ego'" == "" {
		local ego = "`nw_ego'"
	}
	if "`alter'" == "" {
		local alter = "`nw_alter'"
	}	

	// BUGFIX: `_nwdatasync' (this program's own `_nwinclude'-generating
	// mechanism) DROPS and REGENERATES `_nwinclude' fresh on every
	// single call (`capture drop `nw_included''; `gen `nw_included' =
	// (`current'==1)'' - see its own source) - looping it over MULTIPLE
	// networks (`nets', whenever this command is asked to combine more
	// than one network into a single edgelist, e.g. `nwsave's own
	// `nwtoedge _all, egovars(_nw_match_*) ...' call) means each
	// iteration WIPES the previous network's own flag, leaving
	// `_nwinclude' correctly marking only the LAST network in `nets'
	// by the time the loop below finishes - not "the network(s) just
	// synced" (plural) the surrounding code's own pre-existing comment
	// already claimed as this flag's contract. The egovars()/
	// altervars() lookup-table-building steps further below both
	// filter on this flag (`keep if `nw_included' == 1') to build a
	// per-node attribute table - with the un-accumulated flag, every
	// node belonging to any network OTHER than the last one in `nets'
	// silently vanishes from that table entirely, so egovars()/
	// altervars() (and this file's own `_nw_match_*' propagation,
	// nwsave.ado's multi-network round-trip mechanism) come back
	// entirely missing for that node's own rows - confirmed directly:
	// two two-mode networks saved together, `_nw_match_<first network>'
	// was completely missing for every row after a save/reload, `_nw_
	// match_<last network>' was correct. Fixed by accumulating a
	// UNION flag (`nw_included'_all, initialized 0, OR'd in after each
	// `_nwdatasync' call) across the whole loop, rather than reading
	// the last call's own overwritten `_nwinclude' directly - a true
	// "belongs to any network in `nets'" flag, matching the comment's
	// own already-stated (but previously unimplemented) intent.
	capture drop `nw_included'_all
	local __nwtoedge_haveall = 0
	foreach net in `nets' {
		_nwdatasync `net'
		if !`__nwtoedge_haveall' {
			gen `nw_included'_all = 0
			local __nwtoedge_haveall = 1
		}
		replace `nw_included'_all = 1 if `nw_included' == 1
	}
	capture drop `nw_included'
	rename `nw_included'_all `nw_included'
	
	// Deal with two-mode networks
	if "`is2mode'" == "true"  & "`ignore2mode'" == ""{
		local egovars "`nw_mode' `egovars'"
		local altervars "`nw_mode' `altervars'"
	}

	// Handle attributes of nodes
	//
	// BUGFIX: `fromfile'/`tofile' used to be built from every row of the
	// active dataset, not just the rows that are actually live nodes of
	// the network(s) just synced above. The shared dataset can carry
	// leftover rows for a node no longer in `net' - most commonly right
	// after nwdropnodes ..., generate() (which, by design, drops nodes
	// from the network object without touching unrelated Stata rows
	// unless attributes() is also given - see nwdropnodes.ado's own
	// header note). Those leftover rows never match any `_ego'/`_alter'
	// value get_edgelist() produced, so the merge m:n below (unmatched
	// "using" observations are appended as new rows by default) silently
	// added one phantom edgelist row per leftover node per egovars()/
	// altervars() call - all five of _ego/_alter/net/from_*/to_* missing
	// except the leftover node's own real attribute values. Confirmed
	// directly: 48-node network (50-node usair with 2 nodes dropped via
	// nwdropnodes ..., generate()), egovars(Lon Lat) altervars(Lon Lat)
	// produced 2,308 rows instead of the correct 2,304 (48x48), the 4
	// extra rows holding the two dropped nodes' own coordinates with
	// _ego/_alter/tie value all missing.
	//
	// `_nwinclude' (this program's own `nw_included' local) is exactly
	// the flag `_nwdatasync' just generated for this purpose - 1 for a
	// row that is a genuine current node of the network(s) just synced,
	// 0 for a leftover row from some other network sharing the same
	// dataset (_nwdatasync.ado's own header documents this convention).
	// Filtering on it here is a no-op whenever every row already is a
	// live node (the ordinary case), so this changes nothing for any
	// network that was never node-dropped.
	qui if "`egovars'" != "" {
		preserve
		keep if `nw_included' == 1
		tempfile fromfile
		keep `nw_nodename' `egovars'
		foreach var of varlist `egovars' {
			rename `var' `var'`ego'
		}
		save `fromfile'
		restore
	}

	qui if "`altervars'" != "" {
		preserve
		keep if `nw_included' == 1
		tempfile tofile
		keep `nw_nodename' `altervars'
		foreach var of varlist `altervars' {
			rename `var' `var'`alter'
		}
		save `tofile'
		restore
	}
	
	
	// Check if there is at least one directed network in the list
	qui foreach net in `nets' {
		_nwsyntax `net'
		if "`directed'" == "true" {
			local full = "full"
		}
	}

	local i = 0
	qui foreach net in `nets' {
		_nwsyntax `net'
		tempfile __nwedgelist`i'
		
		if "`upper'" != "" & "`directed'" == "true" {
			noi di "{txt}Warning! Network {res}`net'{txt} is directed. Option {res}upper{txt} surpressed." 
		}
		mata: __nwedgelist`i' = (`netobj'->get_edgelist((("`upper'" != "" | "`directed'" == "false") & "`full'" == "")))[,(1::5)]
		preserve
		drop _all
		tempvar include
		tempvar transp
		getmata (`ego' `alter' `net' `include' `transp') = __nwedgelist`i', force
		destring `include', replace force
		capture drop if `include' != 1
		capture drop `include'
		destring `net', replace force
		mata: mata drop __nwedgelist`i'
		save `__nwedgelist`i''
		restore
		local i = `i' + 1
	}
	
	local morethanone = `=`i' > 1'
	
	qui drop _all
	qui use `__nwedgelist0'

	qui forvalues j = 1/`=`i'-1' {
		merge m:n (`ego' `alter') using `__nwedgelist`j'', nogenerate
	}
	
	qui if trim("`egovars'") != "" {
		capture drop `nw_nodename'
		gen `nw_nodename' = `ego'
		merge m:n (`nw_nodename') using `fromfile', nogenerate 
	}
	qui if trim("`altervars'") != "" {
		capture drop `nw_nodename'
		gen `nw_nodename' = `alter'
		merge m:n (`nw_nodename') using `tofile', nogenerate 
	}
	qui capture drop `nw_nodename'
	sort `ego' `alter'
	qui if "`compress'" != "" {
		tempvar t
		gen `t' = 0
		foreach net in `nets' {
			replace `t' = `t' + abs(`net')
		}
		drop if `t' == 0
	}
	
	qui foreach net in `nets' {
		capture drop if `net' == `missing2'
	}

	if "`numeric'" != "" {
		if `morethanone' != 0 {
			// Was print-only (di "{err}...") with no `error' call, so
			// execution fell through into a plain node x node numeric grid
			// that no longer matched the multi-network merge already
			// performed above - the documented constraint was never
			// actually enforced. Package standard 198 (invalid syntax /
			// unsatisfied required-option combination, unw_defs.ado).
			di "{err}Programming option {bf:numeric} only allowed for one network."
			exit 198
		}
		drop `ego' `alter'
		
		mata: __nwedgelist = vec(J(`nodes',1,(1::`nodes'))), vec(J(1,`nodes',(1::`nodes'))')
		getmata (`ego' `alter') = __nwedgelist, force
		mata: mata drop __nwedgelist
	}

end	
