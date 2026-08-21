{smcl}
{* *! version 03jun2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwvalue {hline 2} Checks if node exists in a network}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwnode} 
[{it:{help netname}}],
[{opt ego}({it:nodename}) |
{opt egoid}({it:nodeid})]


{title:Description}

{pstd}
The command checks if node {it:nodename} exists in network {it:netname} and returns its {it:nodeid}. In
case it does not exist, it returns -1.

 
{title:Examples}

	{cmd:. nwwebuse florentine}
	{cmd:. nwnode flobusiness, ego(medici)}


{title:Stored values}

	{cmd:r(nodeid)}
	{cmd:r(nodename)}
	
{title:See also}
   
   {help nwvalue}
last certified : 21 Aug 2026
