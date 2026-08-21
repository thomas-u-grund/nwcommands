{smcl}
{* *! 8jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwkeep {hline 2} Keep a network (or only certain nodes)}
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


{title:Examples}

{pstd}
The following command loads data from the internet and keeps the network {it:flobusiness}.

	{com}. nwwebuse florentine, nwclear}
	{res}
	{com}. nwds
	{res}{txt}{col 1}flobusiness  {col 20}flomarriage
	{res}
	{com}. nwkeep flobusiness
	{res}
	{com}. nwds
	{res}{txt}{col 1}flobusiness
	
	
{pstd}
Whenever a command allows a {help netlist}, networks can be abbreviated, just like variables. For example,

	{cmd:. nwkeep fl*}


{pstd}
The next command keeps the first ten nodes of network {it:flobusiness}.
	
	{cmd:. nwkeep flobusiness if _n <= 10}

{pstd}
One can also keep the first ten nodes of a network like this:

	{cmd:. nwkeepnodes glasgow1, nodes(1-10)}

{pstd}
The following command keeps only nodes in the flomarriage network with seats in the civic council (seat == 1).

	{com}. nwwebuse florentine, nwclear}
	{res}
	{com}. nwkeep flomarriage if seat == 1{txt}


{title:Remarks}

{pstd}
By default, all dropped nodes remain in the dataset, i.e. they are only excluded from the network. With option
{bf:clean}, dropped nodes are removed from the Stata dataset as well. Notice that for example the node
"medici" in the Florentine dataset is a node in both the marriage and the business network. Hence, the option {bf:clean}
would remove this node and all node attributes. In the example above, the node "medici" would be removed from the {bf:flomarriage}
network, but not from the {bf:flobusiness} network. But with the option {bf:clean} all node attributes would be deleted as well (although the node "medici" remains in the {bf:flobusiness}
network). 


{title:Also see}
   
   {help nwclear}, {help nwdrop}, {help nwkeepnodes}, {help nwdropnodes}

last certified : 21 Aug 2026
