capture program drop nwpath
program nwpath
	version 9
	// `name(string)' removed - it was accepted by syntax but never
	// referenced anywhere in this file's body (a fully dead,
	// undocumented no-op; confirmed via grep). The real option for
	// naming this command's output network(s) is `generate()' - a stub
	// prefix, since one call can produce multiple path networks, so
	// `name()' could not simply have aliased it (a single fixed name
	// doesn't fit a multi-network stub the way it does for other
	// commands in this group).
	syntax [anything(name=netname)],  [nwreplace ego(string) alter(string) egoid(integer 0) alterid(integer 0) sym generate(string) nopaths alpha(string) BINary]
	
	if "`sym'" != "" & "`generate'" != "" {
		di "{err}Options {bf:sym} and {bf:generate()} cannot be combined."
		err 99
	}
	// BUGFIX: `egoid'/`alterid' are declared `integer 0' (a numeric
	// option with a default), so their own string form is never truly
	// empty - it reads "0" when not given, not "" - making
	// `"`egoid'" == ""'/`"`alterid'" == ""' always false regardless of
	// whether the caller passed the option. Both guards below were
	// therefore dead code: calling nwpath with neither ego() nor
	// egoid() (or neither alter() nor alterid()) never actually raised
	// this command's own clear message, it fell through to a much more
	// confusing downstream "Node  or  does not exist" (an empty ego/
	// alter name reaching nwnode). Fixed to compare the actual integer
	// value against its own documented "not given" sentinel (0) instead
	// of a string comparison that could never be true.
	if "`ego'" == "" & `egoid' == 0 {
		di "{err}Either options {bf:ego()} or {bf:egoid} needs to be specified"
		err 99
	}
	if "`alter'" == "" & `alterid' == 0 {
		di "{err}Either options {bf:ego()} or {bf:egoid} needs to be specified"
		err 99
	}
	_nwsyntax `netname', max(1)

	// Tie values: on a valued network the shortest path is the one of least cost, a step along a tie of
	// value w costing 1/w^alpha (alpha = 1 by default; alpha(-1) reads the values as lengths, as igraph does).
	// binary ignores the values (fewest steps).  alpha() is accepted on any network.
	if "`alpha'" != "" {
		capture confirm number `alpha'
		if _rc {
			di "{err}Option {bf:alpha()} must be a number."
			error 198
		}
	}
	if "`binary'" != "" & "`alpha'" != "" {
		di "{err}Options {bf:binary} and {bf:alpha()} cannot be combined."
		error 198
	}
	local __wtd = ("`alpha'" != "" | ("`valued'" == "true" & "`binary'" == ""))
	local __alpha 1
	if "`alpha'" != "" local __alpha = real("`alpha'")
	
	if `egoid' != 0 {
		qui capture nwnode `netname', egoid(`egoid')
		if _rc != 0 {
			noi di "{err}Egoid {bf:`egoid'} out of bounds"
			err 99
		}
		local ego "`r(nodename)'"
	}
	if `alterid' != 0 {
		qui capture nwnode `netname', egoid(`alterid') 
		if _rc != 0 {
			noi di "{err}Alterid {bf:`alterid'} out of bounds"
			err 99
		}
		local alter "`r(nodename)'"
	}
	
	if "`directed'" == "false" {
		local undirected_sign "<"
	}
	
	set more off
	if "`length'" == "" {
		local length 0
	}
	
	// check if ego or alter does not exit
	capture qui nwvalue `netname', ego("`ego'") alter("`alter'")
	if _rc != 0 {
		di "{err}Node {bf:`ego'} or {bf:`alter'} does not exist in network {it:`netname'}; check spelling"
		error 99
	}
	local egoid `r(ego_id)'
	local alterid `r(alter_id)'
	local netname_orig `netname'
	
	tempname _path _sym
	if "`sym'" != "" {
		nwduplicate `netname', name(`_sym')
		nwsym `_sym'
		_nwsyntax `_sym'
		local symtext " (symmetrized)"
		local undirected_sign "<"
	}
	if `__wtd' {
		mata: `_path' = `netobj'->get_path_weighted(`egoid', `alterid', `__alpha')
	}
	else {
		mata: `_path' = `netobj'->get_path(`egoid', `alterid', `length')
	}
	mata: st_numscalar("r(paths)", rows(`_path'))
	mata: st_numscalar("r(path_length)", rows(`_path') == 0 ? -1 : sum(`_path'[1,.] :> 0) - 1)
	mata: st_numscalar("r(ego)", `egoid')
	mata: st_numscalar("r(alter)", `alterid')
	// r(path_shortest): this command only ever finds shortest paths -
	// length() is documented (and was previously documented as though
	// implemented) but was never actually a real syntax option, so
	// there is currently no way to request a longer, non-shortest path.
	// r(path_shortest) is therefore always identical to r(path_length)
	// today; kept as its own explicit return (rather than removed from
	// the documented interface) so it is already in place, unchanged,
	// on the day a real length()-selection option is eventually added.
	mata: st_numscalar("r(path_shortest)", rows(`_path') == 0 ? -1 : sum(`_path'[1,.] :> 0) - 1)
	if `__wtd' {
		mata: st_numscalar("r(path_cost)", rows(`_path') == 0 ? . : nw_pathcost(`netobj', `_path'[1,.], `__alpha'))
	}
	if `r(paths)' > 0 {
		mata: st_matrix("r(paths_matrix)", `_path')
	}


	di ""
	di "{hline 40}"
	di "{txt}  Network: {res}`netname_orig'`symtext'"
	di "{hline 40}"
	di "{txt}    Ego                  : {res}`ego'"
	di "{txt}    Alter                : {res}`alter'"
	if `r(path_length)'>=0 {
		if `__wtd' {
			di "{txt}    Cost (1/value^alpha, alpha = `__alpha'): {res}`=strtrim(string(r(path_cost), "%12.0g"))'"
			di "{txt}    Steps                : {res}`r(path_length)'"
		}
		else {
			di "{txt}    Shortest path length : {res}`r(path_length)'"
		}
	}
	else {
		di "{txt}    Shortest path length : {res}not connected"
	}
	di "{hline 40}"
	
	if "`nopaths'" == "" forvalues i = 1/`r(paths)' {
		local p "{txt}	Path `i': {res}`ego'"
		mata: st_local("__plen", strofreal(sum(`_path'[`i',.] :> 0) - 1))
		forvalues j = 2/`=`__plen'+1' {
			mata: st_local("next", `netobj'->get_nodenames()[`_path'[`i',`j']])
			local p "`p' `undirected_sign'=> `next'"
		}
		di "`p'"
	}

	
	if "`generate'" != "" {
		forvalues i = 1/`r(paths)' {
			capture _nwsyntax `generate'_`i', other("other")
			if _rc == 0 & "`nwreplace'" == "" {
				capture nwdrop `_sym'
				di "{pstd} {err}Network {bf:`generate'_`i'} already exists; use {bf:nwreplace} or specify another stub {bf:generate()}{p_end}"
				error 99
			}
			capture nwdrop `generate'_`i'
			nwduplicate `netname', name(`generate'_`i')
			_nwsyntax 
			mata: nw_path_net(`netobj', `_path', `i')
		}
	}
	
	tempname rstore
	_return hold `rstore'
	capture nwdrop `_sym'
	_return restore `rstore'
	capture mata: mata drop `_path'
end

capture mata: mata drop makenet()
capture mata: mata drop nw_pathcost()

mata:
real scalar nw_pathcost(pointer(class nw_def scalar) scalar p, real rowvector path, real scalar alpha)
{
	real scalar i, c, k
	k = sum(path :> 0)
	c = 0
	for (i = 1; i < k; i++) c = c + p->edge_weight(path[i], path[i+1])^(-alpha)
	return(c)
}

real matrix makenet(real matrix path, real scalar id, real scalar nodes){
	real matrix net
	real scalar i, ego, alter
	net = J(nodes, nodes, 0)
	for (i = 1; i < cols(path); i++){
		ego = path[id, i]
		alter = path[id, (i + 1)]
		net[ego, alter] = 1
	}
	return(net)
}
end
