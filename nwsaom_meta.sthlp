{smcl}
{* *! version 0.1.0  22oct2026}{...}
{vieweralsosee "nwsaom" "help nwsaom"}{...}
{title:Title}

{phang}
{bf:nwsaom_meta} {hline 2} Multi-group meta-analysis of separate {cmd:nwsaom} fits (RSiena's {cmd:siena08}){p_end}

{title:Syntax}

{p 8 16 2}
{cmd:nwsaom_meta} {it:name1 name2} [{it:name3} ...] [{cmd:,} {opt bound(#)} {opt alpha(#)} {opt maxit(#)} {opt rates} {opt notable}]{p_end}

{pstd}
{it:name1 name2 ...} are stored estimates ({cmd:estimates store}) of the {it:same} {cmd:nwsaom} model fitted to several networks (groups, for example school classes): same effects in the same order.

{title:Options}

{phang}{opt bound(#)} excludes group estimates with a standard error of at least # (default 10), as RSiena.{p_end}
{phang}{opt alpha(#)} the level of the profile-likelihood intervals (default 0.05).{p_end}
{phang}{opt maxit(#)} maximum number of IWLS iterations (default 20).{p_end}
{phang}{opt rates} also combines the rate parameters ({cmd:e(rates)}, one per period; the standard errors of conditional fits are not comparable).{p_end}
{phang}{opt notable} suppresses the output; the results are in {cmd:r()}.{p_end}

{title:Description}

{pstd}
For every effect {cmd:nwsaom_meta} combines the group estimates {it:theta_j} and standard errors {it:s_j} as {cmd:siena08} (Snijders and Baerveldt 2003): the robust IWLS random-effects mean with its t test and
the estimated between-group standard deviation, the heterogeneity test Q, Fisher's combination of the one-sided tests, and the maximum likelihood estimates of the mean and the between-group standard deviation
under normality with profile-likelihood confidence intervals. The Mata port reproduces RSiena's numbers (checked on made-up estimates to five decimals).
The correlation between estimates and standard errors (a diagnostic for bias) is Spearman's rho with the usual t approximation for its p value (RSiena uses the exact/Edgeworth p value).

{title:Stored results}

{synoptset 16 tabbed}{...}
{synopt:{cmd:r(meta)}}effects x 24 matrix: n_used, corr, corr_p, iwls_mean, iwls_se, iwls_t, iwls_p, iwls_sd, Tsq, Tsq_p, Q, Q_p, ml_mean, ml_se, mu_lo, mu_hi, ml_sd, sd_lo, sd_hi, fisher_right, fisher_right_p, fisher_left, fisher_left_p, level{p_end}
{synopt:{cmd:r(theta)}, {cmd:r(se)}}groups x effects estimates and standard errors{p_end}
{synopt:{cmd:r(groups)}}number of groups{p_end}

{title:Example}

{phang2}{cmd:. nwsaom, waves(c1a c1b) outdegree reciprocity transtrip}{p_end}
{phang2}{cmd:. estimates store class1}{p_end}
{phang2}{cmd:. nwsaom, waves(c2a c2b) outdegree reciprocity transtrip}{p_end}
{phang2}{cmd:. estimates store class2}{p_end}
{phang2}{cmd:. nwsaom_meta class1 class2 class3}{p_end}

{title:Reference}

{pstd}Snijders, T.A.B. and Baerveldt, C. (2003). A multilevel network study of the effects of delinquent behavior on friendship evolution. {it:Journal of Mathematical Sociology} 27: 123-151.{p_end}
