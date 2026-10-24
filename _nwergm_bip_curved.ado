capture program drop _nwergm_bip_curved
program _nwergm_bip_curved
	// curved (estimated-decay) bipartite terms: gwb1degree, gwb2degree, gwb1dsp, gwb2dsp with R's fixed=FALSE.
	// The raw count statistics 1..max are registered and the term is marked curved (as gwdegreefree()/gwdspfree()).
	version 14
	syntax , [BGWDEGREEFREE1(string) BGWDEGREEFREE2(string) BGWDSPFREE1(string) BGWDSPFREE2(string)]
	local temps ""
	foreach o in bgwdegreefree bgwdspfree {
		forvalues m = 1/2 {
			local v `"``o'`m''"'
			if `"`v'"' == "" continue
			capture confirm number `v'
			if _rc {
				di "{err}{bf:`o'`m'()} takes the starting value of the decay parameter, a number."
				error 198
			}
			if "`o'" == "bgwdegreefree" mata: st_local("__maxd", strofreal(_bx_maxdeg(__nwergm_last_G, `m')))
			else mata: st_local("__maxd", strofreal(_bx_maxsp(__nwergm_last_G, `m')))
			mata: st_local("__other", strofreal(rows(_bx_nodes(__nwergm_last_G, 3 - `m'))))
			local maxd = max(1, min(`__other', `__maxd' + 1))
			capture mata: __nwbx_cnt = __nwbx_cnt + 1
			if _rc mata: __nwbx_cnt = 1
			mata: st_local("td", "__nwbx" + strofreal(__nwbx_cnt))
			mata: `td' = ErgmTermData()
			local names ""
			forvalues k = 1/`maxd' {
				local names "`names' `o'`m'_`k'"
			}
			if "`o'" == "bgwdegreefree" {
				mata: `td'.levels = (1..`maxd')'
				mata: __nwergm_last_M.addterm("b`m'degree", `maxd', &stat_b`m'degree(), &change_b`m'degree(), `td', tokens("`names'"))
			}
			else {
				mata: `td'.levelpairs = (J(`maxd', 1, 10), (1..`maxd')', J(`maxd', 1, `m'))
				mata: `td'.attr = J(__nwergm_last_G.n, 1, 0)
				mata: __nwergm_last_M.addterm("bipx", `maxd', &stat_bipx(), &change_bipx(), `td', tokens("`names'"))
			}
			mata: __nwergm_last_M.mark_curved()
			local temps "`temps' `td'"
		}
	}
	c_local __ergm_bipnewtemps "`temps'"
end
