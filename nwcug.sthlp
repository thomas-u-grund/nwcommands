{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwcug {hline 2} Conditional Uniform Graph (CUG) test}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwcug}
[{it:{help netname}}]
{cmd:,}
{opt stat(command)}
{opt rname(string)}
[{opth reps(int)}
{opt seed(int)}
{opt tail(both|upper|lower)}
{opt silent}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt stat(command)}}Command template used to compute the test statistic; must contain the literal token {bf:##net##} where the network name belongs{p_end}
{synopt:{opt rname(string)}}Name of the {it:stat}'s {bf:r()} scalar to use as the test statistic{p_end}
{synopt:{opth reps(int)}}Number of conditioned random networks to draw; default = 1000{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before drawing (for reproducibility){p_end}
{synopt:{opt tail(both|upper|lower)}}Which tail(s) to report a p-value for; default = {it:both}{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwcug} performs a Conditional Uniform Graph (CUG) test (Anderson, Butts and Carley 1999): it
compares an observed network statistic against the distribution of that same statistic computed on
{bf:reps} random networks drawn uniformly from the set of all networks with the same number of nodes
and the same density as {help netname} (using {help nwrandom}'s {bf:density()} conditioning). This
answers "is my observed statistic unusual, given only the size and density of the network?" - a
standard baseline null model in network analysis, since many statistics (e.g. transitivity, number of
components) are mechanically related to density alone, and a CUG test controls for that before
attributing a finding to genuine structure.

{pstd}
{bf:stat()} is a full command template (any {cmd:nw*} command plus whatever options it needs) that
returns a scalar in {bf:r()}; use the literal token {bf:##net##} wherever the network name belongs -
{cmd:nwcug} substitutes it with the observed network's name once, and with a freshly-drawn random
network's name {bf:reps()} times. {bf:rname()} names the returned scalar (without the surrounding
{cmd:r(...)}). Passing whatever {bf:replace}-style option the command needs (as part of the template)
is the caller's responsibility, since the same command runs once per random draw. For example, to
test whether the Florentine marriage network's component count is unusual for its size and density:

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcug flomarriage, stat(nwcomponents ##net##, replace) rname(components) reps(1000) seed(12345)}

{pstd}
{bf:tail()} controls which p-value(s) are reported: {bf:upper} is the proportion of random draws with
a statistic at least as large as observed (evidence the observed value is unusually {it:high});
{bf:lower} is the proportion at least as small (unusually {it:low}); {bf:both} (the default) reports
both, plus a two-sided p-value ({bf:r(p)}, twice the smaller one-sided p-value, capped at 1).

{title:Stored results}

	Scalars
	  {bf:r(obs)}		observed statistic
	  {bf:r(reps)}		number of random draws
	  {bf:r(mean_null)}	mean of the statistic across random draws
	  {bf:r(sd_null)}	standard deviation of the statistic across random draws
	  {bf:r(p_greater)}	proportion of random draws >= observed (upper-tail p-value)
	  {bf:r(p_less)}	proportion of random draws <= observed (lower-tail p-value)
	  {bf:r(p)}		two-sided p-value (2 * min(p_greater, p_less), capped at 1)

{title:References}

{pstd}
Anderson, B.S., Butts, C., Carley, K. (1999). The interaction of size and density with graph-level
indices. {it:Social Networks} 21(3), 239-267.

{title:See also}

	{help nwrandom}, {help nwpermute}, {help nwqap}

last certified : 21 Aug 2026
