{smcl}
{* *! version 2.0.0  18aug2016 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_cohesion:[NW-2.6.2] Cohesion, components and subgroups}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwcomponents {hline 2}}Network components and the largest component{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwcomponents} 
[{it:{help netlist}}]
[, {opt lgc}
{opth generate(newvarname)}
{opt replace}
{opt silent}
{opt listall}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores information about components (component membership, or largest-component membership if {opt lgc} is
given){p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt lgc}}Calculate membership to largest component{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt listall}}Print the full table of components; by default at most the first 30 rows are printed, with a note. Results in {cmd:r()} are unchanged{p_end}

{p2colreset}{...}


{title:Description}

{pstd}
Calculate the components of a network or a list of networks. A component is a set of nodes that are
only connected among each other. All calculations are performed on the undirected network. Nodes can only belong to one component. 

{pstd}
{opt generate()} is required and names the new variable that stores the component membership. When
option {bf:lgc} is specified, the command instead stores in that variable
information about membership to the largest component (1 for its nodes, 0 for all others). With more than one network
in the {it:netlist}, a number is appended to the name ({it:newvarname}{bf:1}, {it:newvarname}{bf:2}, ...) and the stored
results are those of the last network.


{title:Network types}

{pstd}
{bf:Directed:} weak components (the direction is ignored). {bf:Valued:} tie values are ignored (every tie counts as
present; the command prints a note). {bf:Two-mode:} same as for the bipartite graph read as a one-mode network.
{bf:Signed:} not applicable. See {help nwnetworktypes}.{p_end}


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcomponents flomarriage, generate(_component)}

	{res}{hline 40}
	{txt}  Network name: {res}flomarriage
	{txt}  Components: {res}2

	 {txt}_component {c |}      Freq.     Percent        Cum.
	{hline 12}{c +}{hline 35}
	{txt}          1 {c |}{res}         15       93.75       93.75
	{txt}          2 {c |}{res}          1        6.25      100.00
	{txt}{hline 12}{c +}{hline 35}
	      Total {c |}{res}         16      100.00{txt}
  
 {pstd}
 This shows that there are two components in the Florentine marriage network. All except one node belong to the first
 component. Some alternative ways how the commands can be used.
 
	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwcomponents glasgow1, generate(mycomponent)}
	{cmd:. nwcomponents _all, lgc generate(_lgc)}
	{cmd:. nwcomponents _all, lgc generate(mylgc)}
  

 {title:Limits}

 {pstd}
 The components are found from the stored ties (10,000 nodes: 0.04 seconds). A network with more than 1,000 components (any sparse network
 of a few thousand nodes) has its component sizes counted in Mata; the
 table is not printed above 1,000 components, and {bf:r(comp_sizeid)} holds the sizes ordered by size and then by component number.

 {title:See also}
 
	{help nwgen}, {help nwkcomponents}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(components)}}number of components{p_end}
	  
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{bf:r(comp_sizeid)}}distribution over components: one row per component with the columns size, compid (component id) and share{p_end}

{hline}
{pstd}{it:nwcommands version 3.24.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
