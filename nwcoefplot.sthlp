{smcl}
{* *! version 1.0.0  20nov2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_statmodels:[NW-2.6.7] Statistical tests}

{title:Title}

{p2colset 9 23 25 2}{...}
{p2col :nwcoefplot {hline 2}}Coefficient plot of network model results{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:nwcoefplot} [{it:namelist}] [{cmd:,} {it:options}]

{pstd}
{it:namelist} holds names of results saved with {helpb estimates store}; a period ({cmd:.}) stands for the active estimation results, which is also what is plotted without a list. Up to eight models are drawn side by side.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt l:evel(#)}}confidence level; default is {cmd:c(level)}, normally 95{p_end}
{synopt:{opt keep(patterns)}}plot only the coefficients that match; the patterns also set their order{p_end}
{synopt:{opt drop(patterns)}}leave out the coefficients that match{p_end}
{synopt:{opt nocons:tant}}leave out {cmd:_cons}{p_end}
{synopt:{opt ef:orm}}exponentiate: odds ratios or rate ratios; the reference line is 1 on a log scale{p_end}
{synopt:{opt byeq}}one panel for each equation (the default when there is more than one equation){p_end}
{synopt:{opt mixeq}}all equations on one axis, labelled {it:eq}{cmd::}{it:name}{p_end}
{synopt:{opt common}}with several models: only the coefficients that all models have{p_end}
{synopt:{opt skip:missing}}leave out models without {cmd:e(b)} and {cmd:e(V)} instead of stopping{p_end}
{synopt:{opt msy:mbol(symbols)}}marker symbol for each model, in the order of the models (for example {cmd:msymbol(O D T)}); symbols are used again from the start when there are fewer than models; default is a circle for all{p_end}
{synopt:{opt ti:tle(string)}}title of the graph{p_end}
{synopt:{opt name(name[, replace])}}name of the graph in memory; default {cmd:coefplot}; an existing graph is replaced{p_end}
{synopt:{opt sav:ing(filename[, replace])}}save the graph to a {cmd:.gph} file; an existing file is replaced{p_end}
{synopt:{opt exp:ort(filename[, options])}}write the graph with {helpb graph export}; an existing file is replaced{p_end}
{synopt:{it:twoway_options}}other options of {helpb twoway}, applied to each panel; they come last, so {opt xscale()} and {opt xlabel()} replace the default axis; the size options {opt xsize()},
{opt ysize()}, {opt aspectratio()} and {opt scale()} replace the default size (with {opt byeq} or {opt mixeq} across several panels they apply to the combined graph){p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:nwcoefplot} draws point estimates with confidence intervals of the coefficients in {cmd:e(b)} and {cmd:e(V)} of the last estimation or of stored results. It works after {helpb nwsaom}, {helpb nwergm},
{helpb nwdynam}, {helpb nwrem}, {helpb nwalaam}, {helpb nwlsm} and after any other command that leaves {cmd:e(b)} and {cmd:e(V)}. The coefficients are labelled with their names. The intervals are {it:b}
{c +-} {it:z} se, with a {it:t} quantile when the command stores {cmd:e(df_r)}. For {cmd:nwlsm} the coefficients are posterior means with posterior standard deviations, so the intervals are normal approximations;
the credible intervals of the fit are in the output of {helpb nwlsm}. Coefficients that were omitted or have no variance are not drawn.

{pstd}
Equations are never mixed on one axis unless {opt mixeq} is given: a model with several equations (for example the network and outcome equations of {cmd:nwlsm} with {opt influence()}) gets one panel for
each, with its own scale. The axis of a panel always contains all intervals and the reference line (0, or 1 with {opt eform}), with a margin; with {opt eform} the axis is logarithmic and labelled at 1,
2, 5 times powers of ten.

{pstd}
{opt eform} gives odds ratios after {cmd:nwergm}, {cmd:nwalaam} and {cmd:nwlsm} with the Bernoulli or binomial family, and rate ratios after {cmd:nwdynam} and {cmd:nwrem} (and after {cmd:nwlsm} with the
Poisson family). It is refused for {cmd:nwsaom} and {cmd:nwsbm}, whose parameters are not log odds or log rates; in the outcome equation of {cmd:nwlsm} the coefficients stay on their own scale. For other
commands the axis reads "Exponentiated coefficient".

{pstd}
{opt keep()} and {opt drop()} take coefficient names or patterns with {cmd:*} and {cmd:?}. A pattern is compared with the name ({cmd:edges}, {cmd:gwesp*}) and with {it:eq}{cmd::}{it:name} ({cmd:network:*}).
The order of the {opt keep()} patterns is the order of the coefficients from top to bottom.

{pstd}
With a list of models the coefficients of different models are drawn in one row in different colours, with a legend; {cmd:nwcompare, graph} calls this for the fit table.
For a black-and-white print give each model its own marker with {opt msymbol()}, for example {cmd:msymbol(O D T)} for three models (circle, diamond, triangle; hollow
forms are {cmd:Oh Dh Th Sh}); at most one symbol per model is allowed, and a symbol that is not a Stata marker symbol name stops the command with r(198).

{title:Examples}

{phang2}{cmd:. nwergm flomarriage, edges gwesp(.5)}{p_end}
{phang2}{cmd:. nwcoefplot, eform title("ERGM of the marriage network")}{p_end}

{phang2}{cmd:. nwergm flomarriage, edges triangle}{p_end}
{phang2}{cmd:. estimates store m0}{p_end}
{phang2}{cmd:. nwergm flomarriage, edges gwesp(.5)}{p_end}
{phang2}{cmd:. estimates store m1}{p_end}
{phang2}{cmd:. nwcoefplot m0 m1, keep(edges) export(coefs.png, width(1200))}{p_end}

{phang2}{cmd:. nwcoefplot m0 m1, msymbol(O D) export(coefs_gray.png, width(1200))}{p_end}

{phang2}{cmd:. nwlsm advice, dim(2) influence(belief2 belief1 tenure) neighbors(10)}{p_end}
{phang2}{cmd:. nwcoefplot, noconstant}{p_end}

{title:Stored results}

{pstd}
{cmd:nwcoefplot} stores in {cmd:r()}:

{synoptset 18 tabbed}{...}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(n_coef)}}number of plotted estimates (coefficients times models){p_end}
{synopt:{cmd:r(n_panels)}}number of panels{p_end}
{synopt:{cmd:r(n_models)}}number of models{p_end}
{synopt:{cmd:r(models)}}names of the models{p_end}

{title:Also see}

{pstd}
{help nwcompare}, {help nwergm}, {help nwsaom}, {help nwdynam}, {help nwrem}, {help nwalaam}, {help nwlsm}, {help estimates}

{hline}
{pstd}{it:nwcommands version 3.32.0, 20 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
