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

{title:Supported network types}

{pstd}
Not applicable - these postestimation tools operate on the fitted model and its own MCMC/simulation
output left behind by {help nwergm}, not on a network directly; see that command's own classification.

{title:estat mcmcdiag}

{p 8 17 2}
{cmd:estat mcmcdiag} {opt [, PLOT NAME(string)]}

{pstd}
{cmd:estat mcmcdiag} reports basic diagnostics for the final MCMC simulation {cmd:nwergm} ran
at its converged (or last-tried) coefficient vector: per-statistic mean, standard deviation,
lag-1 autocorrelation, and an AR(1)-based effective sample size, plus the overall
Metropolis-Hastings acceptance rate and {cmd:nwergm}'s own MCMLE convergence-test result.
Available only after {opt method(mcmle)} - a pure MPLE fit involves no MCMC simulation at all,
so there is nothing to diagnose.

{pstd}
{bf:This command never claims a fit converged merely because estimation stopped.} A satisfied
convergence test is reported as exactly that - a necessary check that passed, not a proof of
global convergence - and low ESS, low acceptance rate, or high autocorrelation are signs worth
investigating even when {cmd:e(converged)} is 1.

{pstd}
{opt plot} additionally draws a trace plot and a kernel density plot for each model statistic
in the final MCMC sample - an analogous pair of diagnostic plots to R's {cmd:mcmc.diagnostics()}
produces, combined here into a single figure (one row per statistic) via {help graph combine}.
A trace plot that drifts or shows long runs at one level, rather than a stationary-looking
"fuzzy caterpillar", indicates poor mixing even when the numeric diagnostics above look
acceptable. {opt name()} sets the combined graph's name; default {cmd:mcmcdiag}.

{title:estat gof}

{p 8 17 2}
{cmd:estat gof} {opt [, NSIM(integer 50) SEED(integer -1) GOFBURNIN(integer 3000) GOFINTERVAL(integer 50) PLOT MAXDEG(integer 15) MAXDIST(integer 6) NAME(string)]}

{pstd}
{cmd:estat gof} compares the fitted model's own simulated networks against the network
{cmd:nwergm} was fitted on, on three dimensions computed via this package's own existing
commands rather than duplicating their algorithms: mean degree (arithmetic), average geodesic
distance ({helpb nwgeodesic}), and the full MAN triad census ({helpb nwtriads}).
{opt nsim()} simulated networks are drawn by continuing the Markov chain from wherever
{cmd:nwergm}'s own fit left it (for {opt method(mcmle)}) or from the observed network itself
(for {opt method(mple)}, which never runs MCMC during estimation), recording one snapshot every
{opt gofinterval()} steps.

