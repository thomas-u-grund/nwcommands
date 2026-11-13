{smcl}
{* *! version 1.0.0  11nov2014}{...}
{marker topic}
{helpb nwtopical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 16 22 2}{...}
{p2col :nwring {hline 2}}Generate a ring-lattice network{p_end}
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
{opt labs}({it:lab1,lab2,...})
{opt xvars}
{opth ntimes(int)}]

{synoptset 21 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:{help int:nodes}}}number of nodes{p_end}
{synopt:{opth k(int)}}number of neighbors on ring-lattice on each side{p_end}
{synopt:{opt weights(p1, p2,...)}}probabilities p_k for tie weights k{p_end}
{synopt:{opt undirected}}generate an undirected network; default = directed{p_end}
{synopt:{opth name(newnetname)}}name of the new network; default = {it:ring}{p_end}
{synopt:{opt labs}({it:lab1,lab2,...})}overwrite node labels (separated by commas){p_end}
{synopt:{opt xvars}}generate Stata variables for the network{p_end}
{synopt:{opth ntimes(int)}}number of networks to be generated (named {it:name}_1, {it:name}_2, ...); default = 1{p_end}
{synopt:{opt noreplace}}reserved; currently a no-op - the create/replace collision guard on {opt name()} already applies regardless{p_end}


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


{title:Network types}

{pstd}
{bf:Directed:} directed by default; {opt undirected} gives an undirected network. {bf:Valued:} {opt weights()} draws tie
values. {bf:Two-mode:} not applicable - the command always creates a one-mode network. {bf:Signed:} not checked. See
{help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
Above 2,000 nodes the ring is written as a list of ties (20,000 nodes with {opt k(5)}: 0.2 seconds).
{opt weights()} still uses the matrix.


{title:Examples}
	
	{cmd:. nwclear}
	{cmd:. nwring 20, k(2) undirected}


{title:Stored results}

	{bf:nwring} stores the following in {bf:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(netlist)}}list of new networks{p_end}


{title:See also}

	{help nwpref}, {help nwrandom}, {help nwlattice}, {help nwsmall}

{hline}
{pstd}{it:nwcommands version 3.24.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
