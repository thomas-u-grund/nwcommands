*! Date        : 15oct2015
*! Version     : 2.0
*! Author      : Thomas Grund, University College Dublin
*! Email	   : thomas.u.grund@gmail.com

capture program drop nwunab
program nwunab, rclass
	syntax anything, [ min(passthru) max(passthru)]
	gettoken macro_name _temp : anything, parse(":")
	local _temp : subinstr local _temp ":" ""
	local _tempcount : word count `_temp'
	local netlist `_temp'
	
	preserve
	drop _all
	mata: st_global("r(names)", nw.nws.get_names())
	foreach n in `r(names)' {
		noi gen `n' = .
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
