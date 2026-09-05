*! Date        : 26oct2015
*! Version     : 2.0
*! Author      : Thomas Grund, University College Dublin
*! Email	   : thomas.u.grund@gmail.com

capture program drop _nwsyntax
program _nwsyntax
	syntax [anything],[max(integer 1) min(passthru) other(string) nocurrent name(string)]
	unw_defs

	if "`name'" == "" {
		local name = "netname"
	}
	
	local networks_count = 1
	if "`anything'" == ""  & "`current'" == ""{
		capture mata: st_local("_temp", `nws'.get_current_name())
		capture mata: st_numscalar("r(id)",`nws'.get_index_of_current())
	}
	else {
		capture nwunab _temp : `anything', max(`max') `min'
		local networks_count : word count `_temp'
		capture local lastnet : word `networks_count' of `_temp'
		// missing `capture' - when no network has ever been created
		// this session (`nw' doesn't exist as a Mata object at all,
		// not merely "0 networks registered"), this line raised a raw
		// Mata "type mismatch: exp.exp: transmorphic found where
		// struct expected" (r(3000)) instead of falling through to the
		// clean "not found" error immediately below, since an
		// uncaptured error aborts before the `if _rc != 0' check ever
		// runs. Confirmed via a minimal repro independent of any other
		// bug: `nwclear' then `_nwsyntax somenetwork' in a single
		// session reproduces this on its own.
		capture mata: st_numscalar("r(id)", first_index_match(`nws'.names, "`lastnet'"))
	}

	// BUGFIX: first_index_match() returns a plain 0 (not a Mata error) for
	// "not found", so `capture' above never triggers and `_rc' stays 0
	// even when the requested network doesn't exist - as long as at
	// least one OTHER network is currently loaded (with none loaded at
	// all, `nws'.names itself doesn't exist yet as a Mata object, which
	// DOES throw and IS caught, per the fix directly above this one). The
	// `if _rc != 0' check below then fell through with r(id)==0, and the
	// very next line's `pdefs[0]' array access crashed with a raw,
	// uninformative "subscript invalid" (r(3301)) instead of this
	// command's own clean "not found" message - confirmed directly:
	// loading one real network, then referencing an unrelated bogus name
	// (nwcurrent/nwds/nwdrop/nwsummarize and likely others, all of which
	// resolve their network name through this same shared utility)
	// crashed raw rather than erroring cleanly.
	//
	// Checked via nested `if' blocks, not one compound `_rc != 0 |
	// r(id) == 0' expression: when the mata call itself failed (caught by
	// `capture' above), r(id) can be entirely undefined from this call -
	// a bare `r(id)'' in that state expands to nothing, and splicing that
	// into a compound boolean expression (`|'/`&' do not short-circuit in
	// Stata; both sides are textually substituted before evaluation)
	// produced a malformed "==0 invalid name" syntax error instead of
	// ever reaching this command's own clean message.
	local __nwsyntax_ok = 0
	if _rc == 0 {
		capture confirm number `r(id)'
		if _rc == 0 {
			if `r(id)' > 0 {
				local __nwsyntax_ok = 1
			}
		}
	}
	if `__nwsyntax_ok' == 0 {
		di "{err}Network {bf:`anything'} not found"
	    error `errNWsNotFound'
	}

	mata: st_local("directed", `nws'.pdefs[`r(id)']->is_directed())
	mata: st_local("valued", `nws'.pdefs[`r(id)']->is_valued())
	mata: st_local("nodes", strofreal(`nws'.pdefs[`r(id)']->get_nodes()))
	mata: st_local("selfloops", `nws'.pdefs[`r(id)']->is_selfloop())
	mata: st_local("is2mode", `nws'.pdefs[`r(id)']->is_2mode())
	mata: st_local("istemporal", `nws'.pdefs[`r(id)']->is_temporal())
	mata: st_local("temporaltype", `nws'.pdefs[`r(id)']->get_temporal_type())
	mata: st_local("datasync", strofreal(`nws'.get_datasync()))
    mata: st_local("labs", invtokens(`nws'.pdefs[`r(id)']->get_nodenames(),","))

	c_local `other'selfloops "`selfloops'"
	c_local `other'nodes "`nodes'"
	c_local `other'is2mode "`is2mode'"
	c_local `other'istemporal "`istemporal'"
	c_local `other'temporaltype "`temporaltype'"
	c_local `other'directed "`directed'"
	c_local `other'valued "`valued'"
	c_local `other'netobj "`nws'.pdefs[`r(id)']"
	c_local `other'datasync "`datasync'"
	c_local `other'id `r(id)'
	c_local `other'netname `_temp'
	c_local `other'labs "`labs'"
	c_local networks `networks_count'	
end
