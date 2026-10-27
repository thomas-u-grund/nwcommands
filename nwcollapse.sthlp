{smcl}
{* *! version 2.0.0  19aug2016}{...}
{marker topic}
{helpb nwtopical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwcollapse {hline 2}}Collapse a network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwcollapse} 
[{opt (stat)}]
[{it:{help netname}}]
[{cmd:,}
{opth by(varname)} 
{opth generate(newnetname)} 
{it:{help collapse##table_options:options}}]


{title:Description}

{pstd}
This command collapses a network, i.e. it merges network nodes. It works very similar as {help collapse}. With option {opth by(varname)} one specifies which nodes should
be merged. The rule for collapsing two nodes are specified with {it:stat}, by default {it:stat} = {bf:max} ({help collapse:see here for possible values}). For example, when nodes
A and B are collapsed to node Z, Z inherits all the ties from node A and B. The nodes in the new network are named after the values in {it:varname}.  

{pstd}
By default, an existing network is replaced, unless option {opt generate(newnetname)} is specified. 


{marker examples}{...}

{title:Two-mode networks}

{pstd}
Two-mode: not supported - error 6088; make a one-mode network of one mode first with {help nwproject}.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes - {opt generate()}'s own collapse function operates on whatever tie values are present. Signed: not checked. Two-mode: not supported - error 6088; make a one-mode network of one mode first with {help nwproject}.

{title:Examples}

{pstd}
This collapses the first and the second node of a random network. The collapsed node will have all ties that the original nodes had. 

	{cmd:. nwrandom 20, prob(.1) name(mynet)}
	{cmd:. gen att = _n}
	{cmd:. replace att = 1 in 2}
	{cmd:. nwcollapse mynet, by(att)}

	
{title:Limits}

{pstd}
The collapse is done on the list of all dyads of the network (see {help nwtoedge}), so the time and the memory grow with the
square of the number of nodes. Measured in Stata/BE, random directed network with 10 ties per node and 5 groups: 1,000
nodes 8 seconds, 5,000 nodes 61 seconds and 4.5 GB; above 7,071 nodes (50,000,000 dyads) the command stops at once with r(484),
a message that says why and what to do instead.

{title:See also}

	{help collapse}
last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.11.1, 28 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
