{smcl}
{* *! version 1.0.1  15sept2014 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##programming:[NW-2.9] Programming}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :_nwnodeid {hline 2}}Returns the nodeid of a node given its node label{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: _nwnodeid} 
[{it:{help netname}}],
{opt nodelab}({help nodeid:nodelab})
[{opt detail}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt nodelab}({help nodeid:nodelab})}nodelab of network node i{p_end}
{synopt:{opt detail}}displays the {help nodeid} and {help nodeid:nodelab} of node i{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
Returns the {help nodeid} of a node given its node label specified in {it:nodelab}. Results are stored
in the return vector. When no node with the specified label is found in network {it:netname} an error is thrown. When {it:nodelab} is an integer, it is
taken as the {help nodeid} itself (an error is thrown when it is larger than the number of nodes). This command is mostly used for programming with networks.


{title:Examples}

   {cmd:. nwwebuse florentine}
   {cmd:. _nwnodeid flomarriage, nodelab(medici) detail}
   
		{hline 40}
		{txt}  Network: {res}flomarriage
		{hline 40}
		{txt}    Nodeid  : {res}9
		{txt}    Nodelab : {res}medici
		
   {com}. return list

	{txt}scalars:
{synoptset 28 tabbed}{...}
{synopt:r(nodeid) =}{res}9{p_end}

	{txt}macros:
{synoptset 28 tabbed}{...}
{synopt:r(netname) : "{res}flomarriage{txt}"}{p_end}
{synopt:r(nodelab) : "{res}medici{txt}"}{p_end}


{title:Stored results}

{synoptset 28 tabbed}{...}
{p2col 5 28 32 2: Scalars}{p_end}
{synopt:{bf:r(nodeid)}}nodeid of node{p_end}
	  
{p2col 5 28 32 2: Macros}{p_end}
{synopt:{bf:r(netname)}}name of the networks{p_end}
{synopt:{bf:r(nodelab)}}node label of the node{p_end}


{title:See also}

   {help _nwnodelab}, {help nodeid}

{hline}
{pstd}{it:nwcommands version 3.21.0, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
