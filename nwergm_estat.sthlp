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
in the final MCMC sample - the same pair of diagnostic plots R's {cmd:mcmc.diagnostics()}
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
distance ({helpb nwgeodesic}), and the count of complete (3-edge) triads ({helpb nwtriads}).
{opt nsim()} simulated networks are drawn by continuing the Markov chain from wherever
{cmd:nwergm}'s own fit left it (for {opt method(mcmle)}) or from the observed network itself
(for {opt method(mple)}, which never runs MCMC during estimation), recording one snapshot every
{opt gofinterval()} steps.

{pstd}
{bf:This is a BASIC check, not a formal test.} A large, systematic gap between the Observed and
Simulated columns on any row is evidence against the fitted model; rough agreement is evidence
for it, not proof. A simulated network that happens to be disconnected or edgeless does not
contribute to the geodesic/triad-census averages respectively (reported in the output) rather
than being treated as an error.

{pstd}
{opt plot} additionally draws the full degree distribution and the full geodesic-distance
distribution - not just their means - across the {opt nsim()} simulated draws, each as its own
panel: a whisker (minimum-maximum), a box (interquartile range), and a median marker summarize
the simulated draws at each value, with the observed network's own proportion overlaid as a
connected line. This is the same comparison Statnet's {cmd:plot(gof())} draws (via R's
{cmd:boxplot()} rather than these {cmd:graph twoway} primitives), restricted to the two
dimensions {cmd:estat gof} already computes a mean for - it does not add an edgewise
shared-partner panel, the third dimension Statnet's own default GOF plot includes.
{opt maxdeg()} caps the degree axis (values above it are pooled into a single "{it:maxdeg}+"
category); {opt maxdist()} similarly caps the geodesic-distance axis (unreached pairs, including
disconnected ones, are pooled into their own "NR" - not reached - category, matching Statnet's
own convention). {opt name()} sets the combined graph's name; default {cmd:gof}.

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

