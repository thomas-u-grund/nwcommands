{smcl}
{* *! version 0.2.0  23oct2026}{...}
{vieweralsosee "nwsaom" "help nwsaom"}{...}
{vieweralsosee "nwsaom_estat" "help nwsaom_estat"}{...}
{vieweralsosee "nwsaom_meta" "help nwsaom_meta"}{...}
{title:Title}

{phang}
{bf:nwsaom bayes} {hline 2} Bayesian estimation of a stochastic actor-oriented model, following multiSiena's {cmd:multi_siena()} (the successor of RSiena's {cmd:sienaBayes}) for a single group{p_end}

{title:Syntax}

{p 8 16 2}
{cmd:nwsaom bayes} [{cmd:,} {it:options}]{p_end}

{pstd}
{cmd:nwsaom bayes} is run after {cmd:nwsaom} and samples the posterior distribution of the model that was just fitted (same network waves, same effects, covariates included). It can also be called as {cmd:nwsaom_bayes}.
The fitted model must be one directed one-mode network, with or without one co-evolving behavior, without endowment/creation effects, rate covariates, structural zeros, missing-data or composition-change options, and the native plugin must be installed.
The estimates of the {cmd:nwsaom} fit are the starting values and its covariance matrix gives the proposal distribution for the effects.

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt nprewarm(#)}}pre-warming iterations, default 50{p_end}
{synopt:{opt nwarm(#)}}warming iterations, default 50{p_end}
{synopt:{opt nmain(#)}}main iterations (one draw is saved per iteration), default 250{p_end}
{synopt:{opt nrunmh(#)}}batches per iteration, default 20 (the draw saved is the state after the last batch of the iteration){p_end}
{synopt:{opt nimprovemh(#)}}batches per round of tuning of the proposal scale factors (twice: before and after the warming), default 100{p_end}
{synopt:{opt mhgeom(#)}}draw the position of the second ministep of an inserted pair from a truncated geometric distribution with this ratio (between 0 and 1) instead of uniformly (the default 0 is the uniform choice of RSiena);
shorter blocks are cheaper but mix the length of the sequence more slowly{p_end}
{synopt:{opt targetmh(#)}}target acceptance probability, default 0.25{p_end}
{synopt:{opt mult(#)}}the number of Metropolis-Hastings steps on the unobserved sequence of ministeps per batch and period is {opt mult()} times the observed number of tie changes (rounded to hundreds above 100), default 5{p_end}
{synopt:{opt nmh(#)}}that number given directly{p_end}
{synopt:{opt nsampconst(#)}}proposals for the effects per batch, default 1 ({cmd:0} keeps the effects fixed){p_end}
{synopt:{opt nsamprates(#)}}additional proposals for the rates per batch, default 0{p_end}
{synopt:{opt priormeaneta(numlist)}, {opt priorsigeta(numlist)}}normal prior of the effects: means (default 0) and variances; without {opt priorsigeta()} the prior is flat{p_end}
{synopt:{opt ratepriormean(numlist)}, {opt ratepriorsd(#)}}normal prior of the rates: means (default: the rates of the fit) and standard deviation (default 1; {cmd:0} = flat){p_end}
{synopt:{opt gibbsrates}, {opt priorrate(# #)}}draw the rates from their gamma full conditional (shape and rate of the prior, default flat) instead of a Metropolis step{p_end}
{synopt:{opt fixrates}}keep the rates at their starting values{p_end}
{synopt:{opt theta0(numlist)}, {opt rate0(numlist)}}starting values (default: the fit){p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt frame(name)}}frame for the draws, default {cmd:nwsaom_bayes_draws}{p_end}
{synopt:{opt level(#)}}credible interval level, default 95{p_end}
{synopt:{opt notable}, {opt noheader}}display control{p_end}
{synoptline}

{title:Description}

{pstd}
The unobserved sequence of ministeps between two waves (who considered which tie change, including ministeps without a change) is part of the state of the sampler, as in the maximum likelihood estimation of Snijders, Koskinen and Schweinberger (2010) and the Bayesian estimation of
Koskinen and Snijders (2007). The algorithm and its controls follow {cmd:multi_siena()} of the R package multiSiena (Snijders, Koskinen and Ripley) for one group. One batch consists of

{phang2}1. Metropolis-Hastings steps on the sequences of all periods: with probabilities 0.05, 0.05, 0.2, 0.3 and 0.3 insertion of a ministep without change, deletion of one, permutation of up to c0 consecutive ministeps, insertion of a pair of
ministeps that cancel (a tie toggled twice with no other toggle of that tie between) while permuting the ministeps in between, and deletion of such a pair with permutation; the remaining probability (0.1) belongs to the moves for missing data and does nothing here.
The permutation length c0 starts at 20, is adapted between 2 and 40 during the pre-warming and warming, and is then kept fixed;{p_end}
{phang2}2. one Metropolis proposal for the rates of all periods, from a normal distribution with the standard errors of the fit as scale, with a normal prior;{p_end}
{phang2}3. {opt nsampconst()} Metropolis proposals for the effects from a normal distribution with the covariance matrix of the fit (flat prior).{p_end}

{pstd}
The proposal scale factors start at 2.38^2 divided by the number of parameters and are tuned by rounds of {opt nimprovemh()} batches that leave the parameters unchanged, as multiSiena's {cmd:improveMH}, before and after the warming;
as in multiSiena the effects are tuned to twice {opt targetmh()} per half round.
The schedule is: pre-warming, tuning, warming, tuning, main run; only the main iterations are saved.

{pstd}
Differences from multi_siena: only one group is supported (no group-level mean and covariance matrix, no randomly varying effects, no hierarchical prior;
with one group multi_siena itself keeps the rate prior fixed at a normal distribution around the initial rate estimates with variance 1, which is the default here);
the starting values and proposal covariance come from the {cmd:nwsaom} fit (multi_siena first runs a short method-of-moments estimation of its own);
the Metropolis-Hastings steps were written from the published description of the algorithm and the probability of each proposal is derived and checked, the permutation length is kept fixed in the main run;
several behaviors, several networks, missing data, composition change, rate covariates, non-directed and two-mode models are not available. The posterior of the effects is, for a flat prior, close to the maximum likelihood estimate and its standard error.

{title:Remarks}

{pstd}
The draws are autocorrelated; check the effective sample sizes in the table and increase {opt nmain()} or {opt nrunmh()} when they are small. With a behavior the sequences also contain behavior ministeps (the actor changes the behavior by -1, 0 or +1;
their rates are separate parameters, {cmd:e(rates_beh)}) and the permuted blocks and inserted pairs follow the rules of RSiena's maximum likelihood chain for behavior. The sampler is slower than the method of moments; {opt mult()} larger than 5 slows it further but mixes better.

{title:Stored results}

{synoptset 24 tabbed}{...}
{synopt:{cmd:e(b)}, {cmd:e(V)}}posterior means and covariance matrix of the effects{p_end}
{synopt:{cmd:e(rates)}}2 x periods: posterior mean and standard deviation of the rates{p_end}
{synopt:{cmd:e(interval)}}3 x (effects + rates): lower limit, median, upper limit{p_end}
{synopt:{cmd:e(ess)}}effective sample sizes{p_end}
{synopt:{cmd:e(post_frame)}}name of the frame with the draws: {cmd:b1}...{cmd:b}K (effects), {cmd:rate1}..., {cmd:nchain} (total number of ministeps), {cmd:loglik} (log-likelihood of the sequences){p_end}
{synopt:{cmd:e(accept_effects)}, {cmd:e(accept_rates)}}acceptance rates of the proposals in the main run{p_end}
{synopt:{cmd:e(accept_diag)}, {cmd:e(accept_permute)}, {cmd:e(accept_insperm)}, {cmd:e(accept_delperm)}}acceptance rates of the steps on the sequences{p_end}
{synopt:{cmd:e(scale_effects)}, {cmd:e(scale_rates)}}tuned scale factors{p_end}
{synoptline}
The estimates of {cmd:nwsaom} are replaced; use {cmd:estimates store} first to keep them.

{title:References}

{phang}Koskinen, J. H., and T. A. B. Snijders (2007). Bayesian inference for dynamic social network data. Journal of Statistical Planning and Inference 137: 3930-3938.{p_end}
{phang}Snijders, T. A. B., J. H. Koskinen, and M. Schweinberger (2010). Maximum likelihood estimation for social network dynamics. Annals of Applied Statistics 4: 567-588.{p_end}
