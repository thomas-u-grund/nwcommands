
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
	nw_syntax `netname'
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
	if "`is2mode'" == "true" {
		unw_defs
		di "{err}Network {bf:`netname'} is two-mode; {bf:nwcollapse} does not support collapsing two-mode networks."
		error `errTwoModeUnsupported'
	}
	local original `netname'

	if "`name'" == "" {
		local name "`netname'_collapsed"
	}
	
	nwduplicate `original', name(_temp_`original')
	_nwdatasync _temp_`original'
	nw_syntax _temp_`original'
	tempvar by_group by_dummy
	gen `by_dummy' = 1
	replace `by_dummy' = . if _n > `nodes'
	tempvar running
	gen `running' = _n
	bys `by': egen `by_group' = total(`by_dummy')
	sort `running'
	replace _nwnode = "new_" + _nwnode if `by_group' > 1
	nwname _temp_`original', newlabsfromvar(_nwnode)
	
	nwtoedge _temp_`original', egovars(`by') altervars(`by') ego(_fromid) alter(_toid)
	
	tempvar _newfrom _newto

	keep _fromid _toid _temp_`original' `by'_fromid `by'_toid
	collapse (`stat') _temp_`original' (firstnm) _fromid _toid , by(`by'_fromid `by'_toid) `options'
	
	if "`generate'" != "" {
		qui nwfromedge _fromid _toid _temp_`original', name(`generate')
	}
	else {
		nwdrop `original'
		qui nwfromedge _fromid _toid _temp_`original', name(`original')
	}
	restore
end

