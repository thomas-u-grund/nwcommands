capture program drop _nwergm_bipgof
program _nwergm_bipgof, rclass
	// Goodness of fit for a bipartite model, as R's gof(): b1degree, b2degree, dspartners and distance
	// (observed, min, mean, max and Monte Carlo p-value over nsim simulated networks)
	version 14
	syntax , OBS(string) NSIM(integer) BURNIN(integer) INTERVAL(integer) N1(integer) N2(integer) NODES(integer)
	tempname bmat sim
	matrix `bmat' = e(b)
	mata: st_local("__gof_hasmask", strofreal(__nwergm_last_G.has_dyadmask))
	if `__gof_hasmask' {
		if "`e(proposal)'" == "tnt" local __gof_propfn "&ergm_propose_tnt_masked()"
		else local __gof_propfn "&ergm_propose_uniform_masked()"
	}
	else local __gof_propfn "&ergm_propose_tnt()"
	mata: `sim' = J(0, cols(`obs'), .)
	forvalues s = 1/`nsim' {
		local b = cond(`s' == 1, `burnin', 0)
		mata: __gof_discard = ErgmMCMCSample(__nwergm_last_M, __nwergm_last_G, st_matrix("`bmat'"), `b', `interval', 1, `__gof_propfn')
		mata: `sim' = `sim' \ ergm_bip_gofstats(__nwergm_last_G)
	}
	capture mata: mata drop __gof_discard
	local lens "`=`n2'+1' `=`n1'+1' `=`nodes'-1' `nodes'"
	local titles "b1degree b2degree dspartners distance"
	local first 1
	local k 0
	foreach t of local titles {
		local ++k
		local len : word `k' of `lens'
		local last = `first' + `len' - 1
		mata: st_matrix("__gof_o", `obs'[1, `first'..`last'])
		mata: st_matrix("__gof_s", `sim'[., `first'..`last'])
		mata: st_matrix("__gof_res", (`obs'[1, `first'..`last']' , colmin(`sim'[., `first'..`last'])', colsum(`sim'[., `first'..`last'])' / rows(`sim'), colmax(`sim'[., `first'..`last'])', J(`len', 1, .)))
		mata: __gof_d = `sim'[., `first'..`last'] :- `obs'[1, `first'..`last']
		mata: st_matrix("__gof_p", rowmin((J(`len',1,1), 2 * rowmin((colsum(__gof_d :>= 0)' / rows(`sim'), colsum(__gof_d :<= 0)' / rows(`sim'))))))
		matrix __gof_res[1, 5] = __gof_p
		// keep rows up to the last one with any count, plus 3 as R's printed summary does
		local lastc = `last' - ("`t'" == "distance")
		mata: st_local("__gof_lastnz", strofreal(max((1, max(selectindex(colsum(abs(`sim'[., `first'..`lastc'])) + `obs'[1, `first'..`lastc'] :> 0))))))
		local show = min(`len' - ("`t'" == "distance"), `__gof_lastnz' + 2)
		local lab = cond("`t'" == "distance", "geodesic distance (last row: infinite)", cond("`t'" == "dspartners", "dyadwise shared partners", "`t'"))
		di
		di as txt "Goodness-of-fit for `lab'"
		di as txt "{hline 8}{c TT}{hline 56}"
		di as txt %8s "" "{c |}" %10s "obs" %10s "min" %10s "mean" %10s "max" %14s "MC p-value"
		di as txt "{hline 8}{c +}{hline 56}"
		forvalues r = 1/`show' {
			local rl = `r' - 1
			if "`t'" == "distance" local rl = cond(`r' == `len', "Inf", "`r'")
			di as txt %8s "`rl'" "{c |}" as res %10.0f __gof_res[`r',1] %10.0f __gof_res[`r',2] %10.2f __gof_res[`r',3] %10.0f __gof_res[`r',4] %14.3f __gof_res[`r',5]
		}
		if "`t'" == "distance" di as txt %8s "Inf" "{c |}" as res %10.0f __gof_res[`len',1] %10.0f __gof_res[`len',2] %10.2f __gof_res[`len',3] %10.0f __gof_res[`len',4] %14.3f __gof_res[`len',5]
		di as txt "{hline 8}{c BT}{hline 56}"
		matrix `t' = __gof_res
		return matrix `t' = __gof_res
		local first = `last' + 1
	}
	capture mata: mata drop `sim' __gof_d
end
