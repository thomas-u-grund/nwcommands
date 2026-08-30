{smcl}
{* *! 11jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwdrop {hline 2}}Drop networks or network nodes{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwdrop} 
[{it:{help netlist}}]

{p 8 17 2}
{cmdab: nwdrop} 
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
Drops a network or a list of networks. The command is the network version of {help drop} and mirrors {help nwkeep}.

{pstd}
It can also be used with {help if} or {help in}. Then it only drops certain nodes from a network. This updates the
Stata variable {bf:_nwinclude}, which indicates if a node is included in a network.

{title:Examples}

{pstd}
Load two networks and drop one of them by name:

	{cmd:. nwclear}
	{cmd:. nwrandom 5, prob(.4) name(net1)}
	{cmd:. nwrandom 5, prob(.4) name(net2)}
	{cmd:. nwdrop net1}
	{cmd:. nwset}

{pstd}
Drop only certain nodes from a network, using {help if}:

	{cmd:. nwclear}
	{cmd:. nwrandom 6, prob(.4) name(net3)}
	{cmd:. nwdrop net3 if _n > 3}
	{cmd:. nwsummarize net3}


{title:Supported network types}

{pstd}
