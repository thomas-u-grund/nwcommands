{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nwtopical##analysis_statmodels:[NW-2.6.6] Statistical Estimation of Networks}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwqap  {hline 2}}Multivariate QAP regression{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwqap} 
{it:{help netname:depnet}}
[{it:{help nwqap##independentvariables:indepvars}}]
, 
{opth permutations(int)}
{opt mode}({it:{help nwexpand##expand_mode:mode}})
{opt type(regcmd)}
{opt typeoptions(regoptions)}
{opt detail}
{opt save}({it:{help filename}})
{opth predict(newnetname)}
{opt plot}
{opt name(string)}



{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth permutations(int)}}number of QAP permutations; default = 500{p_end}
{synopt:{opt mode}({it:{help nwexpand##expand_mode:mode}})}modes for expanding variables to networks{p_end}
{synopt:{opt type}({it:{help nwqap##regcmd:regcmd}})}regression command to be used for dyad dataset; default = {it:logit}{p_end}
{synopt:{opt typeoptions(regoptions)}}options to be passed on to the regression command{p_end}
{synopt:{opt detail}}display details of regression results{p_end}
{synopt:{opt save}({it:{help filename}})}save coefficients from permutations in file{p_end}
{synopt:{opth predict(newnetname)}}store the fitted dyad-level values (from {bf:type()}'s own default prediction, e.g. Pr(y=1) for {bf:logit}/{bf:probit}, the fitted mean for {bf:regress}) as a new valued network{p_end}
{synopt:{opt plot}}Draw one histogram panel per coefficient (including the constant), each with a dashed reference line at the observed coefficient against its own {opt permutations()} null draws - the same comparison R's {bf:sna::plot.qaptest()} draws, generalized to every coefficient in the regression{p_end}
{synopt:{opt name(string)}}Name for the combined graph created by {opt plot}; default = {bf:qap}{p_end}
{synopt:{opt qapspp}}Use double semi-partialling (Dekker, Krackhardt & Snijders 2007) instead of the plain permutation p-value for every independent variable's own coefficient - see {help nwqap##qapspp:qapspp} below{p_end}


{title:Description}

{pstd}
MR-QAP is a multiple regression procedure used to assess the impact of independent variables 
upon a dependent variable. In standard regression techniques, the typical "unit of analysis" 
is an individual observation. In MR-QAP analysis, the unit of analysis is a dyad, a pair of individuals 
who may or may not have some sort of relation connecting them to one another.

{pstd}
{cmd:nwqap} reshapes a network to a dataset of edges/arcs. For example, a directed network with 10 nodes is 
transformed in a dataset with 90 dyads (selfloops are not permitted).

{pstd}
The dependent variable is {it:y_ij}, indicating the network relationship between nodes
{it:i} and {it:j}.{p_end} 
{marker independentvariables}{...}
{pstd}Independent variables can be other {help netname:networks} or normal {help varname:variables}.  
Normal variables are expanded to networks of the same size as the dependent network using 
{help nwexpand}. The default {bf:mode} is {bf:"same"} (see {help nwexpand##mode:here} for other modes.
When more than one {help varname} is specified as independent variable, different modes can be 
selected for each variable, e.g. {bf:mode(same dist invdist)} chooses mode {bf:"dist"} for the 
second {help varname} that appears as independent variable.{p_end}   
{marker regcmd}{...}
{pstd}
{cmd:nwqap} performs the regression specified in {bf:type()}, by default {help logit} regression
is choosen. But notice that any other type of regression can be used (e.g. {help probit}, {help xtmixed}).
Furthermore, options are passed on to the selected regression command with {bf:typeoptions()}.
This gives a lot of flexibility to perform dyad-level regression. For example instead of logistic 
regression one can use probit regression with option {it:asis}:

	{bf:nwqap glasgow2 glasgow1, type(probit) typeoptions(asis)} 

{pstd}
The raw output of this dyad-level regression is displayed with option {bf:detail}.

{pstd}
{opth predict(newnetname)} stores {bf:type()}'s own fitted dyad-level values - whatever statistic
that regression command's own default {help predict} reports (predicted probability for
{bf:logit}/{bf:probit}/{bf:cloglog}, the fitted linear mean for {bf:regress}, etc.) - as a new
valued network, e.g. for comparing predicted tie probabilities against the observed network as a
goodness-of-fit check. Captured from the one real (non-permuted), observed-data regression this
command already runs internally to obtain {bf:type()}'s own coefficients - not from any of the
{opth permutations(int)} null-model draws. The diagonal (excluded from estimation, like every
self-tie in this command's dyadic reshaping) is set to 0 in the resulting network. A name collision
with an existing network is handled the same non-destructive way every other network-creating
command in this package handles it (auto-renamed with a warning, unless {it:newnetname} is free).

{pstd}
Once a dataset is assembled and a regression is carried out, the resulting coefficients indicate 
the direction of the effect of independent variables upon the dependent variable. However, calculating 
the standard error of these coefficients has been shown to lead to biased results when autocorrelation 
exists - which occurs, for instance, when interpersonal relations determine individual behavior 
(Krackhardt 1988). 

{pstd}
Since this method is employed to test hypotheses that suggest interpersonal relations 
matter, a different significance test is needed. The second step of QAP regression, therefore, is to repeatedly permute rows and columns of the matrix representing the dependent variable and after each permutation to re-compute
regression coefficients. Indicators of statistical significance report the proportion of results from randomly altered matrices with 
regression coefficients as high as those from the unaltered dependent variable matrix (Krackhardt 1987).

{pstd}
In this second step, {cmd:nwqap} randomly permutes rows and columns (together) of the dependent 
matrix (dependent network) and recomputes the regression, storing all coefficients. By default this step 
is repeated 500 times. The number of permutations can be changed with the option {bf:permutations}.
The coefficients of all these permutations are saved with {opth save(filename)}. Based one the distribution
of coefficients, {cmd:nwqap} calculates adjusted p-values and saves them in {it:e(pvalues)}.

{pstd}
{opt plot} draws this same permutation distribution visually: one histogram panel per coefficient
(the constant included), each with a dashed vertical line at that coefficient's real, unpermuted
value against a histogram of its own {opt permutations()} null draws - the standard visual check
for a QAP test (is the real coefficient out in the tail of what pure permutation produces, or
comfortably inside it?), the same comparison R's {bf:sna} package's {bf:plot.qaptest()} draws for a
single coefficient, generalized here to every coefficient in the regression at once. Grayscale by
design, matching every other plot this package produces.

{pstd}
{it:References}

{pmore}
Grund, T. and Densley, J. (2012). "Ethnic Heterogeneity in the Activity and Structure of a Black Street Gang." European Journal of Criminology, Vol. 9, Issue 3, pp. 388-406.

{pmore}
Krackhardt, David. (1987). "QAP Partialling as a Test of Spuriousness." Social Networks 9: 171-186.

{pmore}
Krackhardt, David. (1988). "Predicting with Networks: Nonparametric Multiple Regression Analysis of Dyadic Data." Social Networks 10: 359-381.


{marker qapspp}{...}
{title:qapspp - double semi-partialling}

{pstd}
Plain MR-QAP's own standard permutation test (the default, no {opt qapspp}) permutes the WHOLE
dependent network at once and refits the FULL model on every permuted draw - a valid test that a
variable has SOME association with the outcome, but not a valid test that it has an association
{it:net of the other independent variables}, since permuting the whole network scrambles every
variable's own relationship to it simultaneously, not just the one being tested. This is exactly
the "QAP partialling" problem Krackhardt (1987) originally identified.

{pstd}
{opt qapspp} instead uses double semi-partialling (Dekker, Krackhardt & Snijders 2007, "Sensitivity
of MRQAP Tests to Collinearity and Autocorrelation Conditions", {it:Psychometrika} 72(4)): for each
independent variable {it:k} in turn, both the dependent network AND {it:x_k} itself are first
residualized (via ordinary OLS) against every OTHER independent variable in the model, and the
permutation test is then run on those two RESIDUALIZED dyad vectors instead of the raw ones. This
isolates {it:x_k}'s own unique association with the outcome from the other regressors' influence,
giving a p-value that is much less sensitive to collinearity among the independent networks than
the plain permutation test - the specific failure mode Dekker, Krackhardt & Snijders' own
simulation study documents. Applied independently to every independent-variable coefficient
(the constant's own p-value is left as the plain single-permutation result, since double
semi-partialling is not defined for an intercept). Semi-partialling itself is always a real OLS
fit, regardless of which {opt type()} the main model itself used - Dekker, Krackhardt & Snijders'
own procedure is defined this way for any regression type.

{title:Examples}

	{cmd:. nwwebuse glasgow}
	{cmd:. nwqap glasgow2 glasgow1 smoke1 sport1}
	{cmd:. nwqap glasgow2 glasgow1 smoke1 sport1, predict(glasgow2_fitted)}


	{txt}Multiple Regression Quadratic Assignment Procedure

	{txt}  Estimation{col 25}={res}  QAP
	{txt}  Regression{col 25}={res}  logit
	{txt}  Permutations{col 25}={res}  500
	{txt}  Number of vertices{col 25}=  {res}50
	{txt}  Number of arcs{col 25}=  {res}116

{txt}{hline 23}{c TT}{hline 25}
{col 2}{ralign 21:glasgow2}{col 24}{c |}{col 31}Coef.{col 40}P-value
{hline 23}{c +}{hline 25}
{txt}{col 2}{ralign 21:glasgow1}{col 24}{c |}{col 25}{ralign 11:{res}3.652579}{col 40}{ralign 5:0}
{txt}{txt}{col 2}{ralign 21:same_smoke1}{col 24}{c |}{col 25}{ralign 11:{res}.514058}{col 40}{ralign 5:.018}
{txt}{txt}{col 2}{ralign 21:same_sport1}{col 24}{c |}{col 25}{ralign 11:{res}.217359}{col 40}{ralign 5:.394}
{txt}{col 2}{ralign 21:_cons}{col 24}{c |}{col 25}{ralign 11:{res}-4.125208}
{txt}{hline 23}{c BT}{hline 25}
	
{pstd}
This example shows that two individuals are more likely to be friends at time2 (glasgow2) 
when they already were friends at time1 (glasgow1). Furthermore two individuals {it:i} and
{it:j} are more likely to be friends at time2 when they both scored the same on smoking at
time1 (smoke1). There is no effect for both having scored the same on sport1. 


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, and undirected networks are not collapsed to unique dyads - both
{it:(i,j)} and {it:(j,i)} appear as separate observations in the dyad-level dataset (for an
undirected network they carry the same value, so this does not bias point estimates, but it does
mean the reported "Number of obs" and any raw regression standard errors reflect double-counted
dyads; QAP's own permutation-based p-values, not these raw standard errors, are what {cmd:nwqap}
actually reports). Weighted: {bf:W3}, explicit binary-only for the dependent network under the
default (and any other binary-outcome) {opt type()} - {help logit}, {help probit}, {help cloglog},
and {help scobit} all treat any nonzero value as a positive outcome (this is those commands' own
documented behavior, not something {cmd:nwqap} does intentionally) - so a valued/weighted
dependent network's tie strength is silently discarded by the chosen regression command unless a
continuous-outcome {opt type()} (e.g. {opt type(regress)}) is used instead; {cmd:nwqap} now warns
explicitly when this combination is detected, rather than leaving it silent. Independent networks
and variables are not affected - their values enter the regression directly, weighted or not.
Signed: not checked. Two-mode: not checked. A full weighted-QAP alternative (rather than a warning)
remains on the roadmap as a larger follow-on.


{title:Stored results}

{pstd}
{cmd:nwqap} is an {bf:eclass} command: results are posted with {help ereturn:ereturn}, so
{help estimates store}, {help estimates table}, and other standard postestimation commands
that only need {it:e(b)}/{it:e(V)} (e.g. {help test}, {help lincom}) work as usual. {it:e(V)}
is a diagonal matrix built from each coefficient's own QAP-permutation variance, not a
classical OLS/logit covariance matrix - dyadic network data violates the independent-
observations assumption those classical formulas require, which is the entire reason QAP
permutation testing exists in the first place. A native postestimation {help predict} does not
work after {cmd:nwqap} returns (see {help nwqap##independentvariables:Description} above for why -
the dyad-level dataset {bf:type()} actually fits is a transient internal detail, not the current
dataset once {cmd:nwqap} exits); use {opth predict(newnetname)} instead to capture fitted dyad-level
values directly, at the one point internally where they are genuinely meaningful.

	Scalars
	  {bf:e(N)}		number of dyad-level observations
	  {bf:e(permutations)}	number of QAP permutations

	Macros
	  {bf:e(cmd)}		{bf:nwqap}
	  {bf:e(title)}		title of estimation
	  {bf:e(depvar)}	name of dependent network
	  {bf:e(qap_regcmd)}	regression command used ({bf:type()})

	Matrices
	  {bf:e(b)}		coefficient vector
	  {bf:e(V)}		diagonal matrix of QAP-permutation coefficient variances
	  {bf:e(pvalues)}	matrix with QAP p-values, in the same column order as {bf:e(b)}

{title:See also}

	{help nwergm}, {help nwpermute}

