{smcl}
{* *! version 1.0.0  23oct2026 author: Thomas Grund}{...}
{vieweralsosee "nwergm" "help nwergm"}{...}
{vieweralsosee "nwergm postestimation" "help nwergm_estat"}{...}
{title:Title}

{p2colset 9 31 32 2}{...}
{p2col :nwergm estimation methods {hline 2}}Estimation methods, controls, simulation and diagnostics of {helpb nwergm}{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:nwergm} [{it:netname}]{cmd:,} {opt edges} [{it:terms}]
[{opt estimate(mle|mple|cd)} {opt mainmethod(mcmle|sa)} {opt mpletype(glm|penalized)} {opt mplecheck(on|off)} {opt mplecovariance(invhess|godambe|bootstrap)} {opt init(numlist)} {it:mcmle controls}]

{p 8 17 2}
{cmd:nwergm simulate} [{cmd:,} {opt nsim(#)} {opt output(network|stats|edgelist)} {opt basis(netname)} {opt nosequential} {opt seed(#)} {opt burnin(#)} {opt interval(#)} {opt coef(matname)} {opt generate(name)} {opt clear}]

{p 8 17 2}
{cmd:estat gof} [{cmd:,} {opt gof(statistics)} {opt nsim(#)} {opt seed(#)} {opt gofburnin(#)} {opt gofinterval(#)} {opt plot}]

{title:Description}

{pstd}
The options below follow the arguments of R's {cmd:ergm()} and {cmd:control.ergm()}; the names of the R arguments are given in
parentheses.

{title:Estimation method}

{phang}
{opt estimate(mle|mple|cd)} ({cmd:estimate=}) chooses the estimator. {cmd:mle} (the default) is the maximum pseudolikelihood fit for dyad-independent models and Monte Carlo maximum likelihood otherwise,
{cmd:mple} is the maximum pseudolikelihood estimate and {cmd:cd} is contrastive divergence (CD.nsteps proposals from the observed network per draw, started from zeros; the
covariance in {cmd:e(V)} is that of the CD sample, R reports it as missing). {cmd:method(mple|mcmle|cd)} is the older spelling.

{phang}
{opt mainmethod(mcmle|sa)} ({cmd:main.method=}) chooses the Monte Carlo algorithm: Monte Carlo maximum likelihood or Stochastic-Approximation
(Snijders 2002: phase 1 gain estimation, four phase-2 sub-phases, a phase-3 sample and a Newton step). Options {opt saburnin()}, {opt sainterval()}, {opt saphase3()}, {opt sagain()} and {opt sansub()}
set SA.burnin, SA.interval, SA.phase3_n, SA.initial_gain and SA.nsubphases.

{phang}
{opt init(numlist)} ({cmd:control.ergm(init=)}) gives one value per coefficient, in the order of the coefficient table; {cmd:.} or {cmd:NA} leaves a value to be estimated. Values for
{opt offset()} coefficients replace those of {opt offset()}; other values are starting values for the Monte Carlo fit (and are held fixed in the pseudolikelihood step that finds the missing ones). If every
value is given the pseudolikelihood start is skipped. With {cmd:estimate(mple)} only the offset values are used.

{title:Maximum pseudolikelihood}

{phang}
{opt mpletype(glm|penalized)} ({cmd:MPLE.type=}) {cmd:penalized} is the Firth (Jeffreys-prior) penalised fit, which is finite when the ordinary MPLE does not exist. It cannot be combined with {opt offset()}.

{phang}
{opt mplecheck(on|off)} ({cmd:MPLE.check=}) tests whether the MPLE exists (Konis 2007, a linear programme solved by a simplex routine). If it does not, {cmd:nwergm} warns {cmd:The MPLE does not exist!}
and, with {cmd:estimate(mple)}, reports the iterate of R's {cmd:glm()} (huge coefficients, standard errors in the thousands), as R does. With {cmd:mplecheck(off)} the {cmd:glm()} iterate is reported without the test.

{phang}
{opt mplecovariance(invhess|godambe|bootstrap)} ({cmd:MPLE.covariance.method=}) replaces the inverse-Hessian covariance of a pseudolikelihood fit of a dyad-dependent model by the Godambe sandwich or the bootstrap covariance from
500 networks simulated at the MPLE (burn-in 1024, interval 1024).

{title:Monte Carlo maximum likelihood controls}

{phang}
{opt mcmleiterations(#)} ({cmd:MCMLE.maxit}, default 60), {opt mcmleconfidence(#)} ({cmd:MCMLE.confidence}, 0.99), {opt mcmletermination(confidence|hummel|hotelling|none)} ({cmd:MCMLE.termination}),
{opt mcmlesteplength(#)} and {opt mcmlestepmargin(#)} ({cmd:MCMLE.steplength}, {cmd:MCMLE.steplength.margin}; margin {cmd:.} switches the Hummel step length off), {opt mcmleeffectivesize(#)} ({cmd:MCMLE.effectiveSize}),
{opt mcmcburnin()}, {opt mcmcinterval()} and {opt mcmcsamplesize()} ({cmd:MCMLE.burnin}, {cmd:MCMLE.interval}, {cmd:MCMLE.samplesize}).
{cmd:hummel} and {cmd:hotelling} stop after the criterion has held in two successive iterations, the sample size being raised by {cmd:MCMLE.last.boost} (4) after the first; {cmd:none} runs all iterations.
Contrastive divergence uses {opt cdnsteps()} (CD.nsteps, 8), {opt cdsamplesize()} (default CD.samplesize.per_theta = 128 times the number of free coefficients) and {opt mcmleiterations()} for CD.maxit.
If the statistics of the sample do not vary at all the fit stops with the error of R: unconstrained MCMC sampling did not mix at all.

{title:nwergm simulate}

{pstd}
Without a number of nodes, {cmd:nwergm simulate} draws from the model of the last {cmd:nwergm} fit (R {cmd:simulate.ergm()}), starting from the last network of the fit or from {opt basis()}, at the
fitted coefficients or at {opt coef()}. The chain is sequential (burn-in once, {opt interval()} proposals between draws) unless {opt nosequential} restarts every draw from the starting network.
{opt output(network)} creates networks {it:generate}_1, {it:generate}_2, ...; {opt output(stats)} returns the statistics in {cmd:r(stats)}; {opt output(edgelist)} replaces the data with
variables {cmd:_sim _tail _head} (specify {opt clear}). The constraints of the fit (dyad restrictions, fixed density) stay in force.

{title:estat gof}

{pstd}
{cmd:estat gof} follows {cmd:gof.ergm()}: the fit is simulated {opt nsim()} times (default 100, burn-in and interval of the fit, the interval rescaled by sample size / nsim as in R) and for each statistic the observed value,
the minimum, mean and maximum of the simulations and the Monte Carlo p-value 2 min(P(sim >= obs), P(sim <= obs)) are shown; rows that are zero throughout are left out. {opt gof(statistics)} chooses among
{cmd:degree idegree odegree b1degree b2degree espartners dspartners distance triadcensus model} (a minus sign drops {cmd:model}); the default is the R default for the type of network. The tables are returned
in {cmd:r(gof_}{it:statistic}{cmd:)}. The earlier summary values ({cmd:r(obs_meandeg)}, {cmd:r(sim_avgpath)}, {cmd:r(obs_triad_}{it:cat}{cmd:)} ...) are still returned.

{title:estat mcmcdiag}

{pstd}
After the summary of the final sample, {cmd:estat mcmcdiag} prints the report of {cmd:mcmc.diagnostics()}: mean, standard deviation, naive and time-series standard error and quantiles of the centered
statistics, the test that the sample statistics differ from the observed ones (with the Hotelling omnibus test), cross-correlations, autocorrelations at lags of {cmd:interval} proposals, and the Geweke
statistic with individual and joint p-values. The matrices are returned in {cmd:r(mc_summary)}, {cmd:r(mc_quantiles)}, {cmd:r(mc_obstest)}, {cmd:r(mc_crosscorr)}, {cmd:r(mc_autocorr)} and {cmd:r(mc_geweke)}.

{title:References}

{phang}
Hummel, R. M., Hunter, D. R. and Handcock, M. S. 2012. Improving simulation-based algorithms for fitting ERGMs. {it:Journal of Computational and Graphical Statistics} 21: 920-939.{p_end}
{phang}
Konis, K. 2007. {it:Linear Programming Algorithms for Detecting Separated Data in Binary Logistic Regression Models}. DPhil thesis, University of Oxford.{p_end}
{phang}
Snijders, T. A. B. 2002. Markov chain Monte Carlo estimation of exponential random graph models. {it:Journal of Social Structure} 3(2).{p_end}
