{smcl}
{* *! version 1.0.0  4nov2026}{...}
{marker topic}
{helpb nwtopical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 18 20 2}{...}
{p2col :nwstack {hline 2}}Stack several networks into one block-diagonal network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwstack}
{it:{help netlist}}{cmd:,}
{opt name}({it:{help newnetname}})
[{opt gr:oup}({it:newvar})
{opt replace}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt name}({it:newnetname})}name of the stacked network (required){p_end}
{synopt:{opt gr:oup}({it:newvar})}variable that numbers the networks of {it:netlist} 1, 2, ... for the nodes of each{p_end}
{synopt:{opt replace}}replace an existing network of that name{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:nwstack} places the networks of {it:netlist} side by side in one network. The nodes of the first network come first, then
those of the second, and so on; there are no ties between nodes of different networks, so the result is the block-diagonal
matrix of the networks. This is the data structure that {helpb nwsaom} uses for several groups (its option {cmd:groups()}), where each
group is a separate set of actors, such as a school class, observed with the same instrument.

{pstd}
The networks must be one-mode and agree in direction. With {opt group()} the command creates a variable that holds the position of the
network in {it:netlist}, for every node of the stacked network. If there are no data in memory, the command creates the observations; if there are
data, they must already have one observation per node, in the order of the stacked network.


{title:Example}

{pstd}
Two waves of three school classes are stacked into one network per wave, with a class variable:

	{bf:. nwstack class1_w1 class2_w1 class3_w1, name(w1) group(class)}
	{bf:. nwstack class1_w2 class2_w2 class3_w2, name(w2)}
	{bf:. nwsaom, waves(w1 w2) groups(class) outdegree reciprocity}


{title:Stored results}

{pstd}
{cmd:nwstack} stores in {cmd:r()}: {cmd:r(k)}, the number of networks stacked, and {cmd:r(N)}, the number of nodes of the stacked network.


{title:Author}

{pstd}
Thomas U. Grund, University College Dublin, thomas.u.grund@gmail.com
{p_end}

{hline}
{pstd}{it:nwcommands version 3.16.0, 5 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
