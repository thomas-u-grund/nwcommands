/***
{smcl}
{* *! version 2.0.0  19aug2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##information:[NW-2.4] Information}
{marker top2}
{helpb nw_topical##utilities:[NW-2.7] Utilities}


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
{synopt:{opth id(int)}}Originl network ID of the the network that should be made the current network{p_end}
{synoptline}
	
		
{title:Description}

{pstd}
Almost all nwcommands allow that a {help netname} or {help netlist} is optional. When no network 
is specified in such a case, by default, the nwcommands apply the command to the {it:current network}.

{pstd}
The {it:current network} is simply the last network that has been {help nwset:set},
{help nw_topical##import:imported}
or {help nw_topical##generators:generated}. This is a convenient way to way access the latest
network one worked with. 

{pstd}
{cmd:nwcurrent} changes the {it:current network}. Typically, it can be used with a {help netname}. When used with {bf:id()}, the network ID refers to the original order the networks were generated in.
The command also returns some information about the {it:current network}
in the r() vector. 


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

{title:Stored results} {txt}

	Scalars:
	  r(networks)	number of networks
	
	Macros:
	  r(current)	name of current network
	  

{title:Also see}

	{help nwname}, {help nwload}, {help nwset}

***/

capture program drop nwcurrent
program nwcurrent
	syntax [anything(name=netname)] [,id(string)]
	unw_defs
	
	if ("`id'" != "") {
		mata: nw.nws.make_current(`id')
	}
	else if ("`netname'" != ""){
		nw_syntax `netname', max(1)
		mata: nw.nws.make_current_from_name("`netname'")
	}
	
	nw_syntax
	
	mata: st_rclear()
	mata: st_global("r(current)", `nws'.get_current_name())
	mata: st_numscalar("r(networks)", `nws'.get_number())
	mata: st_numscalar("r(nodes)", (*`netobj').get_nodes())
	di "{hline 40}"
	di "{txt}   Current network: {res} `r(current)'"
	di "{txt}   Number of nodes: {res} `r(nodes)'"
	di "{hline 40}"
		
end

