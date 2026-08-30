
capture program drop nwrename
program nwrename
	
	local renameCmd `0'
	
	preserve
	drop _all
	nw_syntax _all, max(9999)
	foreach onenet in `netname' {
		gen `onenet' = .
	}
	// BUGFIX: renaming to an already-existing network name used to
	// surface Stata's own raw built-in rename error (r110, phrased
	// entirely in terms of "variable ... already existing variable"),
	// confusing for a network-level operation - unlike the rest of this
	// group, which phrases collisions in terms of networks. The dummy
	// variables generated just above (one per currently-registered
	// network) are exactly what collides, so a captured rename attempt
	// plus a network-specific message on failure gives a clear error
	// without needing to separately re-parse Stata's own old/new rename
	// syntax (supports both "old new" and "(old1 old2) (new1 new2)"
	// forms) just to pre-check collisions by hand.
	capture noisily rename `renameCmd', r
	if _rc != 0 {
		local renamerc = _rc
		restore
		di "{err}Cannot rename: the target name already exists as a network. Specify a different name."
		error `renamerc'
	}
	local oldnames "`r(oldnames)'"
	local newnames "`r(newnames)'"
	restore
	local i = 1
	foreach onenet in `oldnames' {
		local newname : word `i' of `newnames'
		nw_name `onenet', newname(`newname')
		local i = `i' + 1
	}
end