{pstd}
{bf:Triad census.} The summary table's own "Complete triads" row is joined by a full breakdown,
one row per MAN triad type, exactly matching {helpb nwtriads}'s own category set for the
network's directedness: on a {bf:directed} network, all 16 types ({bf:003}, {bf:012}, {bf:021D},
{bf:021U}, {bf:021C}, {bf:030T}, {bf:030C}, {bf:102}, {bf:111D}, {bf:111U}, {bf:120D}, {bf:120U},
{bf:120C}, {bf:210}, {bf:201}, {bf:300}); on an {bf:undirected} network, only the four types a
0/1/2/3-tie triad can actually be ({bf:003}, {bf:102}, {bf:201}, {bf:300} - the remaining 12
directed-only types are structurally forced to 0 and omitted, matching {cmd:nwtriads}'s own
convention). Each row is an observed COUNT vs. a simulated MEAN COUNT (not a proportion), summed
in {cmd:nwtriads}'s own MAN classification directly - the same simulated draws and the same
disconnected/zero-tie-network defenses ({opt capture} around each draw's own {cmd:nwtriads} call)
already used for the plain "Complete triads" row above it.

{pstd}
{bf:This is a BASIC check, not a formal test.} A large, systematic gap between the Observed and
Simulated columns on any row is evidence against the fitted model; rough agreement is evidence
for it, not proof. A simulated network that happens to be disconnected or edgeless does not
contribute to the geodesic/triad-census averages respectively (reported in the output) rather
than being treated as an error.

{pstd}
{bf:The default {opt nsim(50)} can be too small to trust on its own.} Each simulated draw is
{opt gofinterval()} Metropolis-Hastings steps apart, not an independent redraw, so a
statistic with substantial autocorrelation in the underlying chain (visible via
{help nwergm_estat##mcmcdiag:estat mcmcdiag}'s own Autocorr/ESS columns) can show real
run-to-run swings in the Simulated column at {opt nsim(50)} that have nothing to do with model
fit - confirmed directly: refitting the same model at different seeds moved the simulated mean
degree from noticeably below the observed value to noticeably above it, purely from Monte Carlo
noise, before settling down once {opt nsim()} was increased into the hundreds. If the final MCMC
sample's own autocorrelation is high, increase {opt nsim()} (and consider {opt gofinterval()})
before treating a single {cmd:estat gof} run's Simulated column as a stable estimate.

{pstd}
{opt plot} additionally draws the full degree distribution and the full geodesic-distance
distribution - not just their means - across the {opt nsim()} simulated draws, each as its own
panel: a whisker (minimum-maximum), a box (interquartile range), and a median marker summarize
the simulated draws at each value, with the observed network's own proportion overlaid as a
connected line (dashed, triangle markers - distinguished from the median by shape and line
pattern rather than color, so the figure stays legible printed in black and white). This is an
analogous comparison to Statnet's {cmd:plot(gof())} (via R's {cmd:boxplot()} rather than these
{cmd:graph twoway} primitives), restricted to the two dimensions {cmd:estat gof} already
computes a mean for - it does not add an edgewise shared-partner panel, the third dimension
Statnet's own default GOF plot includes. {opt maxdeg()} caps the degree axis (values above it
are pooled into a single "{it:maxdeg}+" category); {opt maxdist()} similarly caps the
geodesic-distance axis (unreached pairs, including disconnected ones, are pooled into their own
"NR" - not reached - category, matching Statnet's own convention). {opt name()} sets the
combined graph's name; default {cmd:gof}.

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
	  {bf:r(obs_triad{it:XXX})}	observed count for MAN triad type {it:XXX} (one per {helpb nwtriads} category
	                    for the network's directedness - e.g. {bf:r(obs_triad_021D)}, {bf:r(obs_triad_300)})
	  {bf:r(sim_triad{it:XXX})}	simulated mean count for MAN triad type {it:XXX}, averaged over contributing draws

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
	syntax [, PLOT NAME(string)]

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

	if "`plot'" != "" {
		if "`name'" == "" {
			local name "mcmcdiag"
		}
		tempvar drawidx
		tempname sampmat
		matrix `sampmat' = e(mcmcsample)
		preserve
		qui drop _all
		// e(b)'s own column names ("gwesp_.5" for a term like
		// gwesp(.5)) are not legal Stata variable names (a period is
		// not a legal variable-name character), so loaded as plain,
		// sequentially named mcmcv1/mcmcv2/... variables instead; the
		// real term name is used only in plot titles/axis labels,
		// where it is just text, never a variable reference.
		qui svmat double `sampmat', names(mcmcv)
		qui gen `drawidx' = _n
		local __combine_list ""
		forvalues k = 1/`p' {
			local nm : word `k' of `names'
			tempname tr`k' de`k'
			qui twoway line mcmcv`k' `drawidx', ///
				name(`tr`k'', replace) ///
				title("`nm': trace", size(small)) ///
				xtitle("MCMC draw") ytitle("") ///
				legend(off) nodraw
			// ERGM sufficient statistics (edge counts, shared-partner
			// counts, ...) are integer-valued and often take few
			// distinct values over an MCMC run on a small network -
			// `kdensity's own default (Silverman-rule) bandwidth is
			// tuned for continuous data and visibly under-smooths
			// this kind of sparse/discrete support, producing a
			// spurious multi-modal "wiggle" that has nothing to do
			// with the actual sampling distribution. Widened by a
			// fixed multiplier on top of Stata's own default rather
			// than a from-scratch bandwidth rule - good enough to
			// suppress the artifact without materially oversmoothing
			// a genuinely continuous statistic's own density.
			qui kdensity mcmcv`k', nograph
			local __bw = 3 * r(bwidth)
			qui twoway kdensity mcmcv`k', bwidth(`__bw') ///
				name(`de`k'', replace) ///
				title("`nm': density", size(small)) ///
				xtitle("`nm'") ytitle("") ///
				legend(off) nodraw
			local __combine_list `"`__combine_list' `tr`k'' `de`k''"'
		}
		graph combine `__combine_list', cols(2) ///
			title("MCMC diagnostics: trace and density per statistic", size(medium)) ///
			name(`name', replace)
		foreach __g of local __combine_list {
			capture graph drop `__g'
		}
		restore
		di as txt "(plot saved as {bf:`name'}; each row is one model statistic's MCMC trace and density from the final simulation)"
	}

	mata: mata drop `samp'
end

capture program drop nwergm_estat_gof
program define nwergm_estat_gof, rclass
	syntax [, NSIM(integer 50) SEED(integer -1) GOFBURNIN(integer 3000) GOFINTERVAL(integer 50) ///
		PLOT MAXDEG(integer 15) MAXDIST(integer 6) NAME(string)]

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
	// BUGFIX: used to render the dense adjacency matrix as a literal
	// Stata matrix-expression STRING (ErgmMatToLiteral()) and hand that
	// to nwset's own mat() option - which works for small networks, but
	// Stata's own command-line parser hits a hard "too many tokens"
	// error somewhere between 225 and 256 comma-separated matrix
	// elements (confirmed directly: a 15x15 literal parses fine, a
	// 16x16 one does not, on an otherwise identical command) - meaning
	// `estat gof' was completely broken for any network with roughly
	// 16+ nodes, not merely slow. Fixed by passing the matrix as a bare
	// MATA VARIABLE NAME instead of a literal expression string -
	// nwset's own mat() option already accepts this form directly
	// (confirmed: nwrandom.ado's own `nwset, mat(`__nwnew')' call uses
	// exactly this pattern), and since the matrix never has to pass
	// through Stata's command-line tokenizer as a giant string at all,
	// there is no size limit left to hit regardless of network size.
	tempname __gof_obsmat
	mata: `__gof_obsmat' = `obsG'.to_dense()
	mata: mata drop `obsG'

	if "`plot'" != "" {
		tempname obsdeg obsgeo
		mata: `obsdeg' = ergm_gof_degdist(`__gof_obsmat', `maxdeg')
		mata: `obsgeo' = ergm_gof_geodist(`__gof_obsmat', `maxdist')
	}

	preserve
	qui drop _all
	qui set obs `nodes'
	capture nwdrop _nwergm_gofobs
	qui nwset, mat(`__gof_obsmat') `=cond("`edirected'"=="true","directed","undirected")' name(_nwergm_gofobs) nooutput
	mata: mata drop `__gof_obsmat'
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
	// Full MAN triad census (harmonisation unit 143): nwtriads already
	// computes every category in one call - the census was previously
	// discarded down to its own single _300 (complete-triad) category.
	// `__gof_triadcats' matches nwtriads.ado's own directed-vs-undirected
	// convention exactly (its own header note: on an undirected network
	// 12 of the 16 categories are structurally forced to 0, so only
	// _003/_102/_201/_300 are meaningful there).
	if "`edirected'" == "true" {
		local __gof_triadcats "_003 _012 _021D _021U _021C _030T _030C _102 _111D _111U _120D _120U _120C _210 _201 _300"
	}
	else {
		local __gof_triadcats "_003 _102 _201 _300"
	}
	capture qui nwtriads _nwergm_gofobs
	if _rc == 0 {
		local obs_triad300 = r(_300)
		foreach __gof_tc of local __gof_triadcats {
			local obs_triad`__gof_tc' = r(`__gof_tc')
		}
	}
	else {
		local obs_triad300 = .
		foreach __gof_tc of local __gof_triadcats {
			local obs_triad`__gof_tc' = .
		}
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
	foreach __gof_tc of local __gof_triadcats {
		local __gof_sum_triad`__gof_tc' = 0
	}

	// BUGFIX: see the observed-side fix above for the full explanation -
	// a literal matrix-expression string hits Stata's own command-line
	// "too many tokens" limit somewhere around 16 nodes; passing the
	// matrix as a bare Mata variable name instead has no such limit.
	tempname __gof_simmat
	if "`plot'" != "" {
		tempname simdegacc simgeoacc
		mata: `simdegacc' = J(0, `maxdeg'+2, .)
		mata: `simgeoacc' = J(0, `maxdist'+1, .)
	}
	preserve
	forvalues __s = 1/`nsim' {
		local __gof_thisburnin = cond(`__s'==1, `gofburnin', 0)
		mata: __gof_discard = ErgmMCMCSample(__nwergm_last_M, __nwergm_last_G, st_matrix("`bmat'"), `__gof_thisburnin', `gofinterval', 1, &ergm_propose_tnt())
		mata: st_numscalar("__gof_deg", 2*__nwergm_last_G.nties/__nwergm_last_G.n)
		mata: `__gof_simmat' = __nwergm_last_G.to_dense()
		if "`plot'" != "" {
			mata: `simdegacc' = `simdegacc' \ ergm_gof_degdist(`__gof_simmat', `maxdeg')
			mata: `simgeoacc' = `simgeoacc' \ ergm_gof_geodist(`__gof_simmat', `maxdist')
		}

		qui drop _all
		qui set obs `nodes'
		capture nwdrop _nwergm_gofsim
		qui nwset, mat(`__gof_simmat') `=cond("`edirected'"=="true","directed","undirected")' name(_nwergm_gofsim) nooutput

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
			foreach __gof_tc of local __gof_triadcats {
				local __gof_sum_triad`__gof_tc' = `__gof_sum_triad`__gof_tc'' + r(`__gof_tc')
			}
		}
	}
	capture mata: mata drop `__gof_simmat'
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
	foreach __gof_tc of local __gof_triadcats {
		if `__gof_triad_ok' > 0 {
			local sim_triad`__gof_tc' = `__gof_sum_triad`__gof_tc'' / `__gof_triad_ok'
		}
		else {
			local sim_triad`__gof_tc' = .
		}
	}

	di
	di as txt "Simulation-based goodness of fit (nwergm), " `nsim' " simulated network(s) at the fitted coefficients"
	di as txt "{hline 18}{c TT}{hline 14}{hline 14}"
	di as txt %-18s "Statistic" "{c |}" %13s "Observed" %13s "Simulated"
	di as txt "{hline 18}{c +}{hline 14}{hline 14}"
	di as txt %-18s "Mean degree" "{c |}" as res %13.4f `obs_meandeg' %13.4f `sim_meandeg'
	// BUGFIX: the observed side's own -1 "disconnected" sentinel
	// (nwgeodesic's own convention - see the `capture' guard around the
	// SIMULATED side just above, which already treats it as "n/a") was
	// never checked here, so a disconnected OBSERVED network (e.g. the
	// Florentine marriage network's own well-known isolate) displayed a
	// literal, confusing "-1.0000" instead of "n/a".
	local __obs_avgpath_disp = cond(`obs_avgpath' == -1, "n/a", string(`obs_avgpath', "%13.4f"))
	if `sim_avgpath' < . {
		di as txt %-18s "Avg. geodesic" "{c |}" as res %13s "`__obs_avgpath_disp'" %13.4f `sim_avgpath'
	}
	else {
		di as txt %-18s "Avg. geodesic" "{c |}" as res %13s "`__obs_avgpath_disp'" %13s "n/a"
	}
	if `sim_triad300' < . {
		di as txt %-18s "Complete triads" "{c |}" as res %13.4f `obs_triad300' %13.4f `sim_triad300'
	}
	else {
		di as txt %-18s "Complete triads" "{c |}" as res %13.4f `obs_triad300' %13s "n/a"
	}
	di as txt "{hline 18}{c BT}{hline 14}{hline 14}"
	di

	// Full MAN triad census (harmonisation unit 143): the compact table
	// above only ever showed the _300 (complete-triad) category; nwtriads
	// already computes every category applicable to the network's
	// directedness in the SAME call, so surfacing the rest costs nothing
	// extra to compute - only to print and return. Directed networks get
	// the real payoff here (16 genuinely distinct configurations, not
	// just "how many closed triangles"); undirected networks get the 4
	// categories nwtriads itself treats as meaningful there.
	di as txt "Triad census (nwtriads MAN classification):"
	di as txt "{hline 18}{c TT}{hline 14}{hline 14}"
	di as txt %-18s "Type" "{c |}" %13s "Observed" %13s "Simulated"
	di as txt "{hline 18}{c +}{hline 14}{hline 14}"
	foreach __gof_tc of local __gof_triadcats {
		local __gof_tclabel = subinstr("`__gof_tc'", "_", "", .)
		if `sim_triad`__gof_tc'' < . {
			di as txt %-18s "`__gof_tclabel'" "{c |}" as res %13.4f `obs_triad`__gof_tc'' %13.4f `sim_triad`__gof_tc''
		}
		else {
			di as txt %-18s "`__gof_tclabel'" "{c |}" as res %13.4f `obs_triad`__gof_tc'' %13s "n/a"
		}
	}
	di as txt "{hline 18}{c BT}{hline 14}{hline 14}"
	di

	di as txt "Note: this is a BASIC goodness-of-fit check - a large, systematic gap between the Observed and Simulated columns on any row is evidence against the fitted model; rough agreement is evidence for it, not proof. Only " `__gof_path_ok' " of " `nsim' " draws contributed to the geodesic average (excluded draws were disconnected) and " `__gof_triad_ok' " of " `nsim' " to the triad-census average (excluded draws hit a known, unrelated nwtriads.ado limitation on zero-tie networks)."

	return scalar sim_meandeg = `sim_meandeg'
	return scalar sim_avgpath = `sim_avgpath'
	return scalar sim_triad300 = `sim_triad300'
	return scalar obs_meandeg = `obs_meandeg'
	return scalar obs_avgpath = `obs_avgpath'
	return scalar obs_triad300 = `obs_triad300'
	foreach __gof_tc of local __gof_triadcats {
		return scalar obs_triad`__gof_tc' = `obs_triad`__gof_tc''
		return scalar sim_triad`__gof_tc' = `sim_triad`__gof_tc''
	}

	if "`plot'" != "" {
		if "`name'" == "" {
			local name "gof"
		}
		tempname degsumm geosumm
		mata: `degsumm' = ergm_gof_summary5(`simdegacc')
		mata: `geosumm' = ergm_gof_summary5(`simgeoacc')

		tempname panel1 panel2
		nwergm_estat_gofplot `obsdeg' `degsumm' "Degree" "`panel1'" 0 `=`maxdeg'+2' "`maxdeg'+"
		nwergm_estat_gofplot `obsgeo' `geosumm' "Geodesic distance" "`panel2'" 1 `=`maxdist'+1' "NR"
		graph combine `panel1' `panel2', cols(2) ///
			title("Goodness of fit: observed vs. `nsim' simulated draws", size(medium)) ///
			name(`name', replace)
		capture graph drop `panel1'
		capture graph drop `panel2'
		di as txt "(plot saved as {bf:`name'}; whiskers/box/median summarize the `nsim' simulated draws at each value, the connected line is the observed network - the same comparison as the summary table above, shown across the full distribution rather than one summary number)"
	}

	// BUGFIX: a bare `capture' as the program's own LAST executed line
	// leaves its (usually nonzero - the temp network is often already
	// gone by this point) _rc standing as the ambient _rc once the
	// program returns, even though every substantive step above
	// succeeded - the same _rc-staleness class fixed elsewhere in this
	// package (e.g. nwsync.ado, nw2project.ado). A harmless `local'
	// assignment always succeeds, resetting _rc to 0 before returning.
	capture nwdrop _nwergm_gofsim
	local __nwergm_gof_donothing = 0
