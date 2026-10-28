{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_statmodels:[NW-2.6.6] Statistical Estimation of Networks}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwcug {hline 2}}Conditional Uniform Graph (CUG) test{p_end}
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
{opt condition(density|census|mode1degree|mode2degree|degrees)}
{opt trades(#)}
{opt silent}
{opt plot}
{opt name(string)}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt stat(command)}}Command template used to compute the test statistic; must contain the literal token {bf:##net##} where the network name belongs{p_end}
{synopt:{opt rname(string)}}Name of the {it:stat}'s {bf:r()} scalar to use as the test statistic{p_end}
{synopt:{opth reps(int)}}Number of conditioned random networks to draw; default = 1000{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before drawing (for reproducibility){p_end}
{synopt:{opt tail(both|upper|lower)}}Which tail(s) to report a p-value for; default = {it:both}{p_end}
{synopt:{opt condition(density|census|mode1degree|mode2degree|degrees)}}Null model to condition random draws on; default = {it:density}; {it:census} for directed one-mode networks, {it:mode1degree}, {it:mode2degree} and {it:degrees} for two-mode networks{p_end}
{synopt:{opt trades(#)}}Two-mode {bf:condition(degrees)}: the number of curveball trades between two draws; default = 5 times the number of nodes of the smaller mode (the first draw follows 6 times that many){p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt plot}}Draw a histogram of the {bf:reps()} null draws, with a dashed reference line at the observed statistic (the same comparison R's {bf:sna::plot.cug.test()} draws){p_end}
{synopt:{opt name(string)}}Name for the graph created by {opt plot}; default = {bf:cug}{p_end}

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
{opt condition(density|census)} chooses what property of {help netname} the random draws must
share, via {help nwrandom}'s own {bf:density()} (the default) or {bf:census()} conditioning.
{bf:condition(density)} draws uniformly from every network with the same node count and density -
the standard baseline used above. {bf:condition(census)} instead draws uniformly from every
network with the {it:same dyad census} (identical mutual/asymmetric/null tie counts, via
{help nwdyads}) as {help netname} - a stricter, reciprocity-aware null model: two directed networks
can share the same overall density while differing sharply in how many ties are reciprocated, so a
statistic that is unremarkable once density alone is held fixed can still be unusual once
reciprocity is held fixed too (or vice versa). {bf:condition(census)} requires a directed network -
mutual/asymmetric/null dyad types have no meaning for undirected ties, where every dyad is simply
tied or not.

{pstd}
Some statistics are fixed by the dyad census (reciprocity, for example). With {bf:condition(census)} their null distribution has standard deviation 0 and the test carries no information; the command prints a one-line note in that case.

{pstd}
{bf:tail()} controls which p-value(s) are reported: {bf:upper} is the proportion of random draws with
a statistic at least as large as observed (evidence the observed value is unusually {it:high});
{bf:lower} is the proportion at least as small (unusually {it:low}); {bf:both} (the default) reports
both, plus a two-sided p-value ({bf:r(p)}, twice the smaller one-sided p-value, capped at 1).

{pstd}
{opt plot} draws a histogram of the {bf:reps()} null draws with a dashed vertical line at the
observed statistic - the standard visual check for a CUG test (is the observed value out in the
tail of the null distribution, or comfortably inside it?), the same comparison R's {bf:sna}
package's {bf:plot.cug.test()} draws for its own {bf:cug.test()}. Grayscale by design, matching
every other plot this package produces.

{title:Two-mode networks}

{pstd}
For a two-mode network the null networks are two-mode networks with the same nodes (and the same node names and attributes) as {help netname}; the draws are made by a kernel of the native plugin of nwcommands 3.10.0 or later (a clear message asks for the update otherwise), so the time of a test is that of the statistic. The conditions are
{p_end}

{phang2}{bf:condition(density)} (the default): the same number of ties between a random mode-1 node and a random mode-2 node, no pair twice ({cmd:igraph::sample_bipartite(type = "gnm")}, {cmd:vegan::nullmodel(method = "r00")}).{p_end}
{phang2}{bf:condition(mode1degree)}: every mode-1 node keeps its degree and takes its partners at random among all mode-2 nodes ({cmd:vegan} method {cmd:r0}).{p_end}
{phang2}{bf:condition(mode2degree)}: the same for the mode-2 nodes ({cmd:vegan} method {cmd:c0}).{p_end}
{phang2}{bf:condition(degrees)}: both degree sequences stay, the curveball algorithm of Strona et al. (2014) ({cmd:vegan} method {cmd:curveball}; the same null model as {help nwpermute} with {opt swap}, which exchanges the partners of two ties). The draws form a chain; {opt trades()} sets the number of trades between two draws.{p_end}

{pstd}
The values of a valued two-mode network are shuffled over the ties of every draw (the number of ties and the degrees count ties, not values). {bf:condition(census)} counts the dyads of a directed one-mode network and is refused for a two-mode network (error 198); the two-mode conditions are refused for a one-mode network. For example, to test whether the nestedness of the Southern women is unusual for their degrees:

	{cmd:. nwuse davis, nwclear}
	{cmd:. nwcug davis, stat(nw2nested ##net##) rname(nodf) condition(degrees) reps(1000) seed(1)}

{pstd}
The means and standard deviations of the null distributions agree with those of {cmd:vegan::nullmodel} in R (1,000 draws of the nestedness NODF of the Southern women: 36.98 against 36.78 for {it:density}, 38.81 against 38.81 for {it:mode1degree}, 44.53 against 44.53 for {it:mode2degree}, 48.36 against 48.43 for {it:degrees}).

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes (required for {opt condition(census)}). Weighted: depends entirely on
{bf:stat()} - {cmd:nwcug} itself only draws random comparison networks and calls whatever command
{bf:stat()} names, so it inherits that command's own support. Signed: same as weighted, depends on
{bf:stat()}. Two-mode: yes - the null networks are two-mode networks with the number of ties or the degrees of the network (see Two-mode networks above).

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
Strona, G., Nappo, D., Boccacci, F., Fattorini, S., San-Miguel-Ayanz, J. (2014). A fast and unbiased procedure to randomize ecological binary matrices with fixed row and column totals. {it:Nature Communications} 5, 4114.

{pstd}
Anderson, B.S., Butts, C., Carley, K. (1999). The interaction of size and density with graph-level
indices. {it:Social Networks} 21(3), 239-267.

{title:Limits}

{pstd}
Every draw of the null distribution is a new random network ({help nwrandom}) and the statistic is computed on it. With
{cmd:condition(density)} above 5,000 nodes a draw is made in a fraction of a second (the positions of the ties are drawn
directly), so the time is that of the statistic: 5 draws with {cmd:nwcomponents} as the statistic take 2 seconds at 20,000 nodes
(more than 5 minutes at 10,000 nodes before, each draw shuffling the 100 million cells). The draws of networks of more than
5,000 nodes are not those of earlier versions for the same seed. {cmd:condition(census)} still works on the matrix.

{title:See also}

	{help nwrandom}, {help nwdyads}, {help nwpermute}, {help nwqap}

last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.12.0, 28 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
