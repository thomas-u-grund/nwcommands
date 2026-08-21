{smcl}
{* *! version 1.0.0  11nov2014}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 16 22 2}{...}
{p2col :nwring {hline 2} Generate a ring-lattice network}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwring} 
{it:{help int:nodes}}
{cmd:,}
{opth k(int)} 
[{opt weights(p1, p2,...)}
{opt undirected}
{opth name(newnetname)}
{opt labs}({it:lab1 lab2 ...})
{opt xvars}
{opth ntimes(int)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:{help in:nodes}}}number of nodes{p_end}
{synopt:{opth k(int)}}number of neighhbors on ring-lattice on each side{p_end}
{synopt:{opt weights(p1, p2,...)}}probabilities p_k for tie weights k{p_end}
{synopt:{opt undirected}}generate an undirected network; default = directed{p_end}
{synopt:{opth name(newnetname)}}name of the new network{p_end}
{synopt:{opt labs}({it:lab1 lab2 ...})}overwrite node labels{p_end}
{synopt:{opt xvars}}do not generate Stata variables{p_end}
{synopt:{opth ntimes(int)}}number of networks to be generated; default = 1{p_end}

{title:Description}

{pstd}
{cmd:nwring} generates a (un-)directed, (un-)weighted ring-lattice network. Each node is connected to {it:k} 
nodes on each side. Basically, each node has 2 * {it:k} neighbors in a ring structure.

{pstd}
With option {bf:weights(}{it:p1, p2,...}{bf:)} the command generates a weighted network. Here,
{it:p_k} stands for the probability to sample tie weight {it:k}. The probabilities {it:p1, p2..., pn}
do not necessarily have to sum up to one; they are standardized. For example, the following
produces a ring-lattice network with 20 nodes, where each node is connected to two neighbors on each side. Furthermore,
each one of these sampled ties gets assigned a tie weight because of option {bf:weights()}. In this case,
{bf:weights(0.0, 0.3,0.7)} indicates that tie weight 1 should be sampled with probability 0.0, tie weight 2 with
probability 0.3 and tie weight 3 with probability 0.7. 

	{cmd:. nwring 20, k(2) weights(0.0,0.3,0.7)}
	
{title:Examples}
	
	{cmd:. nwclear}
	{cmd:. nwring 20, k(2) undirected}
	
	
{title:See also}

	{help nwpref}, {help nwrandom}, {help nwlattice}, {help nwsmall}

last certified : 21 Aug 2026
