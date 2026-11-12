{smcl}
{* *! version 1.0.0  11nov2014}{...}
{marker topic}
{helpb nwtopical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 8 18 22 2}{...}
{p2col :nwlattice {hline 2}}Generate a lattice network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwlattice}
{it: {help int:cols rows}}
{cmd:,}
[{opt undirected}
{opt xwrap}
{opt ywrap}
{opt name}({it:{help newnetname}})
{opt vars}({it:{help newvarlist}})
{opt stub}({it:string})
{opt labs}({it:lab1 lab2 ...})
{opt xvars}
{opth ntimes(int)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:{help int:cols}}}number of columns in lattice; first positional argument{p_end}
{synopt:{it:{help int:rows}}}number of rows in lattice; default = 1 if omitted{p_end}
{synopt:{opt xwrap}}wrap horizontally{p_end}
{synopt:{opt ywrap}}wrap vertically{p_end}
{synopt:{opt undirected}}generate an undirected network; default = directed{p_end}
{synopt:{opt name}({it:{help newnetname}})}name of the new network; default = {it:lattice}{p_end}
{synopt:{opt vars}({it:{help newvarlist}})}new variables that are used for the network{p_end}
{synopt:{opt stub}({it:string})}stub of the variable names when {opt vars()} does not give one name per node; default = {it:lattice}{p_end}
{synopt:{opt labs}({it:lab1 lab2 ...})}node labels{p_end}
{synopt:{opt xvars}}generate Stata variables for the network{p_end}
{synopt:{opth ntimes(int)}}number of networks to be generated; default = 1{p_end}
{synopt:{opt noreplace}}reserved; currently a no-op - the create/replace collision guard on {opt name()} already applies regardless{p_end}

{title:Description}

{pstd}
{cmd:nwlattice} generates a lattice network. Each node is connected to maximally four other nodes. With options {it:xwrap} and {it:ywrap} 
each node is connected to exactly four other nodes.



{title:Network types}

{pstd}
{bf:Directed:} the default; {opt undirected} makes an undirected lattice. {bf:Valued:} not applicable (the lattice is
binary). {bf:Two-mode:} not applicable (the network is one-mode). {bf:Signed:} not applicable. See
{help nwnetworktypes}.{p_end}

{title:Examples}
	
	{cmd:. nwclear}
	{cmd:. nwlattice 4 4}
	{cmd:. nwplot, label(_nodeid)}
	
	{cmd:. nwclear}
	{cmd:. nwlattice 4 4, xwrap ywrap}
	{cmd:. nwplot, layout(grid) label(_nodeid)}

{title:Stored results}

	{bf:nwlattice} stores the following in {bf:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(netlist)}}list of new networks{p_end}

{title:See also}

	{help nwpref}, {help nwrandom}, {help nwring}, {help nwsmall}

{hline}
{pstd}{it:nwcommands version 3.20.1, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
