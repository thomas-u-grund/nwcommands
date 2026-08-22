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

