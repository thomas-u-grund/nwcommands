{smcl}
{* *!  4jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_centrality:[NW-2.6.1] Centrality}

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
{opt generate}({it:{help varlist:varlist}})
{opt replace}
{opt silent}
{opt isolates}
{opt standardize}
{opt in}({it:{help tabulate_oneway##tabulate1_options:tabulate_opt}})
{opt out}({it:{help tabulate_oneway##tabulate1_options:tabulate_opt}})
{it:{help tabulate_oneway##tabulate1_options:tabulate_opt}}
{opt outputoff}
]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt alpha}}Tuning parameter for valued networks; default = 0{p_end}
{synopt:{opt generate}({it:{help varlist}})}Generate variables for degree, outdegree, indegree, isolate{p_end}
{synopt:{opt replace}}Overwrite existing variables {it:varlist}{p_end}
{synopt:{opt silent}}Surpress output{p_end}
{synopt:{opt outputoff}}Reserved/internal - has no effect on a one-mode network's own output; use {opt silent} instead. Only meaningful when {help netname} turns out to be two-mode (where it is named, along with any other one-mode-only option, in the note explaining which options have no bipartite equivalent and were ignored when redirecting to {help nw2degree}){p_end}
{synopt:{opt isolates}}Generate variable for network isolates{p_end}
{synopt:{opt standardize}}Divide degree or strength by N - 1{p_end}
{synopt:{opt in}({it:{help tabulate_oneway##tabulate1_options:tabulate_opt}})}Options for tabulating {it:indegree}{p_end}
{synopt:{opt out}({it:{help tabulate_oneway##tabulate1_options:tabulate_opt}})}Options for tabulating {it:outdegree}{p_end}
{synopt:{it:{help tabulate_oneway##tabulate1_options:tabulate_opt}}}Options for tabulating {it:degree}{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwdegree} calculates the generalized degree centrality of the nodes as outlined in Opsahl et al (2010) for the (un-)weighted, (un-directed) networks in {help netlist} . By default, the command generates the Stata variables {it:_degree} 
for an undirected network. When the network is directed the command generates by default {it:_outdegree} and {it:_indegree} unless something else is specified in {opt generate()}. It also tabulates the newly generated variables.

{pstd}
Following Opsahl et al. (2010) the degree centrality C_i of node i is defined as:

{pmore}
{it:C_i = k_i * ( s_i / k_i ) ^ alpha}

{pstd}
where {it:k_i} is the number of ties that node {it:i} is involved in (regardless of tie values) and {it:s_i} is the sum of the tie values of these ties. When {it:alpha = 0} (default), this generalized
degree centrality gives the number of ties that a node has. When {it:alpha = 1}, it gives the node strength, i.e. the sum of the tie values that a node is involved in. For unvalued networks the
value of {it:alpha} does not matter. 

{pstd}
Option {bf:isolates} generates the variable {it:_isolate} that indicates if a node is an isolate (not connected to any
other node).

{pstd}
Option {bf:standardize} divides the centrality scores by N - 1, where N = number of nodes in a network.

{pstd}
{cmd:nwdegree} accepts a {help netlist} (e.g. {bf:nwdegree glasgow1 glasgow2}), calculating degree
centrality independently for each network in the list. When more than one network is given, the
default output variable names get the network's own name appended (e.g. {it:_degree_glasgow1},
{it:_degree_glasgow2}, or {it:_indegree_glasgow1}/{it:_outdegree_glasgow1} for a directed network);
a single-network call is unaffected and keeps the plain default names ({it:_degree}, or
{it:_indegree}/{it:_outdegree}) exactly as before. Explicit {opt generate()} names are suffixed the
same way when more than one network is processed. {bf:r()} results (e.g. {bf:r(dg_central)}) reflect
whichever network was processed last, matching this package's convention for other {help netlist}
commands.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - generates separate {it:_indegree}/{it:_outdegree} (or {it:_instrength}/
{it:_outstrength} for a valued network) automatically. Weighted: {bf:W1}, native - the Opsahl et al.
(2010) generalized degree formula above is the command's default and only formulation, controlled
by {opt alpha()}; weight meaning is tie strength, used directly (not a distance). Signed: not
checked. Two-mode: not checked.


{title:References}

{pstd}
Tore Opsahl, Filip Agneessens, John Skvoretz (2010). Node centrality in weighted networks: Generalizing degree and shortest paths. {it:Social Networks} 32 (3), 245-251.


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
	{com}. qui nwdegree, alpha(0)
	. qui nwdegree, alpha(0) generate(deg0)
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
	{cmd:. nwdegree glasgow1, in(matcell(matindeg)) out(matcell(matoutdeg))}
	{cmd:. mat list matindeg}
	
{pstd}
The next example saves the out- and indegree centrality in the variables {it:myout} and {it:myin} and the information about isolates in {it:myisolate}.

	{cmd:. nwdegree glasgow1, generate(myout myin mysiolate) isolates}
	
	
{title:See also}

   {help nwbetween}, {help nwcloseness}, {help nwclustering}, {help nwevcent}, {help nwkatz} 
last certified : 24 Aug 2026
