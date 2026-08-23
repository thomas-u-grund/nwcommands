{smcl}
{* *! version 15jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwvalue {hline 2} Returns a tie value}
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

	  
{title:Examples}

	{cmd:. nwwebuse florentine}
	{cmd:. nwvalue flobusiness, ego("medici") alter("pazzi")}
	{cmd:. nwvalue flobusiness, egoid(2) alterid(9)}
	{cmd:. return list}


{title:See also}
   
   {help nwreplace}
