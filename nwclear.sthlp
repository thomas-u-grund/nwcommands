{smcl}
{* *! version 2.0.0  18Aug2016}{...}
{marker topic}
{helpb nw_topical##utilities:[NW-2.7] Utilities}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwclear {hline 2}}Clear all networks and variables from memory{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 13 2}{cmd:nwclear}


{title:Description}

{pstd}
Clears all networks and variables from memory. This is the network extension of {help clear}. One can also just drop
some or all networks using {help nwdrop}.

{pstd}
This example loads network data and clears everything afterwards.

	{cmd:. nwwebuse glasgow}
	{cmd:. nwclear}

{pstd}	
Alternatively, one can also just drop networks. This does not delete the Stata variables that are not associated 
with networks. For more information see {help nwdrop}. 

	{cmd:. nwdrop _all}
	


{title:Supported network types}

{pstd}
Not applicable - clears all networks and Stata variables from memory unconditionally, independent of any network's own properties.

{title:See also}

  {help nwdrop}, {help clear}
last certified : 24 Aug 2026
