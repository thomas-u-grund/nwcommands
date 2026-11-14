
capture program drop nwtoedge
program nwtoedge
	version 9
	syntax [anything(name=netname)][, isolates0 compress upper egovars(varlist) altervars(varlist) numeric ///
	ego(name) alter(name) full ignore2mode comparevars(varlist) comparemode(string) ALLpairs time AGGregate]

	unw_defs
	_nwsyntax `netname', max(9999)
	local nets `netname'
	// numeric needs exactly one network: refused before anything is changed
	if "`numeric'" != "" & (`: word count `netname'' > 1 | "`comparevars'" != "") {
		di "{err}Programming option {bf:numeric} only allowed for one network."
		exit 198
	}

	// Temporal networks. time: one row per event (event network), per observation of a tie (snapshot network) or per
	// interval (interval network), with the time in _time (_start and _end for intervals) and, for a valued network, the
	// value in _value; the data in memory are replaced like the list of ties below. Without time the list holds each tie
	// once, aggregated over all times: a note says so, and aggregate states the aggregation and leaves the note out.
	if "`time'" != "" {
		if "`aggregate'" != "" {
			di "{err}options {bf:time} and {bf:aggregate} cannot be combined"
			exit 198
		}
		if `: word count `netname'' != 1 | "`numeric'`comparevars'`egovars'`altervars'`isolates0'`compress'`upper'`full'`ignore2mode'`allpairs'" != "" {
			di "{err}{p 0 0 2}option {bf:time} needs exactly one network and cannot be combined with other options except {bf:ego()} and {bf:alter()}.{p_end}"
			exit 198
		}
		if "`istemporal'" != "true" {
			di "{err}{p 0 0 2}Network {bf:`netname'} is not temporal; option {bf:time} needs a network declared with {help nwset:nwset}'s {bf:time()}, {bf:interval()} or {bf:eventtime()}.{p_end}"
			exit 198
		}
		if "`is2mode'" == "true" {
			di "{err}{p 0 0 2}option {bf:time} is not available for a two-mode network.{p_end}"
			exit 198
		}
		local __tev = ("`temporaltype'" == "event")
		local __tvalued = ("`valued'" == "true")
		local __tegoname = cond("`ego'" == "", "`nw_ego'", "`ego'")
		local __talname = cond("`alter'" == "", "`nw_alter'", "`alter'")
		if "`temporaltype'" == "interval" local __tt "t1(_start) t2(_end)"
		else local __tt "t1(_time)"
		if `__tev' & `__tvalued' local __tt "`__tt' value(_value)"
		_nwtemporal pack `netname', ego(`__tegoname') alter(`__talname') `__tt' half
		_nwtemporal drop
		qui compress
		exit
	}
	if "`aggregate'" == "" {
		local __nwte_tnets ""
		foreach __nwte_n of local netname {
			qui nwname `__nwte_n'
			if "`r(temporal)'" == "true" local __nwte_tnets "`__nwte_tnets' `__nwte_n'"
		}
		if "`__nwte_tnets'" != "" {
			di "{txt}{p 0 0 2}(note: `__nwte_tnets' is temporal. The list holds each tie once, aggregated over all times; specify {bf:time} to list the times of the ties, or {bf:aggregate} to state the aggregation and leave this note out.){p_end}"
		}
	}

	// Isolate preservation (#5): an edgelist has no way to represent a
	// zero-tie node, so a plain nwtoedge/nwfromedge round trip silently
	// drops isolates - confirmed directly on real data (Glasgow
	// friendship network, 50 nodes -> 47 after a round trip). Attach the
	// source network's own full node list as a dataset characteristic
	// (get_nodenames_string()'s own ";"-delimited format) so
	// nwfromedge/nw2fromedge can add any missing node back automatically,
	// with no option to remember at either end. Scoped to a single
	// source network - ambiguous which network's own isolates would
	// apply once nwtoedge is combining more than one (see comparevars()
	// above, which is already single-network-only for the same reason).
	local __iso_nwcount : word count `netname'
	// a two-mode network is written as its ties by default (see nw2toedge); allpairs gives the row for every pair
	if "`is2mode'" == "true" & "`allpairs'" == "" & `__iso_nwcount' == 1 {
		local compress compress
	}
	local __iso_srclabels ""
	if `__iso_nwcount' == 1 {
		_nwsyntax `netname'
		mata: st_local("__iso_srclabels", `netobj'->get_isolate_source_string())
	}

	// A single two-mode network with compress: list only the ties between
	// the two modes, like nw2toedge does. The generic code below would
	// list every dyad inside each mode as well (a row with a missing
	// value each), which for a large two-mode network is gigabytes
	// (nwsave of a 5,092 x 455 network came to 2.6 GB) and made nwexport
	// write those rows too.
	if "`compress'" != "" & `__iso_nwcount' == 1 & "`is2mode'" == "true" & "`numeric'" == "" & "`comparevars'" == "" {
		local __t2opts ""
		if "`upper'" != "" local __t2opts "`__t2opts' upper"
		if "`full'" != "" local __t2opts "`__t2opts' full"
		if "`isolates0'" != "" local __t2opts "`__t2opts' isolates0"
		if "`egovars'" != "" local __t2opts "`__t2opts' egovars(`egovars')"
		if "`altervars'" != "" local __t2opts "`__t2opts' altervars(`altervars')"
		if "`ego'" != "" local __t2opts "`__t2opts' ego(`ego')"
		if "`alter'" != "" local __t2opts "`__t2opts' alter(`alter')"
		nw2toedge `netname', compress `__t2opts'
		if "`ignore2mode'" != "" {
			local __t2e = cond("`ego'" == "", "`nw_ego'", "`ego'")
			local __t2a = cond("`alter'" == "", "`nw_alter'", "`alter'")
			capture drop `nw_mode'`__t2e'
			capture drop `nw_mode'`__t2a'
		}
		if "`__iso_srclabels'" != "" {
			char _dta[nwtoedge_nodes] "`__iso_srclabels'"
		}
		exit
	}

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
		qui replace `nw_included'_all = 1 if `nw_included' == 1
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
		// compress with ONE network: list only the stored ties (O(ties));
		// everything else lists all N x N cells, zeros included, which is
		// what the uncompressed list means (and what several networks
		// merged on one ego/alter pair need).
		local __sparseok 0
		// (the sparse listing does not handle a network of one node)
		if "`compress'" != "" & `: word count `nets'' == 1 & `nodes' > 1 {
			mata: st_local("__sparseok", strofreal(`netobj'->edgelist_sparse_ok()))
		}
		if `__sparseok' {
			mata: __nwedgelist`i' = (`netobj'->get_edgelist_sparse((("`upper'" != "" | "`directed'" == "false") & "`full'" == "")))[,(1::5)]
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
		}
		else {
			// every dyad: the ego, alter and value columns go straight into
			// variables (no string matrix and no destring)
			preserve
			drop _all
			mata: `netobj'->edgelist_full_to_vars((("`upper'" != "" | "`directed'" == "false") & "`full'" == ""), "`ego'", "`alter'", "`net'")
			compress `net'
			save `__nwedgelist`i''
			restore
		}
		local i = `i' + 1
	}
	
	local morethanone = `=`i' > 1'
	
	qui drop _all
	qui use `__nwedgelist0'

	qui forvalues j = 1/`=`i'-1' {
		merge m:n (`ego' `alter') using `__nwedgelist`j'', nogenerate
	}

	// two-mode network: the mode-1 node of a tie between the modes is always
	// _ego and the mode-2 node _alter (nw2fromedge _ego _alter rebuilds it)
	if "`is2mode'" == "true" & "`ignore2mode'" == "" {
		local __tw_first : word 1 of `nets'
		_nwsyntax `__tw_first'
		mata: nwtoedge_mode1ego("`ego'", "`alter'", `netobj'->get_nodenames(), `netobj'->get_modes())
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
		// node labels -> node numbers (position of the node in the network),
		// row by row, whatever rows the listing kept
		_nwsyntax `netname'
		tempvar __nte __nta
		mata: nwtoedge_numid("`ego'", "`alter'", "`__nte'", "`__nta'", `netobj'->get_nodenames())
		drop `ego' `alter'
		rename `__nte' `ego'
		rename `__nta' `alter'
		order `ego' `alter'
	}

	// See the isolate-preservation note near the top of this file (#5).
	// `numeric' replaces ego/alter with generic 1..N indices, so real
	// node labels are meaningless here - skip attaching the char in that
	// case, matching how `numeric' already disables the multi-network
	// path above.
	if `__iso_nwcount' == 1 & "`numeric'" == "" & "`__iso_srclabels'" != "" {
		char _dta[nwtoedge_nodes] "`__iso_srclabels'"
	}

