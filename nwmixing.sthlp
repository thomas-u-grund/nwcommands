{smcl}
{* *! version 1.0.0  24aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

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
{synopt:{opt plot}}Plot the ego/alter mixing table via {help tabplot}{p_end}
{synopt:{opt plotoptions(string)}}Additional options forwarded to {opt plot}'s own {help tabplot}{p_end}
{synopt:{opth permutations(int)}}Number of QAP permutations for the E-I index's own null
distribution and p-value; default = 100. Set to 1 to skip the permutation test entirely (only the
observed table/index are reported){p_end}
{synopt:{opth save(filename)}}Save the QAP permutation draws (variable {it:EI_simulated}) and the
observed value (variable {it:EI_observed}) to a new dataset{p_end}
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

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - ego/alter mixing is directional for a directed network (an
{it:attribute}{cmd:_ego}/{it:attribute}{cmd:_alter} pair is not symmetric); an undirected network's
own mixing table instead shows each edge counted from both endpoints, noted explicitly in the
output. Weighted: not applicable - see Description (ties are always treated as unvalued). Signed:
not checked. Two-mode: not checked.

{title:Stored results}

	Scalars
	  {bf:r(EI_index)}		the observed E-I index
	  {bf:r(EI_pvalue)}		two-sided QAP permutation p-value (only when {opt permutations()} > 1)

	Macros
	  {bf:r(netname)}		the network name
	  {bf:r(attribute)}		the {opt attribute()} variable name

	Matrices
	  {bf:r(table)}			the mixing table's own tie counts
	  {bf:r(col)}			the mixing table's column category values
	  {bf:r(row)}			the mixing table's row category values

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwmixing flomarriage, attribute(priorates)}

{title:References}

{pstd}
Krackhardt, D., Stern, R.N. (1988). Informal networks and organizational crises: An experimental
simulation. {it:Social Psychology Quarterly} 51(2), 123-140.

{title:See also}

	{help nwassortativity}, {help nwqap}, {help nwcorrelate}

