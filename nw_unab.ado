
capture program drop nw_unab
program nw_unab, rclass
	syntax anything, [ min(passthru) max(passthru)]
	gettoken macro_name _temp : anything, parse(":")
	local _temp : subinstr local _temp ":" ""
	local _tempcount : word count `_temp'
	local netlist `_temp'
	
	preserve
	drop _all
	unw_defs
	mata: st_global("r(names)", `nws'.get_names())
	foreach n in `r(names)' {
		noi gen `n' = .
	}
	if "`max'" == "max(.)" {
		local max ""
	}
	unab unabnets : `netlist', `max' `min'
	local numnets : word count `unabnets'
	
	return local networks `numnets'
	return local netlist "`unabnets'" 
	c_local `macro_name' "`unabnets'"
	restore
end
