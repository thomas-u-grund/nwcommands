/***
{smcl}
{* *! 14jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##utilities:[NW-2.7] Utilities}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwsync {hline 2}}Sync network with Stata variables{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwsync} 
[{it:{help netname}}]
[{cmd:,}
{opt label}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt label}}Sync the node labels{p_end}
{synopt:{opt fromstata}}Change the direction of the sync{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
Networks ultimately exist as Mata objects. However, one can also load them
as Stata variables that represent the adjacency matrix of a network 
(see {help nwload}). Normally, when a network is changed through another {help nwcommands:nwcommand} the 
Stata variables (if they exist) are automatically synced. But one can also invoke such 
a sync explicitly. Furthermore, {help nwsync} can be used to sync the other way around, i.e.
one can change the values of the Stata variables that represent the network and sync the 
network (that lives in Mata).   
 
{pstd}


{title:Options}

{phang}
{opt fromstata} Change the direction of the sync, i.e. the network is updated based on the
Stata variables that represent the network.
{p_end}

{phang}
{opt label} Sync the labels of the nodes with the Stata variable _nodelab
{p_end}


{title:Remarks}

{pstd}
One can use {help nwload} and {help nwsync: nwsync, fromstata} to replace tie values in a network. For example,
	
	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwload flomarriage}
	{cmd:. replace acciaiuoli = 99 in 2}
	{cmd:. nwsync flomarriage, fromstata}	

{pstd}
However, the preferred method to change the same tie value would be using {help nwreplace} instead:
 	
	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwreplace flomarriage[2,1] = 99 }

	
{title:See also}

	{help nwload}, {help nwreplace}, {help nwname}

***/

capture program drop nwsync
program def nwsync
	version 9
	syntax [anything(name=netname)],[ label fromstata]
	
	nw_syntax `netname', max(1)
	if "`label'" != "" {
		nw_datasync `netname'
	}
	
	mata: st_global("r(vars)", `netobj'->get_nodesvar_string())
	capture confirm variable `r(vars)'
	if (_rc == 0){
		if "`fromstata'" == "" {
			drop `r(vars)'
			nwload `netname'
		}
		else {
			mata: `netobj'->set_edge(st_data((1::`nodes'), "`r(vars)'"))
		}
	}
end

