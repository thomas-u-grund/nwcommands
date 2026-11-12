{smcl}
{* *!  4jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_centrality:[NW-2.6.1] Centrality}

{title:Title}

{p2colset 9 17 22 2}{...}
{p2col :nwdegree {hline 2}}Degree centrality and distribution{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwdegree} 
[{it:{help netname}}]
[{cmd:,}
{opth alpha(real)}
{opth ties(varlist)}
{opt generate}({it:{help varlist:varlist}})
{opt replace}
{opt silent}
{opt isolates}
{opt standardize}
{opt in}({it:{help tabulate_oneway##tabulate1_options:tabulate_opt}})
{opt out}({it:{help tabulate_oneway##tabulate1_options:tabulate_opt}})
{it:{help tabulate_oneway##tabulate1_options:tabulate_opt}}
{opt outputoff}
{opt onemode}
{opt raw}

{opt binary}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt alpha}}Tuning parameter for valued networks; default = 1 (strength) on a valued network, 0 (number of ties) otherwise{p_end}
{synopt:{opt ties}({it:varlist})}Valued networks: variables for the number of ties (one name, or outdegree and indegree), next to the strength in {opt generate()}{p_end}
{synopt:{opt generate}({it:{help varlist}})}{bf:Required.} Variable name(s) for degree (undirected) or outdegree/indegree (directed) - and, if {opt isolates} is also given, an extra name for the
isolate indicator{p_end}
{synopt:{opt replace}}Overwrite existing variables {it:varlist}{p_end}
{synopt:{opt silent}}Surpress output{p_end}
{synopt:{opt outputoff}}Reserved/internal - has no effect on a one-mode network's own output; use {opt silent} instead. Only meaningful when {help netname} turns out to be two-mode (where it is named,
along with any other one-mode-only option, in the note explaining which options have no two-mode form and were ignored){p_end}
{synopt:{opt isolates}}Generate variable for network isolates{p_end}
{synopt:{opt standardize}}Divide degree or strength by N - 1{p_end}
{synopt:{opt in}({it:{help tabulate_oneway##tabulate1_options:tabulate_opt}})}Options for tabulating {it:indegree}{p_end}
{synopt:{opt out}({it:{help tabulate_oneway##tabulate1_options:tabulate_opt}})}Options for tabulating {it:outdegree}{p_end}
{synopt:{it:{help tabulate_oneway##tabulate1_options:tabulate_opt}}}Options for tabulating {it:degree}{p_end}
{synopt:{opt binary}}Ignore the tie values of a valued network (by default they are used){p_end}
{synopt:{opt onemode}}Two-mode network: compute the one-mode degree of the bipartite graph instead of the two-mode degree (the default){p_end}
{synopt:{opt raw}}Two-mode network: the number of ties itself, not divided by the size of the other mode ({cmd:tnet::degree_tm}){p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwdegree} calculates the generalized degree centrality of the nodes as outlined in Opsahl et al (2010) for the (un-)weighted, (un-directed) networks in {help netlist}. {opt generate()} is
required: name one variable for an undirected network, or two (outdegree, indegree, in that order) for a directed one. It also tabulates the newly generated variable(s).

{pstd}
Following Opsahl et al. (2010) the degree centrality C_i of node i is defined as:

{pmore}
{it:C_i = k_i * ( s_i / k_i ) ^ alpha}

{pstd}
where {it:k_i} is the number of ties that node {it:i} is involved in (regardless of tie values) and {it:s_i} is the sum of the tie values of these ties. When {it:alpha = 0} (the default for an unvalued network), this generalized
degree centrality gives the number of ties that a node has. When {it:alpha = 1} (the default for a valued network), it gives the node strength, i.e. the sum of the tie values that a node is involved in. For unvalued networks the
value of {it:alpha} does not matter. 

{pstd}
Option {bf:isolates} adds one more name to {opt generate()} (after the degree name(s)) for a variable
indicating whether a node is an isolate (not connected to any other node) - e.g.
{cmd:generate(mydeg myisolate) isolates} on an undirected network, or
{cmd:generate(myout myin myisolate) isolates} on a directed one. When that extra name is not given, the variable is called {it:_isolates}.

{pstd}
Option {bf:standardize} divides the degree (undirected network) or the outdegree and the indegree (directed network) by N - 1, where N = number of nodes in a network. Each variable is divided once.

{pstd}
The stored results {bf:r(dg_central)} (undirected), {bf:r(indg_central)} and {bf:r(outdg_central)} (directed) are Freeman's degree centralization, computed from the raw scores whether or not
{bf:standardize} is given: sum(max - c_i) / ((N-1)*(N-2)) for an undirected network and sum(max - c_i) / ((N-1)*(N-1)) for the in- and outdegree of a directed network.

{pstd}
{cmd:nwdegree} accepts a {help netlist} (e.g. {bf:nwdegree glasgow1 glasgow2, generate(deg)}), calculating degree
centrality independently for each network in the list. When more than one network is given,
{opt generate()}'s own name(s) get the network's own name appended (e.g. {it:deg_glasgow1},
{it:deg_glasgow2}); a single-network call is unaffected and keeps the plain name(s) exactly as
given. {bf:r()} results (e.g. {bf:r(dg_central)}) reflect whichever network was processed last,
matching this package's convention for other {help netlist} commands.


{title:Network types}

{pstd}
{bf:Directed:} in- and out-degree (in- and out-strength) separately. {bf:Valued:} the strength by default,
{opt alpha()} for Opsahl's generalized degree, {opt binary} for the number of ties; {opt ties()} stores the tie
counts. {bf:Two-mode:} two-mode form by default (option {opt onemode} for the one-mode computation) - ties divided by
the size of the other mode, {opt raw} the count. {bf:Signed:} not checked. See {help nwnetworktypes}.{p_end}


{title:Examples}

{pstd}This is the example used in Opsahl et al. (2010, Table 1):

	{com}. nwclear
	{com}. nwset, mat((.,4,4,0,0,0\
		4,.,2,1,1,0\
		4,2,.,0,0,0\
		0,1,0,.,0,0\
		0,1,0,0,.,7\
		0,0,0,0,7,.)) undirected labs(A, B, C, D, E, F)
{res}
	{com}. qui nwdegree, alpha(0) generate(deg0)
	. qui nwdegree, alpha(.5) generate(deg0_5)
	. qui nwdegree, alpha(1) generate(deg1)
	. qui nwdegree, alpha(1.5) generate(deg1_5)

	. list deg*
{txt}
     {c TLC}{hline 6}{c -}{hline 11}{c -}{hline 6}{c -}{hline 11}{c TRC}
     {c |} {res}deg0      deg0_5   deg1      deg1_5 {txt}{c |}
     {c LT}{hline 6}{c -}{hline 11}{c -}{hline 6}{c -}{hline 11}{c RT}
  1. {c |} {res}   2           4      8          16 {txt}{c |}
  2. {c |} {res}   4   5.6568542      8   11.313708 {txt}{c |}
  3. {c |} {res}   2   3.4641016      6   10.392304 {txt}{c |}
  4. {c |} {res}   1           1      1           1 {txt}{c |}
  5. {c |} {res}   2           4      8          16 {txt}{c |}
     {c LT}{hline 6}{c -}{hline 11}{c -}{hline 6}{c -}{hline 11}{c RT}
  6. {c |} {res}   1   2.6457512      7    18.52026 {txt}{c |}
     {c BLC}{hline 6}{c -}{hline 11}{c -}{hline 6}{c -}{hline 11}{c BRC}

	
{pstd}
In the following example, the degree distributions for in- and outdegree are saved in Stata matrices {it:matindeg} and {it:matoutdeg}:

	{cmd:. nwwebuse glasgow}
	{cmd:. nwdegree glasgow1, generate(_outdegree _indegree) in(matcell(matindeg)) out(matcell(matoutdeg))}
	{cmd:. mat list matindeg}
	
{pstd}
The next example saves the out- and indegree centrality in the variables {it:myout} and {it:myin} and the information about isolates in {it:myisolate}.

	{cmd:. nwdegree glasgow1, generate(myout myin mysiolate) isolates}


{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{bf:r(alpha)}}value of {it:alpha} used{p_end}
{synopt:{bf:r(mean_ties)}}valued network: mean number of (out-)ties{p_end}
{synopt:{bf:r(mean_strength)}}valued network: mean (out-)strength{p_end}
{synopt:{bf:r(dg_central)}}undirected network: degree centralization (not with {opt isolates}){p_end}
{synopt:{bf:r(indg_central)}}directed network: indegree centralization (not with {opt isolates}){p_end}
{synopt:{bf:r(outdg_central)}}directed network: outdegree centralization (not with {opt isolates}){p_end}
{p2colreset}{...}

{pstd}
These results are those of a one-mode network; for a two-mode network see {help nw2degree}.{p_end}


{title:References}

{pstd}
Tore Opsahl, Filip Agneessens, John Skvoretz (2010). Node centrality in weighted networks: Generalizing degree and shortest paths. {it:Social Networks} 32 (3), 245-251.


{title:See also}

   {help nwbetween}, {help nwcloseness}, {help nwclustering}, {help nwevcent}, {help nwkatz}

{hline}
{pstd}{it:nwcommands version 3.21.0, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
