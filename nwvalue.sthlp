{smcl}
{* *! version 15jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_other:[NW-2.6.7] Other Analysis Utilities}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwvalue {hline 2}}Returns a tie value{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwvalue} 
[{it:{help netname}}][,
{opt ego}({it:nodename})
{opt alter}({it:nodename})
{opth egoid(integer)}
{opth alterid(integer)}]


{title:Description}

{pstd}
The command returns the scalar {it:r(value)} with the value of the tie between the nodes {it:ego} and {it:alter} if those
nodes exists. It also returns the names of those nodes when ids are used. Either the option pair {bf:ego(), alter()} or {bf:egoid(), alterid()} need to be specified.

	  

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - the raw stored (row=ego, column=alter) cell is returned exactly as stored, respecting direction, never symmetrized. Weighted: yes, natively - returns the tie's own raw stored value. Signed: not checked; a negative value is returned as-is with no special handling. Two-mode: not checked, but not expected to need any - a direct single-cell lookup by node identity.

{title:Examples}

	{cmd:. nwwebuse florentine}
	{cmd:. nwvalue flobusiness, ego("medici") alter("pazzi")}
	{cmd:. nwvalue flobusiness, egoid(2) alterid(9)}
	{cmd:. return list}


{title:See also}
   
   {help nwreplace}
last certified : 24 Aug 2026
