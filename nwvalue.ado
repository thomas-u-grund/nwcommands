
capture program drop nwvalue
program nwvalue
	syntax [anything(name=netname)] [,egoid(integer 0) alterid(integer 0) ego(string) alter(string)]

	// support netname[egoid,alterid] shorthand, equivalent to egoid()/alterid()
	local bracketpos = strpos("`netname'","[")
	if (`bracketpos' != 0) {
		local closepos = strpos("`netname'","]")
		local sep = strpos("`netname'",",")
		local egoid = real(trim(substr("`netname'", `bracketpos' + 1, `sep' - `bracketpos' - 1)))
		local alterid = real(trim(substr("`netname'", `sep' + 1, `closepos' - `sep' - 1)))
		local netname = substr("`netname'", 1, `bracketpos' - 1)
	}

	unw_defs
	mata: st_rclear()

	// BUGFIX (error-code coherence, found alongside the out-of-range fix
	// below): this and the two "does not exist" checks just below used
	// to all raise the bare literal `error 3000' - Stata's OWN reserved
	// code for "Mata compile-time error", so every one of these prints
	// Stata's own generic canned text for that ALONGSIDE this command's
	// real message, confusingly implying an internal crash rather than
	// a deliberate validation guard (the exact anti-pattern nwsimmelian.ado
	// already identified and fixed for its own unrelated "already exists"
	// case - see that file's own comment). This specific guard ("neither
	// ego()/alter() nor egoid()/alterid() given") is a required-option-
	// combination failure, which unw_defs.ado's own registry documents
	// Stata's reserved 198 as the package-wide convention for - not a
	// node-lookup failure - so it gets 198, while the two "node does not
	// exist" checks just below (and the out-of-range checks further
	// down) get the new `errNodeNotFound' (485) instead.
	if (!(("`ego'" != "" & "`alter'" != "" ) | (`egoid' != 0 & `alterid' != 0))){
		di "{err}Either options {bf:ego(), alter()} or {bf:egoid(), alterid()} need to be specified."
		error 198
	}
	_nwsyntax `netname', max(1)
	if `"`ego'"' != "" {
		if `"`alter'"' != "" {
			// check that ego and alter are valid
			mata: st_numscalar("r(ego_valid)", `netobj'->has_node(`"`ego'"'))
			mata: st_numscalar("r(alter_valid)", `netobj'->has_node(`"`alter'"'))

			if `r(ego_valid)' != 1 {
				di "{err}node {it:`ego'} does not exist in network {bf:`netname'}"
				error `errNodeNotFound'
			}
			if `r(alter_valid)' != 1 {
				di "{err}node {it:`alter'} does not exist in network {it:`netname'}"
				error `errNodeNotFound'
			}
			
			capture mata: st_numscalar("r(ego_id)", select((1::`nodes'), (`netobj'->get_nodenames() :== "`ego'")'))
			capture mata: st_numscalar("r(alter_id)", select((1::`nodes'), (`netobj'->get_nodenames() :== "`alter'")'))
			capture mata: st_numscalar("r(value)",(*`netobj'->get_matrix())[`r(ego_id)', `r(alter_id)'])
			capture mata: st_global("r(ego)", "`ego'")
			capture mata: st_global("r(alter)", "`alter'")	
		}
	}
	if `egoid' != 0 & `alterid' != 0 {
		// BUGFIX: out-of-range egoid()/alterid() (either below 1 or
		// above the network's own node count) used to fall straight
		// through this whole block with none of its conditions true -
		// no error, no r(value), just a silent "di ""'" printing an
		// empty line, indistinguishable from a genuine zero-valued tie
		// unless the caller happened to also check `_rc' or `r(value)'
		// for missing. The equivalent ego()/alter() (name-based) path
		// just above already raises a clean error for an invalid node
		// - out-of-range ids are the same kind of caller mistake and
		// now raise the same way (`errNodeNotFound', the same code
		// this file's own name-based ego()/alter() path above uses).
		if `egoid' < 1 | `egoid' > `nodes' {
			di "{err}egoid {it:`egoid'} out of range (network `netname' has `nodes' nodes)"
			error `errNodeNotFound'
		}
		if `alterid' < 1 | `alterid' > `nodes' {
			di "{err}alterid {it:`alterid'} out of range (network `netname' has `nodes' nodes)"
			error `errNodeNotFound'
		}
		capture mata: st_numscalar("r(value)",(*`netobj'->get_matrix())[`egoid', `alterid'])
		capture mata: st_numscalar("r(ego_id)", `egoid')
		capture mata: st_numscalar("r(alter_id)", `alterid')
		capture mata: st_global("r(ego)", `netobj'->get_nodenames()[`r(ego_id)'])
		capture mata: st_global("r(alter)", `netobj'->get_nodenames()[`r(alter_id)'])
	}
	di "`r(value)'"
end

