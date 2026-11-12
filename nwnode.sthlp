{smcl}
{* *! version 03jun2019 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_other:[NW-2.6.8] Other analysis tools}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwnode {hline 2}}Check whether a node exists in a network{p_end}
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


{title:Stored values}

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(nodeid)}}nodeid of the node; -1 if it does not exist{p_end}
{synopt:{cmd:r(nodename)}}name of the node{p_end}


{title:Network types}

{pstd}
The command works the same for every network type (see {help nwnetworktypes}).{p_end}


{title:Examples}

	{cmd:. nwwebuse florentine}
	{cmd:. nwnode flobusiness, ego(medici)}


{title:See also}
   
   {help nwvalue}

{hline}
{pstd}{it:nwcommands version 3.21.0, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
