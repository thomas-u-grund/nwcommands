{smcl}
{* *! version 1.1.0  21nov2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_statmodels:[NW-2.6.7] Statistical tests}

{title:Title}

{p2colset 9 22 24 2}{...}
{p2col :nwcompare {hline 2}}Compare the fit statistics of stored network models{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:nwcompare} [{it:namelist}] [{cmd:,} {opt sort(criterion)} {opt graph} {opt name(name)} {opt saving(filename)} {opt export(filename[, options])} {opt coefopts(options)}]

{pstd}
{it:namelist} holds names of results saved with {helpb estimates store}; a period ({cmd:.}) stands for the active estimation results. Without a list, all stored results are shown.

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt sort(criterion)}}order the rows by {cmd:aic}, {cmd:bic}, {cmd:icl} (smallest first) or {cmd:ll} (largest first); default: the order of the list{p_end}
{synopt:{opt graph}}also draw the coefficients of the models side by side with {helpb nwcoefplot}; {opt plot} is a synonym{p_end}
{synopt:{opt name(name)}}name of the graph in memory; default {cmd:compare}{p_end}
{synopt:{opt sav:ing(filename)}}save the graph to a {cmd:.gph} file{p_end}
{synopt:{opt exp:ort(filename[, options])}}write the graph with {helpb graph export}{p_end}
{synopt:{opt coefopts(options)}}options passed to {helpb nwcoefplot}, for example {cmd:keep()} or {cmd:eform}{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:nwcompare} lists, one row per model, the number of observations {it:N}, the log likelihood, the number of parameters {it:k}, and the criteria AIC, BIC and ICL, as stored by {helpb nwergm},
{helpb nwsaom}, {helpb nwlsm}, {helpb nwsbm}, {helpb nwalaam} and by Stata's own estimation commands. A statistic that a model does not provide is shown as a period.

{pstd}
What is shown for each command:

{phang2}{cmd:nwergm}: {cmd:e(ll)}, {cmd:e(aic)}, {cmd:e(bic)} as stored; {it:k} is {cmd:e(df_m)}, the number of coefficients.{p_end}
{phang2}{cmd:nwergm}, dyad dependence: the log likelihood is estimated by bridge sampling or is a pseudolikelihood; a note under the table says which.{p_end}
{phang2}{cmd:nwlsm}: the posterior mean of the log likelihood, {cmd:e(ll_mean)}; no AIC or BIC, because the fit is Bayesian; {it:k} is the number of coefficients in {cmd:e(b)} (the latent positions are not counted).{p_end}
{phang2}{cmd:nwsbm}: the expected complete-data log likelihood {cmd:e(PL)} and the integrated classification likelihood {cmd:e(ICL)}; {it:N} is the number of actors; AIC and BIC are not shown.{p_end}
{phang2}{cmd:nwsbm}, {it:k}: {cmd:e(npar)} (block parameters, covariate coefficients, a Gaussian variance) plus the free membership proportions, {it:Q} - 1 for {it:Q} blocks ({it:Q1} - 1 plus {it:Q2} - 1 for two modes), as in the ICL penalty.{p_end}
{phang2}{cmd:nwdynam}, {cmd:nwrem}: {cmd:e(ll)}; {it:k} is {cmd:e(df_m)} when the command stores it ({cmd:nwrem}), otherwise the number of coefficients in {cmd:e(b)}; AIC and BIC as stored, or computed from the log likelihood.{p_end}
{phang2}{cmd:nwsaom}, {cmd:nwalaam}: these estimators (method of moments, Monte Carlo) do not store a likelihood, so only {it:N} and {it:k}, the number of coefficients in {cmd:e(b)}, appear.{p_end}
{phang2}Other estimation commands: {cmd:e(ll)}, {cmd:e(aic)}, {cmd:e(bic)}; {it:k} is {cmd:e(rank)}, else {cmd:e(df_m)}, else the number of coefficients; AIC and BIC are computed from the log likelihood when not stored.{p_end}

{title:Remarks}

{pstd}
Criteria from different model families are not always comparable. An ERGM is a likelihood for the {it:N} dyads, a latent space model with a posterior mean log likelihood is not a maximised likelihood,
and the block model's PL and ICL refer to the actors and include the memberships. Compare AIC and BIC between models of the same family fitted to the same network (for example several {cmd:nwergm}
specifications, or several numbers of blocks), and treat a comparison across families as a rough guide at most. {cmd:nwcompare} prints a note when the rows differ in {it:N} or in the network.

{pstd}
{cmd:nwsbm} stores no coefficient vector, so {cmd:estimates store} cannot keep its results: list them with the period, as the active results. Restoring another model afterwards replaces them, so fit
the block model last, or call {cmd:nwcompare} again after fitting it.

{pstd}
With {opt graph}, {cmd:nwcompare} adds a graph of the coefficients (point estimates with confidence intervals, one colour for each model) of the models that have a coefficient vector, restricted to the
coefficients that all of them share by name; the sample models in the example below share {cmd:edges}. Models of different kinds that share no coefficient give a note instead of a graph.

{title:Examples}

{phang2}{cmd:. nwergm flomarriage, edges}{p_end}
{phang2}{cmd:. estimates store m0}{p_end}
{phang2}{cmd:. nwergm flomarriage, edges gwesp(.5)}{p_end}
{phang2}{cmd:. estimates store m1}{p_end}
{phang2}{cmd:. nwcompare m0 m1, sort(bic)}{p_end}

{phang2}{cmd:. nwcompare m0 m1, graph coefopts(eform)}{p_end}
{phang2}{cmd:. nwcompare m0 m1, graph export(compare.png, width(1200))}{p_end}

{phang2}{cmd:. nwsbm flomarriage, maxblocks(4) seed(1)}{p_end}
{phang2}{cmd:. nwcompare m0 m1 .}{p_end}

{title:Stored results}

{pstd}
{cmd:nwcompare} stores in {cmd:r()}:

{synoptset 18 tabbed}{...}
{synopt:{cmd:r(table)}}matrix with one row per model and the columns {cmd:N}, {cmd:ll}, {cmd:k}, {cmd:aic}, {cmd:bic}, {cmd:icl}{p_end}
{synopt:{cmd:r(names)}}names of the models{p_end}
{synopt:{cmd:r(commands)}}estimation commands of the models{p_end}

{title:Also see}

{pstd}
{help nwcoefplot}, {help nwergm}, {help nwsaom}, {help nwlsm}, {help nwsbm}, {help nwalaam}, {help estimates}

{hline}
{pstd}{it:nwcommands version 3.34.0, 21 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
