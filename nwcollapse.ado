
capture program drop nwcollapse
program nwcollapse
	syntax [anything] [, generate(string) by(varname) *]
	
	preserve
	gettoken stat netname : anything, parse(")")
	if "`netname'" == "" {
		local netname "`stat'"
		local stat = "" 
	}
	else {
		local netname = substr("`netname'", 3,.)
		local stat = substr("`stat'",2,.)
	}

	if "`stat'" == "" {
		local stat = "max"
	}
	_nwsyntax `netname'
	// BUGFIX: collapsing a two-mode network used to silently produce a
	// result reported as an ordinary one-mode network (mode2 flipped
	// from true to false, with no error, warning, or documented
	// behavior) - the row-grouping logic below has no notion of mode at
	// all, so it freely collapsed mode-1 and mode-2 nodes together.
	// Rejected outright with a clear error instead, matching how
	// commands elsewhere in the package that are not meaningful for
	// two-mode networks refuse them explicitly (`errTwoModeUnsupported',
	// 6088, unw_defs.ado - declared package-wide but, until now, never
	// actually used anywhere).
	_nw2guard `netname', cmd(nwcollapse)
	local original `netname'

	// Stata's collapse is applied to the list of ALL dyads (one row per ordered pair of nodes, the zero cells
	// included, since a group's mean or median depends on them); nwtoedge refuses more than 50,000,000 rows.
	// Say so here, before the network is copied.
	if `nodes' * `nodes' > 5e7 {
		di "{err}nwcollapse applies Stata's collapse to every pair of nodes (`=`nodes'*`nodes'' rows for the `nodes' nodes of {bf:`netname'}, zero cells included) and is refused above 50,000,000 rows (7,071 nodes)."
		di "{err}Collapse a part of the network (nwsubset, nwkeepnodes) or count the ties between the groups from the edge list ({bf:nwtoedge, compress}) with Stata's {bf:collapse}."
		exit 484
	}

	if "`name'" == "" {
		local name "`netname'_collapsed"
	}
	
	// a run that stopped half way (e.g. nwtoedge refusing a huge network) leaves its temporary copy behind
	capture nwdrop _temp_`original'
	nwduplicate `original', name(_temp_`original')
	_nwdatasync _temp_`original'
	_nwsyntax _temp_`original'
	local __srcvalued "`valued'"
	// the collapsed network keeps the directedness of the original (nwfromedge
	// would otherwise guess it from whether the collapsed list is symmetric)
	local __dirflag "forcedirected"
	if "`directed'" == "false" local __dirflag "undirected"
	tempvar by_group by_dummy
	gen `by_dummy' = 1
	qui replace `by_dummy' = . if _n > `nodes'
	tempvar running
	gen `running' = _n
	bys `by': egen `by_group' = total(`by_dummy')
	sort `running'
	qui replace _nwnode = "new_" + _nwnode if `by_group' > 1
	nwname _temp_`original', newlabsfromvar(_nwnode)
	
	nwtoedge _temp_`original', egovars(`by') altervars(`by') ego(_fromid) alter(_toid)
	// Isolate preservation (#5) is for a genuine round trip back to the
	// SAME node set nwtoedge started from - wrong here, where the whole
	// point is collapsing several original nodes into fewer new ones.
	// Left attached, nwfromedge below would "restore" every original
	// node the collapse() step deliberately merged away as if they were
	// lost isolates. Clear it so nwfromedge treats this edgelist as it
	// would any other with no such history.
	char _dta[nwtoedge_nodes] ""

	tempvar _newfrom _newto

	keep _fromid _toid _temp_`original' `by'_fromid `by'_toid
	collapse (`stat') _temp_`original' (firstnm) _fromid _toid , by(`by'_fromid `by'_toid) `options'
	
	if "`generate'" != "" {
		qui nwfromedge _fromid _toid _temp_`original', name(`generate') `__dirflag'
	}
	else {
		nwdrop `original'
		qui nwfromedge _fromid _toid _temp_`original', name(`original') `__dirflag'
	}
	// the collapsed network keeps the Valued flag of the original; it becomes valued if the collapse creates values
	// other than 0 and 1 (for example (sum) of a binary network)
	local __tgt "`original'"
	if "`generate'" != "" local __tgt "`generate'"
	_nwsyntax `__tgt', max(1)
	mata: `netobj'->set_valued(("`__srcvalued'" == "true") | `netobj'->check_valued())
	restore
end

