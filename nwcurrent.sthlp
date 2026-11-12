{smcl}
{* *! version 2.0.0  19aug2016 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##utilities:[NW-2.7] Utilities}


{title:Title}

{p2colset 9 19 22 2}{...}
{p2col :nwcurrent {hline 2}}Report and set current network{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwcurrent} 
[{it:{help netname}}]
[{cmd:,}
{opth id(int)}]

{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth id(int)}}Original network ID of the network that should be made the current network{p_end}
{synoptline}
	
		
{title:Description}

{pstd}
Almost all nwcommands allow that a {help netname} or {help netlist} is optional. When no network 
is specified in such a case, by default, the nwcommands apply the command to the {it:current network}.

{pstd}
The {it:current network} is simply the last network that has been {help nwset:set},
{help nwtopical##import:imported}
or {help nwtopical##generators:generated}. This is a convenient way to way access the latest
network one worked with. 

{pstd}
{cmd:nwcurrent} changes the {it:current network}. Typically, it can be used with a {help netname}. When used with {bf:id()}, the network ID refers to the original order the networks were generated in.
The command also returns some information about the {it:current network}
in the r() vector. 



{title:Network types}

{pstd}
The command works the same for every network type (see {help nwnetworktypes}).{p_end}

{title:Examples}

	{com}. nwwebuse florentine
	{com}. nwcurrent
	{res}{hline 40}
	{txt}   Current network: {res} flomarriage
	{txt}   Number of nodes: {res} 16
	{hline 40}

	{com}. nwcurrent flobusiness
	{res}{hline 40}
	{txt}   Current network: {res} flobusiness
	{txt}   Number of nodes: {res} 16
	{hline 40}

{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(networks)}}number of networks{p_end}
{synopt:{bf:r(nodes)}}number of nodes of the current network{p_end}
	
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(current)}}name of current network{p_end}
	  

{title:Also see}

	{help nwname}, {help nwload}, {help nwset}

{hline}
{pstd}{it:nwcommands version 3.21.0, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
