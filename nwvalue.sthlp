{smcl}
{* *! version 15jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_other:[NW-2.6.8] Other analysis tools}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwvalue {hline 2}}Return a tie value{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwvalue} 
[{it:{help netname}}][,
{opt ego}({it:nodename})
{opt alter}({it:nodename})
{opth egoid(integer)}
{opth alterid(integer)}]

{p 8 17 2}
{cmdab: nwvalue}
{it:{help netname}}{cmd:[}{it:egoid}{cmd:,}{it:alterid}{cmd:]}


{title:Description}

{pstd}
The command returns the scalar {it:r(value)} with the value of the tie between the nodes {it:ego} and {it:alter} if those
nodes exists. It also returns the names of those nodes when ids are used. Either the option pair {bf:ego(), alter()} or {bf:egoid(), alterid()} need to be specified.


{title:Network types}

{pstd}
{bf:Directed:} the stored cell (row ego, column alter) is returned, never symmetrized. {bf:Valued:} the stored value
is returned. {bf:Two-mode:} same as for the bipartite graph read as a one-mode network. {bf:Signed:} a negative value
is returned as stored. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
The value of one cell of a network held as stored ties is read from the sparse index (no matrix).


{title:Examples}

	{cmd:. nwwebuse florentine}
	{cmd:. nwvalue flobusiness, ego("medici") alter("pazzi")}
	{cmd:. nwvalue flobusiness, egoid(2) alterid(9)}
	{cmd:. nwvalue flobusiness[2,9]}
	{cmd:. return list}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(value)}}value of the tie from ego to alter{p_end}
{synopt:{bf:r(ego_id)}}position of ego in the network{p_end}
{synopt:{bf:r(alter_id)}}position of alter in the network{p_end}
{synopt:{bf:r(ego_valid)}}1 if ego exists (with {opt ego()} and {opt alter()}){p_end}
{synopt:{bf:r(alter_valid)}}1 if alter exists (with {opt ego()} and {opt alter()}){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(ego)}}name of ego{p_end}
{synopt:{bf:r(alter)}}name of alter{p_end}


{title:See also}
   
   {help nwreplace}

{hline}
{pstd}{it:nwcommands version 3.20.1, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
