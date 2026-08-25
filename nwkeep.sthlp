{smcl}
{* *! 8jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwkeep {hline 2}}Keep a network (or only certain nodes){p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwkeep} 
[{it:{help netlist}}]

{p 8 17 2}
{cmdab: nwkeep} 
[{it:{help netname}}]
{ifin}
[{cmd:,}
{opt clean}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt clean}}Drop node observations{p_end}


{synoptline}
{p2colreset}{...}
	
	
{title:Description}

{pstd}
Keeps a network or a list of networks. The command is the network version of {help keep} and mirrors {help nwdrop}.

{pstd}
It can also be used together with {help if} or {help in}. In this case, the command operates on the node-level
and keeps only certain nodes of a network. 



{title:Supported network types}

{pstd}
