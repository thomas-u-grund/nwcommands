/***
{smcl}
{* *! version 1.0.0  22aug2026 author: Thomas Grund}{...}

{title:Title}

{p2colset 9 25 26 2}{...}
{p2col :nwergm postestimation {hline 2} Postestimation tools for {cmd:nwergm}{p_end}
{p2colreset}{...}

{title:Description}

{pstd}
The following postestimation command is available after {helpb nwergm} with {opt method(mcmle)}:

{p2colset 9 22 23 2}{...}
{p2col: {cmd:estat mcmcdiag}}Basic MCMC diagnostics for the final simulation{p_end}
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

{title:Stored results}

{pstd}
{cmd:estat mcmcdiag} stores the following in {cmd:r()}:

	Scalars
	  {bf:r(acceptrate)}		Metropolis-Hastings acceptance rate over the final simulation

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
