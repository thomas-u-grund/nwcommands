*! Date        : 15oct2015
*! Version     : 2.0
*! Author      : Thomas Grund, RWTH Aachen University
*! Email	   : thomas.u.grund@gmail.com

capture program drop nwunab
program nwunab, rclass
	syntax anything, [ min(passthru) max(passthru)]
	gettoken macro_name _temp : anything, parse(":")
	local _temp : subinstr local _temp ":" ""
	local _tempcount : word count `_temp'
	local netlist `_temp'
	
	unw_defs
	// Fast path: when every word is the exact name of a registered
	// network (no wildcard, range or abbreviation), unab would return
	// the words unchanged; the dataset round trip below costs O(number
	// of stored networks) per call, which made creating k networks
	// quadratic. Anything else (and any max()/min() violation) takes
	// the unab route, which also produces the error messages.
	if `_tempcount' > 0 {
		capture mata: st_local("__nwu_all", `nws'.get_names())
		if _rc == 0 & `"`__nwu_all'"' != "" {
			local __nwu_fast 1
			foreach w of local _temp {
				if strpos("`w'", "*") | strpos("`w'", "?") | strpos("`w'", "~") | strpos("`w'", "-") | strpos("`w'", "$") {
					local __nwu_fast 0
				}
			}
			if `__nwu_fast' {
				local __nwu_fast : list _temp in __nwu_all
			}
			if `__nwu_fast' {
				local __nwu_mx = 1e9
				local __nwu_mn = 1
				if "`max'" != "" & "`max'" != "max(.)" {
					local __nwu_mx = real(subinstr(subinstr("`max'", "max(", "", 1), ")", "", 1))
				}
				if "`min'" != "" {
					local __nwu_mn = real(subinstr(subinstr("`min'", "min(", "", 1), ")", "", 1))
				}
				if `_tempcount' <= `__nwu_mx' & `_tempcount' >= `__nwu_mn' {
					local __nwu_out : list clean _temp
					return local networks `_tempcount'
					return local netlist "`__nwu_out'"
					c_local `macro_name' "`__nwu_out'"
					exit
				}
			}
		}
	}

	preserve
	drop _all
	mata: st_global("r(names)", `nws'.get_names())
	foreach n in `r(names)' {
		noi gen `n' = .
	}
	// BUGFIX: `passthru' defaults an unspecified max() to the literal
	// text "max(.)" rather than leaving it empty, which `unab' itself
	// would reject/misinterpret as a real max() value of "." - normalize
	// back to "no max given" before forwarding to `unab' (ported from
	// nw_unab.ado, which already had this fix - see LEGACY_FILES.md).
	if "`max'" == "max(.)" {
		local max ""
	}
	unab unabnets : `netlist', `max' `min'
	// BUGFIX: was `word count "`unablist'"' - `unablist' is never
	// populated by anything in this program (a typo for `unabnets',
	// the local `unab' actually fills), so the quoted expression always
	// expanded to the two-character literal string `""' regardless of
	// how many networks matched - which `word count' itself counts as
	// exactly one word, making r(networks) always 1 no matter how many
	// networks were actually found (confirmed directly).
	local numnets : word count `unabnets'
	return local networks `numnets'
	return local netlist "`unabnets'" 
	c_local `macro_name' "`unabnets'"
	restore
end
