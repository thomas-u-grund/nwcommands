{smcl}
{* *!  15jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwaddnodes {hline 2}}Add nodes to network{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwaddnodes} 
[{it:{help netname}}], 
{cmd:nodenames}({it:n1, n2, ...})
[{opt generate}({it:{help newnetname}})
{opt xvars}]

{synoptline}
{p2colreset}{...}

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt nodenames}({it:n1, n2, ...})}Node identifiers separated by comma{p_end}
{synopt:{opt generate}({it:{help newnetname}})}Save as new network{p_end}
{synopt:{opt xvars}}Generate Stata variables for the network{p_end}
	
	
{title:Description}

{pstd}
Add isolate nodes to an existing networks. By default, {help netname} is replaced, unless {bf:generate()} is specified.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes - a purely structural operation, existing
ties and their values are untouched. Two-mode: runs without error, but does not offer a way to
choose which mode the new (isolate) nodes belong to - not recommended for two-mode networks until
that is clarified/documented.


{title:Examples}

{pstd}
This example adds three new nodes (isolates) to a random network with 5 nodes.

	{cmd:. nwclear}
	{cmd:. nwrandom 5, prob(.1)}
	{cmd:. nwaddnodes, nodenames(Thomas Grund, Peter, Mathilde Turcotte)}

last certified : 24 Aug 2026
