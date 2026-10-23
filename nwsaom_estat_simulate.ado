*! version 0.1.0 23oct2026 nwcommands: estat simulate after nwsaom
/*
	estat simulate: simulate the fitted model forward. For every inter-wave
	period the simulation starts at the OBSERVED start wave of the period and
	runs for the period's length at the fitted parameters (the same procedure
	as the simulations behind estat gof), nsim times.

	theta(matname) and rates(numlist) replace the fitted coefficients and
	rates, which turns the command into a simulation-only mode (RSiena's
	siena07 with simOnly): the model, the data and the effect list are those
	of the last nwsaom fit.

	Results: r(sim), one row per simulation and period (columns sim, period,
	ties, mutual dyads, transitive triples, behavior mean), r(obs) the same
	statistics for the observed end waves. generate(stub) additionally saves
	the simulated networks as nw networks stub_<sim>_p<period>; for a
	co-evolution fit the simulated behavior is saved as variables of the same
	names.
*/
capture program drop nwsaom_estat_simulate
program define nwsaom_estat_simulate, rclass
	syntax [, NSIM(integer 100) SEED(integer -1) THETA(name) RATES(numlist >0) RATESBEH(numlist >0) GENerate(name) ]

	if `"`e(cmd)'"' != "nwsaom" {
		di as err "last nwsaom estimates not found"
		exit 301
	}
	if "`e(twomode)'" == "1" {
		di as err "estat simulate is not yet available after a two-mode (bipartite) fit."
		exit 198
	}
	capture mata: __nwsaom_last_M.nparam()
	if _rc {
		di as err "no fitted nwsaom model available for simulation - re-run nwsaom before estat simulate."
		exit 498
	}
	if `nsim' < 1 {
		di as err "nsim() must be at least 1."
		exit 198
	}
	if `seed' != -1 set seed `seed'

	local nodes = e(nodes)
	local nwaves = e(nwaves)
	local nperiods = `nwaves' - 1
	local coev = e(has_behavior)

	tempname bmat
	matrix `bmat' = e(b)
	if "`theta'" != "" {
		capture confirm matrix `theta'
		if _rc {
			di as err "theta(): matrix `theta' not found."
			exit 111
		}
		if colsof(`theta') != colsof(`bmat') {
			di as err "theta() must be a row vector with " colsof(`bmat') " coefficient(s), in the order of e(b)."
			exit 198
		}
		matrix `bmat' = `theta'
	}

	forvalues pd = 1/`nperiods' {
		local rate`pd' .
		local ratebeh`pd' .
	}
	capture confirm matrix e(rates)
	if _rc == 0 {
		tempname ratesmat
		matrix `ratesmat' = e(rates)
		forvalues pd = 1/`nperiods' {
			local rate`pd' = `ratesmat'[1,`pd']
		}
	}
	else local rate1 = e(rate)
	local symtype = 0
	if "`e(symtype)'" != "" {
		local rate1 = e(rate_actor)
		local symtypes "joint force agree forcing confirmation"
		local symtype : list posof "`e(symtype)'" in symtypes
	}
	capture confirm matrix e(rates_beh)
	if _rc == 0 {
		tempname ratesbehmat
		matrix `ratesbehmat' = e(rates_beh)
		forvalues pd = 1/`nperiods' {
			local ratebeh`pd' = `ratesbehmat'[1,`pd']
		}
	}
	else local ratebeh1 = e(rate_beh)
	if "`rates'" != "" {
		local nr : word count `rates'
		if `nr' != `nperiods' & !(`nr' == 1 & `nperiods' == 1) {
			di as err "rates() needs one rate per period (`nperiods')."
			exit 198
		}
		forvalues pd = 1/`nperiods' {
			local rate`pd' : word `pd' of `rates'
		}
	}
	if "`ratesbeh'" != "" {
		if !`coev' {
			di as err "ratesbeh() requires a co-evolution fit."
			exit 198
		}
		forvalues pd = 1/`nperiods' {
			local ratebeh`pd' : word `pd' of `ratesbeh'
		}
	}
	forvalues pd = 1/`nperiods' {
		if `rate`pd'' >= . {
			di as err "no rate available for period `pd': give rates()."
			exit 198
		}
		if `coev' & `ratebeh`pd'' >= . {
			di as err "no behavior rate available for period `pd': give ratesbeh()."
			exit 198
		}
	}

	mata: __nwsaom_sim_rcattr = J(0, 0, 0)
	mata: __nwsaom_sim_rccoef = J(1, 0, 0)
	if "`e(ratecov)'" != "" {
		mata: __nwsaom_sim_rcattr = st_data(1::`nodes', "`e(ratecov)'")
		mata: __nwsaom_sim_rccoef = st_matrix("e(ratecoefs)")
	}
	if `coev' {
		local pnet = e(p_net)
		mata: __nwsaom_sim_allbeh = *__nwsaom_last_Behwaves[1]
		forvalues w = 2/`nwaves' {
			mata: __nwsaom_sim_allbeh = __nwsaom_sim_allbeh \ *__nwsaom_last_Behwaves[`w']
		}
		mata: st_numscalar("__nwsaom_sim_behmean", mean(__nwsaom_sim_allbeh))
		local behoverall = __nwsaom_sim_behmean
		mata: mata drop __nwsaom_sim_allbeh
	}

	tempname sim obs
	matrix `sim' = J(`nsim' * `nperiods', 6, .)
	matrix `obs' = J(`nperiods', 6, .)
	forvalues pd = 1/`nperiods' {
		local pe = `pd' + 1
		mata: st_matrix("__nwsaom_sim_row", SaomSimSummary(__nwsaom_last_G`pe'.to_dense(), `pd', `=cond(`coev', "mean(*__nwsaom_last_Behwaves[`pe'])", ".")'))
		forvalues c = 1/6 {
			matrix `obs'[`pd', `c'] = __nwsaom_sim_row[1, `c']
		}
	}

	local row = 0
	forvalues s = 1/`nsim' {
		forvalues pd = 1/`nperiods' {
			local ++row
			mata: __nwsaom_sim_G = ErgmGraph()
			mata: SaomCopyGraph(__nwsaom_last_G`pd', __nwsaom_sim_G)
			if `coev' {
				mata: __nwsaom_sim_B = SaomBehavior()
				mata: __nwsaom_sim_B.init(*__nwsaom_last_Behwaves[`pd'], __nwsaom_beh_minval, __nwsaom_beh_maxval, `behoverall', __nwsaom_last_Mbeh.simMean)
				mata: __nwsaom_sim_eng = SaomGofSimCoev(__nwsaom_sim_G, __nwsaom_last_M, st_matrix("`bmat'")[1,1..`pnet'], ///
					__nwsaom_sim_B, __nwsaom_last_Mbeh, st_matrix("`bmat'")[1,(`pnet'+1)..cols(st_matrix("`bmat'"))], `rate`pd'', `ratebeh`pd'')
				mata: st_matrix("__nwsaom_sim_row", (`s', `pd', SaomSimSummary(__nwsaom_sim_G.to_dense(), `pd', mean(__nwsaom_sim_B.values))[3..6]))
			}
			else {
				mata: __nwsaom_sim_eng = SaomGofSimNet(__nwsaom_sim_G, __nwsaom_last_M, st_matrix("`bmat'"), `rate`pd'', `symtype', __nwsaom_sim_rcattr, __nwsaom_sim_rccoef)
				mata: st_matrix("__nwsaom_sim_row", (`s', `pd', SaomSimSummary(__nwsaom_sim_G.to_dense(), `pd', .)[3..6]))
			}
			forvalues c = 1/6 {
				matrix `sim'[`row', `c'] = __nwsaom_sim_row[1, `c']
			}
			if "`generate'" != "" {
				mata: st_matrix("__nwsaom_sim_mat", __nwsaom_sim_G.to_dense())
				if `symtype' != 0 nwset, mat(__nwsaom_sim_mat) undirected name(`generate'_`s'_p`pd') nooutput
				else nwset, mat(__nwsaom_sim_mat) directed name(`generate'_`s'_p`pd') nooutput
				if `coev' {
					capture drop `generate'_`s'_p`pd'
					quietly generate double `generate'_`s'_p`pd' = .
					mata: st_store((1::`nodes'), "`generate'_`s'_p`pd'", __nwsaom_sim_B.values)
				}
			}
		}
	}
	capture mata: mata drop __nwsaom_sim_G __nwsaom_sim_B __nwsaom_sim_eng __nwsaom_sim_rcattr __nwsaom_sim_rccoef
	capture matrix drop __nwsaom_sim_row __nwsaom_sim_mat

	matrix colnames `sim' = sim period ties mutual transitive behmean
	matrix colnames `obs' = sim period ties mutual transitive behmean
	di as txt "Simulation from the fitted model: " as res `nsim' as txt " replication(s) of " as res `nperiods' as txt " period(s)."
	di as txt "Mean over replications (observed end wave in brackets):"
	di as txt %-8s "period" %12s "ties" %12s "mutual" %14s "transitive" %12s "behavior"
	forvalues pd = 1/`nperiods' {
		mata: st_numscalar("__nwsaom_sim_m3", mean(select(st_matrix("`sim'")[., 3], st_matrix("`sim'")[., 2] :== `pd')))
		mata: st_numscalar("__nwsaom_sim_m4", mean(select(st_matrix("`sim'")[., 4], st_matrix("`sim'")[., 2] :== `pd')))
		mata: st_numscalar("__nwsaom_sim_m5", mean(select(st_matrix("`sim'")[., 5], st_matrix("`sim'")[., 2] :== `pd')))
		di as res %-8.0f `pd' %8.1f __nwsaom_sim_m3 as txt " (" as res %4.0f `obs'[`pd', 3] as txt ")" ///
			as res %8.1f __nwsaom_sim_m4 as txt " (" as res %4.0f `obs'[`pd', 4] as txt ")" ///
			as res %10.1f __nwsaom_sim_m5 as txt " (" as res %4.0f `obs'[`pd', 5] as txt ")" _continue
		if `coev' {
			mata: st_numscalar("__nwsaom_sim_m6", mean(select(st_matrix("`sim'")[., 6], st_matrix("`sim'")[., 2] :== `pd')))
			di as res %8.2f __nwsaom_sim_m6 as txt " (" as res %5.2f `obs'[`pd', 6] as txt ")"
		}
		else di
	}
	capture scalar drop __nwsaom_sim_m3 __nwsaom_sim_m4 __nwsaom_sim_m5 __nwsaom_sim_m6
	return matrix sim = `sim'
	return matrix obs = `obs'
	return scalar nsim = `nsim'
end
