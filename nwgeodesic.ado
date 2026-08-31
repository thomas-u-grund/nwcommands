capture program drop nwgeodesic
program nwgeodesic
	version 9
	syntax [anything(name=netname)], [ nwreplace force noreplace name(string) alpha(real 0) xvars unconnected(string) sym symopt(string) generate(string)]

	capture
	unw_defs
	nw_syntax `netname'
	local origname "`netname'"
	
	if "`name'" == "" {
		local name "`nwgen_geodesic'"
	}
	
	tempname symnet
	local symmetrized "false"

	nw_syntax `netname', max(1)

	local eccvar "`generate'"
	if "`eccvar'" == "" {
		local eccvar "_eccentricity"
	}
	// Deliberately reuses nwreplace (not a separate replace option): this
	// syntax line already declares a dead, unused `noreplace' option, and
	// Stata's syntax parser silently fails to populate a `replace' local
	// when both `replace' and `noreplace' are declared together - verified
	// directly rather than assumed. Piggybacking on the existing, already-
	// working nwreplace avoids the collision entirely.
	// BUGFIX: this guard used to run unconditionally, even when `xvars'
	// was never requested - but `eccvar' is only actually written
	// further down, inside the `if "`xvars'" != ""' block. A call with
	// no xvars at all (or even a genuinely unrelated call, e.g. a
	// second nwgeodesic ... name(other) with no xvars) failed this
	// check purely because SOME earlier call had once left `eccvar'
	// (default "_eccentricity") lying around in the dataset, despite
	// this call never touching it. nwreach.ado wraps its own internal
	// nwgeodesic call in `qui', so this message never even reached the
	// user - just a bare, uninformative r(99).
	if "`xvars'" != "" {
		capture confirm variable `eccvar'
		if _rc == 0 & "`nwreplace'" == "" {
			di "{err}Variable {bf:`eccvar'} already exists; specify {bf:nwreplace}"
			err 99
		}
	}

	if "`sym'" != "" {
		di "{txt}Geodesics calculated on the symmetrized network."
		// `noreplace' dropped from this call: nwsym.ado's harmonisation
		// pass removed that option (see its own header comment) in favor
		// of a plain `replace', which cannot be combined with generate()
		// - so it would now error here. It was already redundant with
		// generate() (already given on this same call) determining the
		// in-place-vs-copy outcome on its own.
		nwsym `netname', generate(`symnet') `symopt'
		nw_syntax `symnet', max(1)
		local symmetrized "true"
	}
	capture nw_syntax `name', other(_check)
	local name_exists = (_rc == 0)
	if `name_exists' & "`nwreplace'" == "" {
		di "{pstd} {err}Network {bf:`name'} already exists; use {bf:nwreplace} or specify another {it:newnetname} with {bf:name()}{p_end}"
		error 99
	}
	// BUGFIX: was an unconditional `capture nwdrop `name'' - in the
	// ordinary case (no pre-existing network under this name), this
	// drop failed every time and left a stale, leaked `_rc' - the same
	// trailing-capture class fixed just below and in nwshared.ado this
	// same pass. `name_exists' above already knows whether there is
	// anything to drop.
	if `name_exists' {
		capture nwdrop `name'
	}
	nwduplicate `netname', name(`name')
	nw_syntax `name'
	
	if ("`valued'" == "false" & `alpha' != 1 ){
		di "{txt}Network is unvalued; {bf:alpha = `alpha'} is ignored."
		local alpha = 1
	}
	
	if (`alpha' == 0) {
		mata: `netobj'->set_edge(`netobj'->calculate_distances(`alpha', "brute"))
	}
	else if (`nodes' > 100 & "`force'" == ""){
		di "{txt}Calculated on unvalued network because network size exceeds 100."
		di "Use option {bf:force} to calculate distance on valued network nevertheless." 
		mata: `netobj'->set_edge(`netobj'->calculate_distances(`alpha', "brute"))	
	}
	else {
		mata: `netobj'->set_edge(`netobj'->calculate_distances(`alpha', "dijkstra"))	
	}
	
	// Get number of unconnected links
	mata: st_numscalar("r(unconnected)", sum((*`netobj'->get_matrix()):==.) - sum(diagonal(*`netobj'->get_matrix()):==.))
	
	// Deal with non-existing paths
	if "`unconnected'" != "" {
		mata: d = diagonal(*`netobj'->get_matrix())
		if "`unconnected'" == "max" {
			mata: st_local("unconnected", strofreal(max(*`netobj'->get_matrix())+1))
			mata: _editvalue((*`netobj'->get_matrix()),., `unconnected')
		}
		capture confirm number `unconnected'
		if _rc == 0 {
			mata: _editvalue((*`netobj'->get_matrix()),.,`unconnected')
		}
		mata: _diag((*`netobj'->get_matrix()), d)
		mata: mata drop d
	}

	mata: st_numscalar("r(nodes)", `nodes')
	mata: st_numscalar("r(numpaths)", `nodes' * (`nodes' - 1))

	// Get number of paths in distance network
	if "`directed'" == "false" {
		mata: st_numscalar("r(numpaths)", (`r(numpaths)' / 2))
	}
	
	// Get average shortest path length
	tempname s
	mata: _sum = sum(*`netobj'->get_matrix())

	mata: st_numscalar("r(avgpath)", (_sum / (`r(numpaths)')))
	if ("`directed'" == "false"){
		mata: st_numscalar("r(avgpath)", (_sum / (`r(numpaths)' * 2)))
		mata: st_numscalar("r(unconnected)",(`r(unconnected)' / 2))
	}		
	mata: mata drop _sum
	
	// Get rest
	mata: st_global("r(netname)","`origname'")
	mata: st_global("r(geodesic)","`name'")
	mata: st_global("r(symmetrized)", "`symmetrized'")
	mata: st_numscalar("r(diameter)", max(*`netobj'->get_matrix()))
	mata: st_numscalar("r(alpha)", `alpha')

	// Per-node eccentricity (max distance from a node to any other node) and
	// network radius (min eccentricity). Missing propagates through max()
	// exactly like it already does for r(diameter) above: a node that
	// cannot reach every other node has undefined (missing) eccentricity
	// unless unconnected() was specified.
	tempname __nw_ecc
	mata: `__nw_ecc' = rowmax(*`netobj'->get_matrix())
	mata: st_numscalar("r(radius)", min(`__nw_ecc'))
	if "`xvars'" != "" {
		qui capture drop `eccvar'
		qui gen `eccvar' = .
		mata: st_store((1::`nodes'), "`eccvar'", `__nw_ecc')
	}
	mata: mata drop `__nw_ecc'

	// Adjust for unconnected networks
	if `r(unconnected)' != 0 & "`unconnected'" == "" {
		mata: st_numscalar("r(avgpath)", -1)
		mata: st_numscalar("r(diameter)",-1)
		mata: st_numscalar("r(radius)",-1)
	}

	di "{hline 40}"
	di "{txt}  Network name: {res}`r(netname)'"
	di "{txt}  Network of shortest paths: {res}`r(geodesic)'"
	di "{hline 40}"
	di "{txt}    Nodes: {res}`r(nodes)'"
	
	if "`directed'" == "true" {
		di "{txt}    Symmetrized : {res}`r(symmetrized)'"
	}
	else {
		di "{txt}    Symmetrized : {res}(already undirected)"
	}
	if "`valued'" == "true" {
		di "{txt}    ALpha : {res}`=round(`r(alpha)',0.001)'"
	}
	di "    {hline 36}"
	di "{txt}    Paths: {res}`r(numpaths)'"
	di "{txt}    Unconnected paths: {res} `r(unconnected)'"
	
	if "`unconnected'" != "" {
		di "{txt}    Unconnected paths replaced with: {res} `unconnected'"
	}
	
	if `r(unconnected)' == 0 | "`unconnected'" != "" {
		di "{txt}    Average shortest path length: {res} `=round(`r(avgpath)',0.001)'"
		di "{txt}    Diameter: {res} `=round(`r(diameter)',0.001)'"
		di "{txt}    Radius: {res} `=round(`r(radius)',0.001)'"
	}
	else {
		di "{txt}    Average shortest path length: {res} (not defined)"
		di "{txt}    Diameter: {res} (not defined)"
		di "{txt}    Radius: {res} (not defined)"
	}

	capture _return drop _geo
	_return hold _geo
	// BUGFIX: was an unconditional `capture nwdrop `symnet'' - `symnet'
	// is only ever actually created as a real network when `sym' was
	// given (see above); otherwise this drop failed every time (nothing
	// to drop), and whenever `xvars' was ALSO not given (nothing else
	// afterward to touch `_rc'), the swallowed `capture' failure became
	// this command's own final, leaked `_rc' on an otherwise entirely
	// successful call - the same trailing-capture leak class fixed in
	// nwshared.ado this same pass. Only drop it when it was genuinely
	// created.
	if "`symmetrized'" != "" {
		capture nwdrop `symnet'
	}


	if "`xvars'" != "" {
		nwload `name'
	}
	// The two conditional-capture fixes above close the two known
	// stale-`_rc'-leak sources, but `capture _return drop _geo' further
	// above (an expected no-op the very first time this runs in a
	// session, since nothing was previously held under "_geo") is a
	// third, harder-to-guard one - and `_return hold'/`_return restore'
	// (both unconditional, including the one on the very next line) do
	// NOT refresh `_rc' themselves (same "quietly-prefixed/inherently
	// silent commands don't touch _rc" class documented in
	// nwbrokerage.ado's own header comment). Resetting explicitly here,
	// on a variable guaranteed to exist by this point, forces a clean,
	// deterministic `_rc==0' regardless of any upstream harmless
	// capture-swallowed failure - the same idiom nwaltergen.ado/
	// nwbrokerage.ado already use for the identical situation.
	capture confirm variable `nw_nodename', exact
	_return restore _geo
end

/*
capture mata mata drop getgeodesic()


mata:
void getgeodesic(pointer (class nw_def scalar) scalar nw)
{
	if (min(*nw->get_distance()) >= 0 ) { 
		st_numscalar("r(L)", sum(nw->get_distance())/(rows(*nw->get_distance())*rows(*nw->get_distance()) - rows(*nw->get_distance()))) 
	}
	else {
		st_numscalar("r(L)", -1) 
	}
}
end*/
