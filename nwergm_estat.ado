/***
{smcl}
{* *! version 1.0.0  22aug2026 author: Thomas Grund}{...}

{title:Title}

{p2colset 9 25 26 2}{...}
{p2col :nwergm postestimation {hline 2}}Postestimation tools for {cmd:nwergm}{p_end}
{p2colreset}{...}

{title:Description}

{pstd}
The following postestimation commands are available after {helpb nwergm}:

{p2colset 9 22 23 2}{...}
{p2col: {cmd:estat mcmcdiag}}Basic MCMC diagnostics for the final simulation (method(mcmle) only){p_end}
{p2col: {cmd:estat gof}}Basic simulation-based goodness of fit{p_end}
{p2colreset}{...}

{title:estat mcmcdiag}

{pstd}
{cmd:estat mcmcdiag} reports basic diagnostics (Part XIX of the governing {cmd:nwergm} design
brief) for the final MCMC simulation {cmd:nwergm} ran at its converged (or last-tried)
coefficient vector: per-statistic mean, standard deviation, lag-1 autocorrelation, and an
AR(1)-based effective sample size, plus the overall Metropolis-Hastings acceptance rate and
{cmd:nwergm}'s own MCMLE convergence-test result. Available only after {opt method(mcmle)} -
a pure MPLE fit involves no MCMC simulation at all, so there is nothing to diagnose.

{pstd}
{bf:This command never claims a fit converged merely because estimation stopped.} A satisfied
convergence test is reported as exactly that - a necessary check that passed, not a proof of
global convergence - and low ESS, low acceptance rate, or high autocorrelation are signs worth
investigating even when {cmd:e(converged)} is 1.

{title:estat gof}

{pstd}
{cmd:estat gof} {opt [, NSIM(integer 50) SEED(integer -1) GOFBURNIN(integer 3000) GOFINTERVAL(integer 50)]}
compares the fitted model's own simulated networks against the network {cmd:nwergm} was fitted
on, on three dimensions computed via this package's own existing commands rather than
duplicating their algorithms: mean degree (arithmetic), average geodesic distance
({helpb nwgeodesic}), and the count of complete (3-edge) triads ({helpb nwtriads}). {opt nsim()}
simulated networks are drawn by continuing the Markov chain from wherever {cmd:nwergm}'s own
fit left it (for {opt method(mcmle)}) or from the observed network itself (for
{opt method(mple)}, which never runs MCMC during estimation), recording one snapshot every
{opt gofinterval()} steps.

{pstd}
{bf:This is a BASIC check, not a formal test.} A large, systematic gap between the Observed and
Simulated columns on any row is evidence against the fitted model; rough agreement is evidence
for it, not proof. A simulated network that happens to be disconnected or edgeless does not
contribute to the geodesic/triad-census averages respectively (reported in the output) rather
than being treated as an error.

{title:Stored results}

{pstd}
{cmd:estat mcmcdiag} stores the following in {cmd:r()}:

	Scalars
	  {bf:r(acceptrate)}		Metropolis-Hastings acceptance rate over the final simulation

{pstd}
{cmd:estat gof} stores the following in {cmd:r()}:

	Scalars
	  {bf:r(obs_meandeg)}		observed mean degree
	  {bf:r(sim_meandeg)}		simulated mean degree, averaged over {opt nsim()} draws
	  {bf:r(obs_avgpath)}		observed average geodesic distance
	  {bf:r(sim_avgpath)}		simulated average geodesic distance (missing if every draw was disconnected)
	  {bf:r(obs_triad300)}		observed complete-triad count
	  {bf:r(sim_triad300)}		simulated complete-triad count, averaged over contributing draws

{title:See also}

	{help nwergm}

***/

capture program drop nwergm_estat
program define nwergm_estat, rclass
	gettoken subcmd rest : 0, parse(" ,")
	local subcmd = lower(trim("`subcmd'"))
	if "`subcmd'" == "mcmcdiag" {
		nwergm_estat_mcmcdiag `rest'
		return add
	}
	else if "`subcmd'" == "gof" {
		nwergm_estat_gof `rest'
		return add
	}
	else {
		di as err "estat `subcmd' not allowed after nwergm"
		exit 321
	}
end

