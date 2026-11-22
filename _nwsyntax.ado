*! Date        : 26oct2015
*! Version     : 2.0
*! Author      : Thomas Grund, RWTH Aachen University
*! Email	   : thomas.u.grund@gmail.com

capture program drop _nwsyntax
program _nwsyntax
	syntax [anything],[max(integer 1) min(passthru) other(string) nocurrent name(string)]
	unw_defs

	if "`name'" == "" {
		local name = "netname"
	}
	
	local networks_count = 1
	local __nwsx_info ""
	// fast path: one word that is exactly the name of a stored network (no wildcard, range or abbreviation) needs no nwunab
	local __nwsx_fast 0
	if "`anything'" != "" & "`current'" == "" & "`min'" == "" {
		if `: word count `anything'' == 1 & ("`max'" == "." | real("`max'") >= 1) {
			if !(strpos("`anything'", "*") | strpos("`anything'", "?") | strpos("`anything'", "~") | strpos("`anything'", "-") | strpos("`anything'", "$")) {
				capture mata: nwf_syntax_named("`anything'")
				if _rc == 0 {
					capture confirm number `r(id)'
					if _rc == 0 {
						if `r(id)' > 0 {
							local _temp "`anything'"
							local lastnet "`anything'"
							local __nwsx_fast 1
							// the r() values that nwunab leaves behind (commands read r(netlist) and r(networks) after _nwsyntax)
							mata: st_global("r(netlist)", "`anything'"); st_global("r(networks)", "1")
						}
					}
				}
			}
		}
	}
	if "`anything'" == ""  & "`current'" == ""{
		capture mata: nwf_syntax_current()
	}
	else if `__nwsx_fast' == 0 {
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
		capture mata: nwf_syntax_named("`lastnet'")
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
	local __nwsyntax_ok = `__nwsx_fast'
	if `__nwsx_fast' == 0 & _rc == 0 {
		capture confirm number `r(id)'
		if _rc == 0 {
			if `r(id)' > 0 {
				local __nwsyntax_ok = 1
			}
		}
	}
	if `__nwsyntax_ok' == 0 {
		// more networks than the command takes (e.g. "nwrem g h"): say so, rather than "Network g h not found"
		if "`anything'" != "" & "`max'" != "." {
			capture nwunab __nwsx_all : `anything'
			if _rc == 0 {
				local __nwsx_n : word count `__nwsx_all'
				if `__nwsx_n' > `max' {
					local __nwsx_s = cond(`max' == 1, "network is", "networks are")
					di "{err}{p 0 0 2}too many networks: {bf:`__nwsx_all'}; only `max' `__nwsx_s' allowed here.{p_end}"
					exit 198
				}
			}
		}
		di "{err}Network {bf:`anything'} not found"
	    exit `errNWsNotFound'
	}

	// one Mata statement instead of nine (nwf_syntax_info() in unw_core.do)
	if "`__nwsx_info'" == "" mata: nwf_syntax_info(`r(id)')

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
