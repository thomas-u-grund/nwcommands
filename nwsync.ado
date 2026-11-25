
capture program drop nwsync
program def nwsync
	version 9
	syntax [anything(name=netname)],[ label fromstata]
	
	_nwsyntax `netname', max(1)
	if "`label'" != "" {
		_nwdatasync `netname'
	}
	
	// The node variables are looked up in Mata, never through one macro:
	// a big network's node-variable list (one name per node) is far longer
	// than Stata's macro limit (r(920)), and cannot all exist as dataset
	// variables anyway.
	// to nwsync, variables are the network's when nwload made them (characteristic [nwload]). Others that have the
	// names of the nodes (the user's own, e.g. those of nwset varlist) are never dropped or overwritten.
	mata: st_local("hasvars", strofreal(cols(`netobj'->get_nodesvar()) > 0 ? all(_st_varindex(`netobj'->get_nodesvar()) :!= .) : 0))
	local __nws_own 0
	if `hasvars' {
		mata: st_global("r(vars)", `netobj'->get_nodesvar_string())
		local __nws_vars "`r(vars)'"
		if "`fromstata'" == "" {
			foreach __nws_v of local __nws_vars {
				local __nws_mark : char `__nws_v'[nwload]
				if "`__nws_mark'" == "" local ++__nws_own
			}
		}
	}
	if `hasvars' {
		if "`fromstata'" == "" {
			if `__nws_own' == 0 nwload `netname'
			else di "{txt}{p 0 0 2}(note: variables with the node names of {bf:`netname'} were not made by {bf:nwload}; they are left as they are. {bf:nwload `netname', overwrite} replaces them){p_end}"
		}
		else {
			mata: `netobj'->set_edge(st_data((1::`nodes'), "`__nws_vars'"))
			if "`istemporal'" == "true" {
				di "{txt}{p 0 0 2}(warning: network {bf:`netname'} is temporal; {bf:fromstata} changes the aggregated ties only, the times (events, snapshots, intervals) stay as they were and may no longer match the ties.){p_end}"
			}
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