end

capture mata: mata drop nwtoedge_mode1ego()
mata:
void nwtoedge_mode1ego(string scalar ev, string scalar av, string rowvector nm, string rowvector md)
{
	transmorphic A
	string colvector e, a
	real colvector sw
	real scalar i
	string scalar ie, ia

	A = asarray_create()
	asarray_notfound(A, "")
	for (i = 1; i <= min((cols(nm), cols(md))); i++) asarray(A, nm[i], md[i])
	e = st_sdata(., ev)
	a = st_sdata(., av)
	sw = J(rows(e), 1, 0)
	for (i = 1; i <= rows(e); i++) {
		ie = asarray(A, e[i])
		ia = asarray(A, a[i])
		sw[i] = (ie == "2" & ia == "1")
	}
	if (!any(sw)) return
	sw = selectindex(sw)
	// both id variables get the same width, so that no label is cut
	if (st_vartype(ev) != st_vartype(av) & st_vartype(ev) != "strL" & st_vartype(av) != "strL") {
		stata("quietly recast str" + strofreal(max((strtoreal(substr(st_vartype(ev), 4, .)), strtoreal(substr(st_vartype(av), 4, .))))) + " " + ev + " " + av)
	}
	st_sstore(sw, ev, a[sw])
	st_sstore(sw, av, e[sw])
}
end

capture mata: mata drop nwtoedge_numid()
mata:
void nwtoedge_numid(string scalar ev, string scalar av, string scalar en, string scalar an, string rowvector nm)
{
	transmorphic A
	string colvector e, a
	real colvector ie, ia
	real scalar i

	A = asarray_create()
	asarray_notfound(A, .)
	for (i = 1; i <= cols(nm); i++) asarray(A, nm[i], i)
	e = st_sdata(., ev)
	a = st_sdata(., av)
	ie = J(rows(e), 1, .)
	ia = J(rows(e), 1, .)
	for (i = 1; i <= rows(e); i++) {
		ie[i] = asarray(A, e[i])
		ia[i] = asarray(A, a[i])
	}
	(void) st_addvar("long", (en, an))
	st_store(., (en, an), (ie, ia))
}
end
