{smcl}
{* *! 8jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwduplicate {hline 2}}Duplicate a network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwduplicate}
[{it:{help netname}}]
[,
{opt name}({it:{help newnetname}})
{opt replace}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt name}({it:{help newnetname}})}name of the new network{p_end}
{synopt:{opt replace}}if a network named {it:newnetname} already exists, drop it and use this name anyway (see {help nwset} for the same convention){p_end}


{title:Description}

{pstd}
{cmd:nwduplicate} simply duplicates an existing network {it:netname}. By default, the duplicated network is called {it:netname_copy}. It also 
duplicates the node labels of the original network.

{pstd}
For example:

	{bf:. nwwebuse florentine, nwclear}
	{bf:. nwduplicate flomarriage}
	{bf:. nwname flomarriage_copy}
	{bf:. return list}
	
	

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes - a full, generic copy of the network object (adjacency matrix, node labels, directed/valued/two-mode status, and mode assignments), independent of any of these properties.

{title:See also}

	{help nwgenerate}, {help nwsubset}

last certified : 24 Aug 2026
