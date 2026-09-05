
capture program drop nwbridges
program nwbridges
	// A bare `distance' flag was declared here alongside `type(string)',
	// but never referenced anywhere in this file's body (confirmed via
	// grep) - `type(distance)' (one of the three real `type()' values,
	// see `_opts_oneof' below) already covers this, making the bare flag
	// a confusing, fully dead duplicate. Removed.
	syntax [anything(name=netname)] [, nwreplace name(string) type(string)]
	_nwsyntax `netname'
	local oldname `netname'
	local olddirected `netname'
	local generate "`name'"
	if "`type'" == "" {
		local type "global"
	}
	_opts_oneof "local global distance" "type" "`type'" 6556
	
	if "`generate'" == "" {
		local generate "_bridges"
	}

	capture _nwsyntax `generate', other(other)
	if _rc == 0 & "`nwreplace'" == "" {
		di "{err}Network {bf:`generate'} already exists; use {bf:nwreplace}"
		err 99
	}
	capture nwdrop `generate'
	nwduplicate `netname', name(`generate')

	_nwsyntax `generate'
	// PERFORMANCE FIX: type(global) only needs to know which ties are
	// bridges (does removing this one tie disconnect its endpoints?),
	// not the actual alternate-path distance calculate_distances_
	// without() computes for every single tie via its own dedicated
	// BFS - O(m*(V+E)) total, confirmed too slow to complete within
	// several minutes at n=10,000/50k edges during a benchmark run.
	// calculate_bridges_global() answers exactly the type(global)
	// question via a single O(V+E) DFS (Tarjan 1974) instead - but
	// only for UNDIRECTED networks; a directed graph's own analogous
	// question is a different, harder problem this fix does not
	// attempt (see that method's own header comment), so directed
	// input keeps using the original, unchanged computation. type(
	// local)/type(distance) both need real distance values (not just
	// a bridge/not-bridge boolean) and also keep the original path
	// unconditionally.
	if "`type'" == "global" & "`directed'" == "false" {
		mata: `netobj'->set_edge(`netobj'->calculate_bridges_global())
	}
	else {
		mata: `netobj'->set_edge(`netobj'->calculate_distances_without())
	}
	if "`type'" == "global" {
		nwreplace `generate' = (`generate' == -1)
		local type "global"
	}
	if "`type'" == "local"{
		nwreplace `generate' = (`generate' == -1 | `generate' > 2)
		local type "local"
	}
	if "`type'" == "distance" {
		local type "distance"
	}
	
	if "`olddirected'" == "false" {
		nwsym `generate', mode(min)
	}
	qui nwsummarize `generate'
	if "`directed'" == "true" {
		local bridges = `r(arcs)'
	}
	else {
		local bridges = `r(edges)'
	}
	mata: st_rclear()
	
	_nwsyntax `oldname'
	mata: st_global("r(name)", "`netname'")
	mata: st_global("r(directed)", "`directed'")
	mata: st_global("r(bridges)", "`bridges'")
	mata: st_global("r(bridges_type)", "`type'")
	di ""
	di "{hline 30}"
	di "{txt}    Network      : {res}`netname'"
	di "{txt}    Directed     : {res}`directed'"
	di "{txt}    Bridges      : {res}`r(bridges)'"
	di "{txt}    Type         : {res}`r(bridges_type)'"
	di "{hline 30}"
	
end



