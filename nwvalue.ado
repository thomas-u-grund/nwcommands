
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

	mata: st_rclear()

	if (!(("`ego'" != "" & "`alter'" != "" ) | (`egoid' != 0 & `alterid' != 0))){
		di "{err}Either options {bf:ego(), alter()} or {bf:egoid(), alterid()} need to be specified."
		error 3000
	}
	nw_syntax `netname', max(1)
	if `"`ego'"' != "" {
		if `"`alter'"' != "" {
			// check that ego and alter are valid
			mata: st_numscalar("r(ego_valid)", `netobj'->has_node(`"`ego'"'))
			mata: st_numscalar("r(alter_valid)", `netobj'->has_node(`"`alter'"'))
			
			if `r(ego_valid)' != 1 {
				di "{err}node {it:`ego'} does not exist in network {bf:`netname'}"
				error 3000
			}
			if `r(alter_valid)' != 1 {
				di "{err}node {it:`alter'} does not exist in network {it:`netname'}"
				error 3000
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
		// now raise the same way (same error code this file already
		// uses for "does not exist").
		if `egoid' < 1 | `egoid' > `nodes' {
			di "{err}egoid {it:`egoid'} out of range (network `netname' has `nodes' nodes)"
			error 3000
		}
		if `alterid' < 1 | `alterid' > `nodes' {
			di "{err}alterid {it:`alterid'} out of range (network `netname' has `nodes' nodes)"
			error 3000
		}
		capture mata: st_numscalar("r(value)",(*`netobj'->get_matrix())[`egoid', `alterid'])
		capture mata: st_numscalar("r(ego_id)", `egoid')
		capture mata: st_numscalar("r(alter_id)", `alterid')
		capture mata: st_global("r(ego)", `netobj'->get_nodenames()[`r(ego_id)'])
		capture mata: st_global("r(alter)", `netobj'->get_nodenames()[`r(alter_id)'])
	}
	di "`r(value)'"
end

