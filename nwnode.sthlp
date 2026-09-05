{smcl}
{* *! version 03jun2019 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_other:[NW-2.6.7] Other Analysis Utilities}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwnode {hline 2}}Checks if node exists in a network{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwnode}
[{it:{help netname}}],
[{opt ego}({it:nodename})
{opt egoid}({it:nodeid})]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt ego}({it:nodename})}Look up the node by name{p_end}
{synopt:{opt egoid}({it:nodeid})}Look up the node by id{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
The command checks if node {it:nodename} exists in network {it:netname} and returns its {it:nodeid}. In
case it does not exist, it returns -1. Either {opt ego()} or {opt egoid()} needs to be specified; if
both are given, {opt egoid()} takes precedence and {opt ego()} is silently ignored.



{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - a pure node-existence/lookup check; does not read tie values or depend on directed/valued/two-mode status.

{title:Examples}

	{cmd:. nwwebuse florentine}
	{cmd:. nwnode flobusiness, ego(medici)}


{title:Stored values}

	{cmd:r(nodeid)}
	{cmd:r(nodename)}
	
{title:See also}
   
   {help nwvalue}
last certified : 24 Aug 2026
