{smcl}
{* *! version 1.0.0  28aug2026 author: Thomas Grund}{...}

{title:Title}

{p2colset 9 25 26 2}{...}
{p2col :nwsaom postestimation {hline 2}}Postestimation tools for {cmd:nwsaom}{p_end}
{p2colreset}{...}

{title:Description}

{pstd}
The following postestimation command is available after {helpb nwsaom}:

{p2colset 9 22 23 2}{...}
{p2col: {cmd:estat gof}}RSiena-style goodness-of-fit test and violin plot{p_end}
{p2colreset}{...}

{title:Supported network types}

{pstd}
Not applicable - {cmd:estat gof} operates on the fitted model and the wave data left behind by
{help nwsaom}, not on a network directly; see that command's own classification.

{title:estat gof}

{p 8 17 2}
{cmd:estat gof} {opt [, NSIM(int) SEED(int) STATS(namelist) MAXDEG(int) MAXDIST(int) TWOTAILED NAME(string)]}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt nsim(int)}}Number of fresh post-fit simulated replicates forming the reference distribution; default 50, minimum 5{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before simulating{p_end}
{synopt:{opt stats(namelist)}}Auxiliary statistics to test, any of {bf:outdegree}, {bf:indegree}, {bf:geodesic}, {bf:behavior}; default all three network statistics, plus {bf:behavior} automatically whenever the fit in memory used {opt behavior()} ({bf:behavior} itself requires a co-evolution fit){p_end}
{synopt:{opt maxdeg(int)}}Highest EXACT out-/in-degree category before the ("maxdeg+") overflow bin; default 15{p_end}
{synopt:{opt maxdist(int)}}Highest EXACT geodesic-distance category before the ("NR", not reached) overflow bin; default 6{p_end}
{synopt:{opt twotailed}}Report a two-tailed p-value instead of the one-tailed default (RSiena's own {cmd:twoTailed=FALSE} default: reject for a SMALL p only, i.e. the observed network is an outlier relative to what the fitted model simulates){p_end}
{synopt:{opt name(string)}}Stub for the violin-plot graph names; default {cmd:gof} (graphs are named {cmd:{it:name}_outdegree}, {cmd:{it:name}_indegree}, {cmd:{it:name}_geodesic}, and {cmd:{it:name}_behavior} for a co-evolution fit's fourth statistic){p_end}
{synoptline}

{pstd}
{cmd:estat gof} reports real RSiena's own goodness-of-fit methodology ({cmd:sienaGOF()}/
{cmd:plot.sienaGOF()}, Lospinoso & Snijders 2019) - a fundamentally different, more rigorous
construction than a simple descriptive comparison. For each requested auxiliary statistic (a
user-chosen SUMMARY of the network, not a raw model term - the out-degree distribution, in-degree
distribution, and geodesic-distance distribution, the same trio real RSiena itself uses by
default), {opt nsim()} fresh post-fit replicates are simulated at the fitted coefficients, and a
Mahalanobis-distance hypothesis test compares the observed wave's own auxiliary-statistic vector
against that simulated reference distribution. A small p-value (below 0.05, RSiena's own
convention) is evidence AGAINST the fitted model on that statistic; rough agreement is evidence
for it, not proof.

{pstd}
{bf:The test itself} is a direct, line-by-line port of real RSiena's own {cmd:applyTest()}
closure inside {cmd:sienaGOF()} (verified against the installed package's own R source, not
re-derived from a description): the simulated replicates' own covariance matrix is inverted via a
Moore-Penrose pseudoinverse ({bf:required}, not merely convenient - a distribution's own category
proportions are collinear by construction, e.g. they sum to 1, so the plain covariance matrix is
rank-deficient), each replicate's own Mahalanobis distance from the simulated mean is computed,
and the reported p-value is the empirical proportion of simulated distances at or beyond the
observed vector's own distance - a permutation-style p-value, not a chi-square/normal-theory one.

{pstd}
{bf:Simulation source differs from real RSiena, disclosed.} Real RSiena's own {cmd:iterations}
reuses networks already simulated and stored during the fit itself. {cmd:nwsaom} has no such
storage today, so {cmd:estat gof} runs {opt nsim()} FRESH simulations instead, restarting from
each period's own observed starting wave exactly as {cmd:nwsaom}'s own estimation does - this does
not change the statistical construction (the Mahalanobis test is agnostic to how its reference
draws were generated, only that they are genuine, independent draws at the fitted parameters).

{pstd}
{bf:Pooling across periods.} With three or more waves, each auxiliary statistic's own vector is
POOLED (summed) across every period before the single test is run - real RSiena's own
{cmd:join=TRUE} default, matching {cmd:nwsaom}'s own established summation-pooling convention for
the rate/eval parameters themselves. A separate test per period ({cmd:join=FALSE}) is real
RSiena's own non-default option and is not implemented here.

{pstd}
{bf:Co-evolution fits} (a {opt behavior()} model) add a fourth default auxiliary statistic,
{bf:behavior} (real RSiena's own {cmd:BehaviorDistribution()}), and simulate network and behavior
JOINTLY for every replicate regardless of which {opt stats()} were actually requested - the fitted
coefficients were estimated jointly, so a network-only simulation would not be faithful to the
fitted model even when only network statistics are being checked. Co-evolution GOF always uses the
Mata reference simulator (no native backend yet for the joint network+behavior case).

{pstd}
{bf:The plot.} Each statistic's own result is additionally rendered as a violin plot: a
kernel-density shape per category (Stata has no native violin geom - this is the standard
{cmd:kdensity}+{cmd:twoway rarea, horizontal} technique), a thin embedded box (interquartile
range), dashed 2.5th/97.5th-percentile envelope lines, and the observed value overlaid as a
red connected line - reproducing real RSiena's own {cmd:plot.sienaGOF()} panel layout (violin +
{cmd:panel.bwplot(box.ratio=0.1)} + dashed percentile lines + red observed overlay) as closely as
Stata's own graphics primitives allow, with the test's own p-value shown as the plot's x-axis
title, matching RSiena's own {cmd:xlabel = paste("p:", round(x$p,3))} convention exactly.

{title:Stored results}

{pstd}
{cmd:estat gof} stores the following in {cmd:r()}, one pair per requested statistic (default
{bf:outdegree}/{bf:indegree}/{bf:geodesic}, plus {bf:behavior} for a co-evolution fit):

		Scalars
		  {bf:r(p_{it:stat})}		empirical Mahalanobis-distance test p-value for that statistic
		  {bf:r(mhd_{it:stat})}		observed vector's own Mahalanobis distance from the simulated mean

{title:Examples}

		{cmd:. nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(wave1)}
		{cmd:. nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(wave2)}
		{cmd:. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity transtrip}
		{cmd:. estat gof}

		{cmd:. estat gof, nsim(200) stats(outdegree geodesic) maxdeg(10)}

		{cmd:. estat gof, twotailed name(mygof)}

{title:References}

{pstd}
Lospinoso, J., Snijders, T.A.B. (2019). Goodness of fit for stochastic actor-oriented models.
{it:Methodological Innovations}, 12(3).

{pstd}
Ripley, R.M., Snijders, T.A.B., Boda, Z., Voros, A., Preciado, P. (2024). Manual for RSiena.

{title:See also}

	{help nwsaom}
