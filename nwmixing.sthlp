{smcl}
{* *! version 1.0.0  24aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_clustering:[NW-2.6.5] Clustering, mixing and balance}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwmixing {hline 2}}E-I index and mixing table for a categorical node attribute{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwmixing}
[{it:{help netname}}]
{cmd:,}
{opth attribute(varname)}
[{opt eiplot}
{opt eiplotoptions(string)}
{opt plot}
{opt plotoptions(string)}
{opth permutations(int)}
{opth save(filename)}
{it:tab_options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth attribute(varname)}}Categorical (string or numeric) node attribute to cross-tabulate
ties by{p_end}
{synopt:{opt eiplot}}Plot the null (QAP-permutation) distribution of the E-I index, with the observed
value marked{p_end}
{synopt:{opt eiplotoptions(string)}}Additional options forwarded to the {opt eiplot}'s own
{help kdensity}{p_end}
{synopt:{opt plot}}Plot the ego/alter mixing table as a bar plot in the style of {cmd:tabplot} (built in; see Remarks on plot){p_end}
{synopt:{opt plotoptions(string)}}Additional options forwarded to {help twoway} for {opt plot}{p_end}
{synopt:{opth permutations(int)}}Number of QAP permutations for the E-I index's own null
distribution and p-value; default = 100. Set to 1 to skip the permutation test entirely (only the
observed table/index are reported){p_end}
{synopt:{opth save(filename)}}Save the QAP permutation draws (variable {it:EI_simulated}) and the
observed value (variable {it:EI_observed}) to a dataset (an existing file is replaced); only when {opt permutations()} > 1{p_end}
{synopt:{it:tab_options}}Any other option is forwarded to the underlying {help tabulate twoway:tab}
call that builds the mixing table (e.g. {opt row}, {opt column}, {opt cell}){p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwmixing} cross-tabulates every tie in the network by the {opt attribute()} value of its ego
and alter (a "mixing table" or "mixing matrix"), and computes Krackhardt & Stern's (1988) E-I index:
the number of ties {it:external} to an attribute category minus the number {it:internal} to it,
divided by their sum. The index ranges from -1 (every tie stays within its own category - maximal
homophily/segregation) to +1 (every tie crosses categories - maximal heterophily/integration); 0
indicates ties are split between internal and external exactly as the network's overall tie count
would suggest.

{pstd}
Ties are treated as unvalued (presence/absence only) throughout - tie strength does not affect the
mixing table or the E-I index.

{pstd}
With {opt permutations()} greater than 1 (the default, 100), {cmd:nwmixing} also runs a QAP
permutation test: the attribute assignment is held fixed while the network itself is repeatedly
randomly permuted, building a null distribution of the E-I index under "no association between this
attribute and tie placement", and reports a two-sided p-value.


{title:Remarks on plot}

{pstd}
The {opt plot} option draws the table with a built-in bar plot (the same plot the user-written {help tabplot} draws; {cmd:tabplot} itself is not needed, and is not used even if it is installed). Any
further options in {opt plotoptions()} are passed to {help twoway}. The built-in plot follows the idea and the look of Nick Cox's {cmd:tabplot} (SSC); thanks to N. J. Cox.


{title:Network types}

{pstd}
{bf:Directed:} the mixing table is directional (ego to alter); on an undirected network every tie is counted from both
ends, as the output notes. {bf:Valued:} tie values are ignored (every tie counts as present; the command prints a note).
{bf:Two-mode:} same as for the bipartite graph read as a one-mode network. {bf:Signed:} not checked. See
{help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
The mixing table counts ties, so only the ties are listed (not all dyads). Measured in Stata/BE, random directed network with
10 ties per node: 5,000 nodes 0.3 seconds. The significance test
({opt permutations()}) permutes the attribute on the dense adjacency matrix; its running time at 5,000 nodes has not been
measured.

{pstd}
The permutations of {opt permutations()} act on the stored ties of a network that is held that way (a tie (u,v) lands in the cell
(inv u, inv v) of the permuted matrix, O(ties) per draw). 20,000 nodes
with 20 permutations: 1.2 seconds.


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwmixing flomarriage, attribute(priorates)}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(EI_index)}}the observed E-I index{p_end}
{synopt:{bf:r(EI_pvalue)}}two-sided QAP permutation p-value with the plus-one Monte Carlo correction, 2(1 + k)/(permutations + 1) with k the number of draws in the smaller tail, so that it is never 0
(only when {opt permutations()} > 1){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(netname)}}the network name{p_end}
{synopt:{bf:r(attribute)}}the {opt attribute()} variable name{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{bf:r(table)}}the mixing table's own tie counts{p_end}
{synopt:{bf:r(col)}}the mixing table's column category values{p_end}
{synopt:{bf:r(row)}}the mixing table's row category values{p_end}


{title:References}

{pstd}
Krackhardt, D., Stern, R.N. (1988). Informal networks and organizational crises: An experimental
simulation. {it:Social Psychology Quarterly} 51(2), 123-140.


{title:See also}

	{help nwassortativity}, {help nwqap}, {help nwcorrelate}

{hline}
{pstd}{it:nwcommands version 3.21.0, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
