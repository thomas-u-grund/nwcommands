
capture program drop nwsync
program def nwsync
	version 9
	syntax [anything(name=netname)],[ label fromstata]
	
	_nwsyntax `netname', max(1)
	if "`label'" != "" {
		_nwdatasync `netname'
	}
	
	mata: st_global("r(vars)", `netobj'->get_nodesvar_string())
	capture confirm variable `r(vars)'
	// BUGFIX: used to branch on `_rc' directly with no `else' clause -
	// on the (very common) path where a network has no Stata-variable
	// sync to do at all (never `nwload'ed), the failed `capture confirm
	// variable' above is completely expected/harmless, but its nonzero
	// `_rc' was left standing as this program's own return code with
	// nothing to reset it - any caller checking `_rc' right after
	// calling nwsync (nwsym does exactly this internally, and nwuse.ado
	// checks it one level further out) saw a spurious failure despite
	// nwsync having done its job correctly. Captured into a local
	// first so the branch no longer depends on `_rc''s own value, and
	// an explicit `exit 0' at the end marks genuine, full success -
	// safe because any real failure in `nwload'/`drop'/`set_edge' below
	// would already have interrupted execution before reaching it.
	local hasvars = (_rc == 0)
	if `hasvars' {
		if "`fromstata'" == "" {
			drop `r(vars)'
			nwload `netname'
		}
		else {
			mata: `netobj'->set_edge(st_data((1::`nodes'), "`r(vars)'"))
		}
	}
	// A bare, uncaptured successful command does NOT reset `_rc' back
	// to 0 in Stata (confirmed directly: a plain `summarize'/`confirm'/
	// `mata:' call leaves a prior nonzero `_rc' from an earlier failed
	// `capture' completely untouched) - only `capture' itself explicitly
	// sets `_rc' to its wrapped command's own result, success or not.
	// `exit 0' alone does not do this either (also confirmed directly)
	// - it is not a special "clear _rc" signal, just an ordinary
	// successful exit that leaves whatever `_rc' already was standing.
	// This harmless, always-succeeding `capture' is the actual fix.
	capture confirm number 1
end

