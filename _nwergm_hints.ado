*! _nwergm_hints: validate nwergm's mcmcprop() (R ergm's control MCMC.prop hint formula)
capture program drop _nwergm_hints
program _nwergm_hints
	version 14
	syntax , SPEC(string asis)
	mata: _ergm_con_split(`"`spec'"')
	local unmet ""
	forvalues t = 1/`__cn' {
		local nm `__cnm`t''
		if !inlist("`nm'", "sparse", "TNT", "triadic", "strat", "Strat", ".triadic") {
			di as err "Sample space constraint '`nm'' not found."
			error 198
		}
		if inlist("`nm'", "triadic", "strat", "Strat", ".triadic") local unmet "`unmet' '`nm''"
	}
	if "`unmet'" != "" {
		di "{txt}Best valid proposal 'TNT' cannot take into account hint(s)`unmet'."
	}
end
