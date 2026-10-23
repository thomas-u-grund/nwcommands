{smcl}
{* *! version 0.1.0  23oct2026}{...}
{vieweralsosee "nwsaom" "help nwsaom"}{...}
{vieweralsosee "nwsaom_estat" "help nwsaom_estat"}{...}
{vieweralsosee "nwsaom_meta" "help nwsaom_meta"}{...}
{title:Title}

{phang}
{bf:nwsaom bayes} {hline 2} Bayesian estimation of a stochastic actor-oriented model (data augmentation and Metropolis-Hastings; the algorithm of RSiena's sienaBayes / multiSiena's multi_siena for a single group){p_end}

{title:Syntax}

{p 8 16 2}
{cmd:nwsaom bayes} [{cmd:,} {it:options}]{p_end}

{pstd}
{cmd:nwsaom bayes} is run after {cmd:nwsaom} and samples the posterior distribution of the model that was just fitted (same network waves, same effects). The command can also be called as {cmd:nwsaom_bayes}.
The fitted model must be one directed one-mode network without a co-evolving behavior, without endowment/creation effects, rate covariates, structural zeros, missing-data or composition-change options, and the native plugin must be installed.
The estimates of the {cmd:nwsaom} fit are the starting values and their covariance matrix gives the starting proposal distribution.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt nprewarm(#)}}pre-warming iterations, default 50{p_end}
{synopt:{opt nwarm(#)}}warming iterations, default 50{p_end}
{synopt:{opt nmain(#)}}main iterations (one draw is saved per iteration), default 250{p_end}
{synopt:{opt nrunmh(#)}}batches per iteration, default 20 (the draw saved is the state after the last batch, so the draws are thinned by this number){p_end}
{synopt:{opt nimprovemh(#)}}iterations of re-tuning the proposal distribution after the warming, default 100{p_end}
{synopt:{opt mult(#)}}number of Metropolis-Hastings steps on the unobserved sequence of ministeps per batch and period is {opt mult()} times the observed number of tie changes, default 5{p_end}
{synopt:{opt nmh(#)}}the number of such steps given directly (overrides {opt mult()}){p_end}
{synopt:{opt nsampconst(#)}}proposals for the effects per batch, default 1{p_end}
{synopt:{opt targetmh(#)}}target acceptance probability for the effects, default 0.25{p_end}
{synopt:{opt window(#)}}largest distance between the two ministeps of an inserted or deleted pair, default 10{p_end}
{synopt:{opt priormean(numlist)}}prior means of the effects (one value or one per effect), default 0{p_end}
{synopt:{opt priorsd(numlist)}}prior standard deviations of the effects; without it the prior of the effects is flat{p_end}
{synopt:{opt priorrate(# #)}}shape and rate of the gamma prior of the rate of every period; default {cmd:priorrate(1 0)}, a flat prior{p_end}
{synopt:{opt theta0(numlist)}, {opt rate0(numlist)}}starting values (default: the fit){p_end}
{synopt:{opt fixrates}}keep the rates at their starting values{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt frame(name)}}frame for the draws, default {cmd:nwsaom_bayes_draws}{p_end}
{synopt:{opt level(#)}}credible interval level, default 95{p_end}
{synopt:{opt notable}, {opt noheader}}display control{p_end}
{synoptline}

{title:Description}

{pstd}
The unobserved sequence of ministeps between two waves (who considered which tie change, including ministeps without a change) is treated as a parameter of the sampler, as in the maximum likelihood estimation of Snijders, Koskinen and Schweinberger (2010) and the Bayesian estimation of
Koskinen and Snijders (2007). One batch consists of Metropolis-Hastings steps on the sequences of all periods (insertion and deletion of a ministep without a change, insertion and deletion of a pair of ministeps that toggle the same tie, swapping two neighbouring ministeps),
then {opt nsampconst()} random-walk Metropolis proposals for the effects, then a draw of the rate of every period from its full conditional distribution (given the number of ministeps; gamma, flat prior by default).
During the pre-warming and warming the scale of the proposal distribution is tuned towards {opt targetmh()}; after the warming its covariance matrix is replaced by the covariance of the warming draws and tuned again for {opt nimprovemh()} iterations. The main iterations then keep it fixed.
The names and default values of the controls follow multiSiena's {cmd:set_algorithm_mcmc()}.

{pstd}
Differences from multiSiena's {cmd:multi_siena()}: only one group is supported (no hierarchical prior with a group-level mean and covariance matrix, no randomly varying effects); the effects have a flat prior unless {opt priorsd()} is given; the rates have a gamma prior and are drawn directly instead of by a Metropolis step;
the proposal tuning is a stochastic-approximation update instead of the batch rule of {cmd:improveMH}; the Metropolis-Hastings steps on the sequence are the three kinds listed above and not the exact set of RSiena's maximum likelihood sampler.
The posterior is checked against enumeration of a small model (the expected number of ministeps) and against RSiena's maximum likelihood estimates for the Glasgow data, see {bf:Remarks}.

{title:Remarks}

{pstd}
With a flat prior and a large sample the posterior mean and standard deviation are close to the maximum likelihood estimate and its standard error; they are not the method of moments estimates (the rates in particular differ in scale from the conditional estimates).
The draws of the rates and of the length of the sequences are strongly autocorrelated; check the effective sample size in the table and increase {opt nmain()} or {opt nrunmh()} when it is small. The sampler is slower than the method of moments.

{title:Stored results}

{synoptset 24 tabbed}{...}
{synopt:{cmd:e(b)}, {cmd:e(V)}}posterior means and covariance matrix of the effects{p_end}
{synopt:{cmd:e(rates)}}2 x periods: posterior mean and standard deviation of the rates{p_end}
{synopt:{cmd:e(interval)}}3 x (effects + rates): lower limit, median, upper limit{p_end}
{synopt:{cmd:e(ess)}}effective sample sizes{p_end}
{synopt:{cmd:e(post_frame)}}name of the frame with the draws: {cmd:b1}...{cmd:b}K (effects), {cmd:rate1}..., {cmd:nchain} (total number of ministeps), {cmd:loglik} (log-likelihood of the sequences){p_end}
{synopt:{cmd:e(accept_effects)}, {cmd:e(accept_diag)}, {cmd:e(accept_pair)}, {cmd:e(accept_swap)}}acceptance rates{p_end}
{synoptline}
The estimates of {cmd:nwsaom} are replaced; use {cmd:estimates store} first to keep them.

{title:References}

{phang}Koskinen, J. H., and T. A. B. Snijders (2007). Bayesian inference for dynamic social network data. Journal of Statistical Planning and Inference 137: 3930-3938.{p_end}
{phang}Snijders, T. A. B., J. H. Koskinen, and M. Schweinberger (2010). Maximum likelihood estimation for social network dynamics. Annals of Applied Statistics 4: 567-588.{p_end}
