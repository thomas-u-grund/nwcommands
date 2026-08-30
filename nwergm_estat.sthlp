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
{cmd:estat mcmcdiag} {opt [, PLOT NAME(string) PVALUE(real 0.05) EPS(real 0.1)]}

{pstd}
{cmd:estat mcmcdiag} reports diagnostics for the final MCMC simulation {cmd:nwergm} ran
at its converged (or last-tried) coefficient vector: per-statistic mean, standard deviation,
lag-1 autocorrelation, and an AR(1)-based effective sample size; the Geweke (1992) z-score and
the Heidelberger-Welch (1983) stationarity/halfwidth test (the two formal convergence hypothesis
tests behind R {cmd:ergm}'s own {cmd:mcmc.diagnostics()}, via its {cmd:coda} package
dependency); plus the overall Metropolis-Hastings acceptance rate and {cmd:nwergm}'s own MCMLE
convergence-test result. Available only after {opt method(mcmle)} - a pure MPLE fit involves no
MCMC simulation at all, so there is nothing to diagnose.

{pstd}
{bf:This command never claims a fit converged merely because estimation stopped.} A satisfied
convergence test is reported as exactly that - a necessary check that passed, not a proof of
global convergence - and low ESS, low acceptance rate, high autocorrelation, a large Geweke
{bf:z}, or a failed Heidelberger-Welch stationarity test are all signs worth investigating even
when {cmd:e(converged)} is 1.

{pstd}
{bf:Geweke's diagnostic} compares the mean of the first 10% of the retained sample against the
mean of the last 50%, each corrected for autocorrelation via the same AR(p) spectral-density
estimator {cmd:nwergm}'s own final variance estimate uses. {bf:|z| > 1.96} (flagged with a
{bf:*}) rejects convergence of that parameter's own chain at the 5% level.

{pstd}
{bf:The Heidelberger-Welch test} first checks STATIONARITY: whether a Cramer-von-Mises test on
the chain's own cumulative-sum path passes once an increasing initial fraction (up to 50%) is
discarded - {bf:Start} reports the first retained iteration once it does; {bf:FAILED} means no
discard fraction achieved it. {opt pvalue()} sets the significance level and must be one of
{bf:0.10}, {bf:0.05} (the default), {bf:0.025}, or {bf:0.01} - the test is evaluated against a
fixed table of Cramer-von-Mises critical values at these four levels (each solved directly from
the real {cmd:coda} package's own {cmd:pcramer()} CDF, not approximated), rather than a
continuously computed p-value; see {cmd:unw_ergm.do}'s own header comment above
{cmd:ergm_heidel_diag()} for why. Only once stationarity passes does the HALFWIDTH test run: the
retained portion's own 95% CI halfwidth must be within {opt eps()} (default 10%) of its own
mean - a separate, stricter precision check.

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

{title:Examples}

{pstd}
Fit a dyad-dependent {help nwergm} model ({opt method(mcmle)} runs automatically whenever any
dyad-dependent term like {opt gwesp()} is present), then check MCMC diagnostics and basic
goodness of fit:

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwergm flomarriage, edges gwesp(.5)}
	{cmd:. estat mcmcdiag}
	{cmd:. estat gof, nsim(50)}

{title:Stored results}

{pstd}
{cmd:estat mcmcdiag} stores the following in {cmd:r()}:

	Scalars
	  {bf:r(acceptrate)}		Metropolis-Hastings acceptance rate over the final simulation

	Matrices
	  {bf:r(geweke)}		1 x {it:p} row vector of Geweke z-scores, one per model term (same
	                    column order as {bf:e(b)})
	  {bf:r(heidel)}		{it:p} x 6 matrix, one row per model term, columns
	                    {bf:stest} (1/0, stationarity test passed), {bf:start} (first retained
	                    iteration, missing if {bf:stest}=0), {bf:teststat} (the retained window's
	                    own Cramer-von-Mises statistic), {bf:htest} (1/0, halfwidth test passed,
	                    missing if {bf:stest}=0), {bf:mean} and {bf:halfwidth} of the retained
	                    window (both missing if {bf:stest}=0)

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