end

// Renders one GOF panel (degree or geodesic distance): whisker (min-max),
// box (interquartile range), median marker, and the observed proportion
// as a connected line, one x-value per integer startval..startval+ncat-2
// plus a final overflow category ("cap+" for degree, "NR" - not reached -
// for geodesic distance, ncat/startval differ between the two since
// ergm_gof_degdist()/ergm_gof_geodist() use different category counts
// for the same maxval, per their own header comments) - Statnet's own
// plot.gof() draws the identical three-layer comparison, just via R's
// boxplot() instead of these `twoway' primitives (Stata's `graph box'
// cannot be overlaid with an arbitrary observed-value line the way
// `twoway' elements can via `||').
capture program drop nwergm_estat_gofplot
program define nwergm_estat_gofplot
	args obsvec summvec xlabel graphname startval ncat lastlabel

	preserve
	qui drop _all
	// Direct st_addvar()/st_store() rather than svmat, whose default
	// column-naming convention (matrix-name plain vs. matrix-name+index)
	// differs depending on whether the source matrix has one column or
	// several - exactly the ambiguity that broke the first attempt at
	// estat mcmcdiag's own plot support. Explicit names throughout here
	// avoids relying on that convention at all.
	mata: st_addobs(`ncat' - st_nobs())
	mata: st_store(., st_addvar("double", "observed"), `obsvec'')
	mata: st_store(., st_addvar("double", "ymin"), `summvec'[.,1])
	mata: st_store(., st_addvar("double", "yp25"), `summvec'[.,2])
	mata: st_store(., st_addvar("double", "ymedian"), `summvec'[.,3])
	mata: st_store(., st_addvar("double", "yp75"), `summvec'[.,4])
	mata: st_store(., st_addvar("double", "ymax"), `summvec'[.,5])
	qui gen xval = `startval' + _n - 1

	local xlabopt ""
	local __lastval = `startval' + `ncat' - 1
	forvalues i = `startval'/`=`__lastval'-1' {
		local xlabopt `"`xlabopt' `i' "`i'""'
	}
	local xlabopt `"`xlabopt' `__lastval' "`lastlabel'""'

	// Grayscale by design, not merely by accident of the default scheme:
	// the Stata Journal requires figures to remain legible in black and
	// white, so the observed-network line is distinguished from the
	// median marker by shape (triangle vs. diamond) and line pattern
	// (dashed vs. solid), not by color - color is not a legend the
	// figure is allowed to depend on.
	twoway (rcap ymin ymax xval, lcolor(gs10)) ///
		(rbar yp25 yp75 xval, barwidth(0.5) fcolor(gs14) lcolor(gs8)) ///
		(scatter ymedian xval, mcolor(black) msymbol(diamond)) ///
		(connected observed xval, lcolor(black) lpattern(dash) mcolor(black) msymbol(triangle)), ///
		xlabel(`xlabopt', angle(45) labsize(vsmall)) ///
		xtitle("`xlabel'") ytitle("Proportion") ///
		title("`xlabel'", size(small)) legend(off) nodraw name(`graphname', replace)
	restore
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

// GOF-plot support (estat gof, plot): full degree and geodesic-distance
// DISTRIBUTIONS, not just the summary means the plain (non-plot) table
// above reports - the Statnet plot.gof() analogue. Computed directly in
// Mata from the same dense adjacency matrix already built for both the
// observed and each simulated draw, rather than round-tripping each
// draw through nwset/nwgeodesic/nwtriads again (as the summary-table
// code above does for a single mean) - nsim() draws x a full BFS each
// would otherwise mean nsim() more nw_def object creations per plot,
// pure overhead for a plot that only ever needed the raw distances.
capture mata: mata drop ergm_gof_degdist()
capture mata: mata drop ergm_gof_geodist()
mata:
real rowvector ergm_gof_degdist(real matrix M, real scalar maxdeg) {
	real scalar n, i, d
	real colvector deg
	real rowvector counts

	n = rows(M)
	deg = rowsum(M)
	counts = J(1, maxdeg+2, 0)
	for (i=1; i<=n; i++) {
		d = deg[i]
		if (d > maxdeg) d = maxdeg + 1
		counts[d+1] = counts[d+1] + 1
	}
	return(counts / n)
}

real rowvector ergm_gof_geodist(real matrix M, real scalar maxdist) {
	// Unweighted BFS from every node on the 0/1 adjacency matrix M
	// (symmetric for undirected). counts[1..maxdist] = proportion of
	// ordered pairs i!=j at that exact distance; counts[maxdist+1] =
	// unreached (including disconnected) pairs - the "NR" category
	// Statnet's own gof plot shows as its own final bar.
	real scalar n, s, i, j, d, npairs
	real colvector dist, frontier, newfrontier
	real rowvector counts

	n = rows(M)
	counts = J(1, maxdist+1, 0)
	for (s=1; s<=n; s++) {
		dist = J(n,1,.)
		dist[s] = 0
		frontier = s
		d = 0
		while (length(frontier) > 0 & d < maxdist) {
			d++
			newfrontier = J(0,1,0)
			for (i=1; i<=length(frontier); i++) {
				for (j=1; j<=n; j++) {
					if (M[frontier[i],j] & dist[j]==.) {
						dist[j] = d
						newfrontier = newfrontier \ j
					}
				}
			}
			frontier = newfrontier
		}
		for (j=1; j<=n; j++) {
			if (j==s) continue
			if (dist[j]==.) counts[maxdist+1] = counts[maxdist+1] + 1
			else counts[dist[j]] = counts[dist[j]] + 1
		}
	}
	npairs = n*(n-1)
	if (npairs > 0) counts = counts / npairs
	return(counts)
}

// Per-column (min, p25, median, p75, max) across simulated draws, via a
// plain nearest-rank method on the sorted column - not a claim to match
// any particular textbook quantile convention exactly (R's boxplot() and
// Stata's own `summarize, detail' each use their own), just enough to
// draw a representative box/whisker range for a visual GOF comparison.
real matrix ergm_gof_summary5(real matrix draws) {
	real scalar ncol, nrow, k, i
	real colvector col
	real matrix out

	nrow = rows(draws)
	ncol = cols(draws)
	out = J(ncol, 5, .)
	for (k=1; k<=ncol; k++) {
		col = sort(draws[.,k], 1)
		out[k,1] = col[1]
		out[k,2] = col[ceil(0.25*nrow)]
		out[k,3] = col[ceil(0.50*nrow)]
		out[k,4] = col[ceil(0.75*nrow)]
		out[k,5] = col[nrow]
	}
	return(out)
}
end