capture program drop nwergm_estat_mcmcdiag
program define nwergm_estat_mcmcdiag, rclass
	syntax [, *]

	if `"`e(cmd)'"' != "nwergm" {
		di as err "last nwergm estimates not found"
		exit 301
	}
	if `"`e(method)'"' != "mcmle" {
		di as err "{bf:estat mcmcdiag} is only available after {bf:method(mcmle)} - MPLE fits involve no MCMC simulation."
		exit 498
	}

	tempname bmat
	matrix `bmat' = e(b)
	local p = colsof(`bmat')
	local names : colnames `bmat'

	tempname samp
	mata: `samp' = st_matrix("e(mcmcsample)")

	di
	di as txt "MCMC diagnostics for the final simulation (nwergm, method(mcmle))"
	di as txt "Sample size:{col 22}={res}  " %6.0f e(mcmc_samplesize)
	di as txt "Burn-in:{col 22}={res}  " %6.0f e(mcmc_burnin)
	di as txt "Thinning interval:{col 22}={res}  " %6.0f e(mcmc_interval)
	di as txt "Acceptance rate:{col 22}={res}  " %6.4f e(mcmc_acceptrate)
	di
	di as txt "{hline 16}{c TT}{hline 11}{hline 11}{hline 12}{hline 9}"
	di as txt %-16s "Statistic" "{c |}" %10s "Mean" %11s "SD" %12s "Autocorr" %9s "ESS"
	di as txt "{hline 16}{c +}{hline 11}{hline 11}{hline 12}{hline 9}"
	forvalues k = 1/`p' {
		local nm : word `k' of `names'
		mata: st_local("__ergm_mn", strofreal(mean(`samp'[.,`k'])))
		mata: st_local("__ergm_sd", strofreal(sqrt(variance(`samp'[.,`k']))))
		mata: st_local("__ergm_rho", strofreal(ergm_lag1_autocorr(`samp')[`k']))
		local __ergm_rhoclip = max(0, min(0.999, `__ergm_rho'))
		mata: st_local("__ergm_ess", strofreal(rows(`samp')*(1-`__ergm_rhoclip')/(1+`__ergm_rhoclip')))
		di as txt %-16s "`nm'" "{c |}" as res %10.4f `__ergm_mn' %11.4f `__ergm_sd' %12.4f `__ergm_rho' %9.1f `__ergm_ess'
	}
	di as txt "{hline 16}{c BT}{hline 11}{hline 11}{hline 12}{hline 9}"
	di

	if e(converged) == 1 {
		di as txt "MCMLE's own convergence test was satisfied after " %3.0f e(mcmle_iterations) " iteration(s)."
	}
	else {
		di as err "Warning: MCMLE did NOT satisfy its own convergence test - treat these diagnostics, and the fitted coefficients, with caution."
	}
	di as txt "Note: a satisfied convergence test is a necessary check, not proof of a converged fit - inspect the autocorrelation/ESS above, and consider increasing {bf:mcmcsamplesize()}/{bf:mcmleiterations()} if acceptance rate or ESS looks poor."

	return scalar acceptrate = e(mcmc_acceptrate)

	mata: mata drop `samp'
end

capture program drop nwergm_estat_gof
program define nwergm_estat_gof, rclass
	syntax [, NSIM(integer 50) SEED(integer -1) GOFBURNIN(integer 3000) GOFINTERVAL(integer 50)]

	if `"`e(cmd)'"' != "nwergm" {
		di as err "last nwergm estimates not found"
		exit 301
	}
	capture mata: __nwergm_last_G.n
	if _rc {
		di as err "no fitted nwergm model available for simulation - re-run nwergm before estat gof."
		exit 498
	}
	if `seed' != -1 {
		set seed `seed'
	}

	local depvar `"`e(depvar)'"'
	local edirected `"`e(directed)'"'
	capture nw_syntax `depvar', max(1)
	if _rc {
		di as err "network `depvar' (the network nwergm was fitted on) is no longer loaded - estat gof needs it for the observed comparison statistics."
		exit 498
	}
	if `nodes' != e(nodes) | ("`directed'"=="true") != ("`edirected'"=="true") {
		di as err "network `depvar' no longer matches the network nwergm was fitted on (nodes or directedness differ) - re-fit before running estat gof."
		exit 498
	}

	// observed comparison statistics (Part XX: reuse the package's own
	// existing algorithms - nwgeodesic's real BFS/Dijkstra machinery and
	// nwtriads' real MAN-census machinery - rather than duplicating
	// them; mean degree is plain arithmetic, not "an algorithm", so it
	// is computed directly rather than via nwdegree's own dataset-
	// variable-generating side effects). Computed on a FRESH temporary
	// network materialized straight from `depvar's own current Mata
	// adjacency (via the same ergm_bridge_from_netobj()/to_dense()/
	// ErgmMatToLiteral() path the simulated side uses below), rather
	// than calling nwgeodesic/nwtriads on `depvar' directly, purely for
	// consistency with the simulated side (both computed the identical
	// way, on an identically-constructed temp network) rather than any
	// known problem with `depvar' itself.
	local obs_meandeg = 2*e(ties)/e(nodes)
	tempname obsG
	mata: `obsG' = ErgmGraph()
	mata: `obsG'.init(`nodes', ("`directed'"=="true"))
	mata: nwergm_estat_bridge_from_netobj(`netobj', `obsG', ("`directed'"=="true"))
	mata: st_local("__gof_obsexpr", ErgmMatToLiteral(`obsG'.to_dense()))
	mata: mata drop `obsG'

	preserve
	qui drop _all
	qui set obs `nodes'
	capture nwdrop _nwergm_gofobs
	qui nwset, mat(`__gof_obsexpr') `=cond("`edirected'"=="true","directed","undirected")' name(_nwergm_gofobs) nooutput
	qui nwgeodesic _nwergm_gofobs, nwreplace
	local obs_avgpath = r(avgpath)
	// nwtriads.ado has a genuine, pre-existing bug (unrelated to nwergm,
	// confirmed via an isolated repro: `nwset, mat((0,0\0,0)) undirected
	// name(x)' then `nwtriads x' crashes with "n not found - data
	// already wide", r(111)) on a network with ZERO ties - wrapped in
	// `capture' here (and below, for the simulated side, where an
	// empty/near-empty draw is a real possibility during MCMC) rather
	// than fixed, since it is out of this subsystem's own scope; see
	// docs/CERTIFICATION.md's Pending list for the full disclosure.
	capture qui nwtriads _nwergm_gofobs
	if _rc == 0 {
		local obs_triad300 = r(_300)
	}
	else {
		local obs_triad300 = .
	}
	capture nwdrop _nwergm_gofobs
	restore

	// simulated comparison statistics: continue the chain from wherever
	// __nwergm_last_G currently stands (already at/near stationarity for
	// a method(mcmle) fit; for method(mple) this is the FIRST simulation
	// ever run for this fit, starting from the observed network itself -
	// both are valid MCMC starting points, not a shortcut) at the fitted
	// e(b), materializing one snapshot every `gofinterval()' steps into a
	// real temporary nw_def network via nwset so nwgeodesic/nwtriads can
	// be reused unmodified.
	tempname bmat
	matrix `bmat' = e(b)

	local __gof_nsim_ok = 0
	local __gof_sum_deg = 0
	local __gof_sum_path = 0
	local __gof_sum_triad = 0
	local __gof_path_ok = 0
	local __gof_triad_ok = 0

	preserve
	forvalues __s = 1/`nsim' {
		local __gof_thisburnin = cond(`__s'==1, `gofburnin', 0)
		mata: __gof_discard = ErgmMCMCSample(__nwergm_last_M, __nwergm_last_G, st_matrix("`bmat'"), `__gof_thisburnin', `gofinterval', 1, &ergm_propose_tnt())
		mata: st_numscalar("__gof_deg", 2*__nwergm_last_G.nties/__nwergm_last_G.n)
		mata: st_local("__gof_matexpr", ErgmMatToLiteral(__nwergm_last_G.to_dense()))

		qui drop _all
		qui set obs `nodes'
		capture nwdrop _nwergm_gofsim
		qui nwset, mat(`__gof_matexpr') `=cond("`edirected'"=="true","directed","undirected")' name(_nwergm_gofsim) nooutput

		local __gof_nsim_ok = `__gof_nsim_ok' + 1
		local __gof_sum_deg = `__gof_sum_deg' + __gof_deg

		capture qui nwgeodesic _nwergm_gofsim, nwreplace
		if _rc == 0 & r(avgpath) < . & r(avgpath) != -1 {
			local __gof_sum_path = `__gof_sum_path' + r(avgpath)
			local __gof_path_ok = `__gof_path_ok' + 1
		}
		capture qui nwtriads _nwergm_gofsim
		if _rc == 0 {
			local __gof_sum_triad = `__gof_sum_triad' + r(_300)
			local __gof_triad_ok = `__gof_triad_ok' + 1
		}
	}
	restore
	capture nwdrop _nwergm_gofsim

	local sim_meandeg = `__gof_sum_deg' / `__gof_nsim_ok'
	if `__gof_path_ok' > 0 {
		local sim_avgpath = `__gof_sum_path' / `__gof_path_ok'
	}
	else {
		local sim_avgpath = .
	}
	if `__gof_triad_ok' > 0 {
		local sim_triad300 = `__gof_sum_triad' / `__gof_triad_ok'
	}
	else {
		local sim_triad300 = .
	}

	di
	di as txt "Simulation-based goodness of fit (nwergm), " `nsim' " simulated network(s) at the fitted coefficients"
	di as txt "{hline 18}{c TT}{hline 14}{hline 14}"
	di as txt %-18s "Statistic" "{c |}" %13s "Observed" %13s "Simulated"
	di as txt "{hline 18}{c +}{hline 14}{hline 14}"
	di as txt %-18s "Mean degree" "{c |}" as res %13.4f `obs_meandeg' %13.4f `sim_meandeg'
	if `sim_avgpath' < . {
		di as txt %-18s "Avg. geodesic" "{c |}" as res %13.4f `obs_avgpath' %13.4f `sim_avgpath'
	}
	else {
		di as txt %-18s "Avg. geodesic" "{c |}" as res %13.4f `obs_avgpath' %13s "n/a"
	}
	if `sim_triad300' < . {
		di as txt %-18s "Complete triads" "{c |}" as res %13.4f `obs_triad300' %13.4f `sim_triad300'
	}
	else {
		di as txt %-18s "Complete triads" "{c |}" as res %13.4f `obs_triad300' %13s "n/a"
	}
	di as txt "{hline 18}{c BT}{hline 14}{hline 14}"
	di
	di as txt "Note: this is a BASIC goodness-of-fit check (Part XX) - a large, systematic gap between the Observed and Simulated columns on any row is evidence against the fitted model; rough agreement is evidence for it, not proof. Only " `__gof_path_ok' " of " `nsim' " draws contributed to the geodesic average (excluded draws were disconnected) and " `__gof_triad_ok' " of " `nsim' " to the triad-census average (excluded draws hit a known, unrelated nwtriads.ado limitation on zero-tie networks - see docs/CERTIFICATION.md)."

	return scalar sim_meandeg = `sim_meandeg'
	return scalar sim_avgpath = `sim_avgpath'
	return scalar sim_triad300 = `sim_triad300'
	return scalar obs_meandeg = `obs_meandeg'
	return scalar obs_avgpath = `obs_avgpath'
	return scalar obs_triad300 = `obs_triad300'

	capture nwdrop _nwergm_gofsim
end

/*
	Own copy of nwergm.ado's own ergm_bridge_from_netobj() (identical
	logic, distinct name). Found by direct trial that Mata functions
	defined at a DIFFERENT .ado file's own file scope do not reliably
	remain callable from a SEPARATE .ado file's own later, separate
	auto-load event, even after that first file's own command has
	already run successfully in the same session (confirmed: right
	after a successful `nwergm mynet, edges' call - which itself
	internally calls ergm_bridge_from_netobj() - a direct
	`mata: mata query'/`capture mata: mata which ergm_bridge_from_netobj()'
	check from the SAME session shows it no longer resolvable; it IS
	reliably available from a `run nwergm.ado' - as opposed to normal
	command auto-load - which is why this was missed until a plain
	cscript-style dev-mode test, not an ad hoc scratch script using
	`run', first exercised it). Each `.ado' file that needs this bridge
	must define its own copy at its own file scope, exactly like
	nwergm.ado's own copy - this is not a case of unwanted duplication,
	it is the same established, working pattern applied per-file.
*/
capture mata: mata drop nwergm_estat_bridge_from_netobj()
mata:
void nwergm_estat_bridge_from_netobj(pointer(class nw_def scalar) scalar netobj,
	class ErgmGraph scalar G, real scalar directed){
	real scalar i, k
	real matrix nb

	for (i=1; i<=G.n; i++) {
		nb = netobj->neighbors(i)
		for (k=1; k<=rows(nb); k++) {
			if (!directed & nb[k] <= i) continue
			G.toggle(i, nb[k])
		}
	}
}
end
