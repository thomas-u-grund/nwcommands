{smcl}
{* *! version 2.0.0, 1dec2016: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwrandom {hline 2}}Generate a random network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwrandom} 
{it:{help int:nodes}}
{cmd:,}
[{opth prob(float)}
{opth density(float)}
{opt census}({help nwdyads:{it:mutual asym} [{it:null}]})
{opt degree}({it:numlist}|{varname})
{opt outdegree}({it:numlist}|{varname}) {opt indegree}({it:numlist}|{varname})
{opth swaps(int)}
{opt weights(p1, p2,...)}
{opt undirected}
{opt directed}
{opth ntimes(int)}
{opt name}({it:{help newnetname}})
{opt labs}({it:lab1, lab2, ...})
{opt selfloop}
{opt xvars}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:{help int:nodes}}}number of nodes{p_end}
{synopt:{opth prob(float)}}probability for a tie{p_end}
{synopt:{opth density(float)}}exact density of the new network{p_end}
{synopt:{opt census}({help nwdyads:{it:mutual} [{it:asym null}]})}dyad census of the new network{p_end}
{synopt:{opt degree}({it:numlist}|{varname})}degree of every node of a new undirected network: a list of {it:nodes} numbers, or a variable (its first {it:nodes} observations){p_end}
{synopt:{opt outdegree()} {opt indegree()}}out-degree and in-degree of every node of a new directed network; both are needed{p_end}
{synopt:{opth swaps(int)}}with degrees: the number of attempted tie swaps that randomize the network; default = 10 times the number of ties{p_end}
{synopt:{opt weights(p1, p2,...)}}probabilities p_k for tie weights k{p_end}
{synopt:{opt undirected}}generate an undirected network; default = directed{p_end}
{synopt:{opt directed}}generate a directed network; this is the default, so the option changes nothing (it cannot be combined with {opt undirected}){p_end}
{synopt:{opth ntimes(int)}}number of random networks to be generated; default = 1{p_end}
{synopt:{opt name}({it:{help newnetname}})}name of the new random network; default = {it:random}{p_end}
{synopt:{opt labs}({it:lab1, lab2, ...})}overwrite node labels{p_end}
{synopt:{opt selfloop}}allow self-loops (a node tied to itself) in the generated network; default = no self-loops{p_end}
{synopt:{opt xvars}}generate Stata variables for the network{p_end}
{synopt:{opt noreplace}}reserved; currently a no-op - the create/replace collision guard on {opt name()} already applies regardless{p_end}


{title:Description}

{pstd}
{cmd:nwrandom} generates a (un-)directed, (un-)weighted Erdos-Renyi network. Each
potential tie in the network has the same probability to exist, which is defined 
by {bf:prob()}. Option {bf:prob()} generates ties based on probabilities, which means that
the exact number of ties can vary. 

{pstd}
Alternatively, the overall density of the network can be specified with 
{bf:density()}. This option always generates the same number of ties
( = {it:density * nodes}), where each tie has the same probability to exist.

{pstd}
Lastly, one can also generate a random network that has a specific {help nwdyads:dyad census} using {opt census()} (see {help nwdyads}).  

{pstd}
A random network with given degrees is drawn with {opt degree()} (undirected) or with {opt outdegree()} and {opt indegree()}
(directed); see {it:Networks with given degrees} below.

{pstd}
Either {bf:prob()}, {bf:density()}, {bf:census()} or the degrees need to be specified.

{pstd}
With option {bf:weights(}{it:p1, p2,...}{bf:)} the command generates a weighted network. Here,
{it:p_k} stands for the probability to sample tie weight {it:k}. The probabilities {it:p1, p2..., pn}
do not necessarily have to sum up to one; they are standardized. For example, the following
produces a random network with 10 nodes, where each tie has the probability 0.5 to exist. Furthermore,
each one of these randomly sampled ties gets assigned a tie weight because of option {bf:weights()}. In this case,
{bf:weights(0.0, 0.3,0.7)} indicates that tie weight 1 should be sampled with probability 0.0, tie weight 2 with
probability 0.3 and tie weight 3 with probability 0.7. 

	{cmd}. nwrandom 10, prob(.5) weights(0.0, 0.3, 0.7)
{txt}
{pstd}
The command can also be used to generate many random networks at the same time. For example, the following command
produces 100 random networks, where ties have the probability 0.1 to exist.

{pmore}
{bf:. nwrandom 50, prob(.1) ntimes(100)}

{pstd}
By default, directed networks are generated, option {bf:undirected} generates undiretced networks instead. 

{pstd}
The command can also be used to generate both complete ({bf:prob(1)}) and empty networks ({bf:prob(0)}). 

{marker degrees}{...}
{title:Networks with given degrees}

{pstd}
{opt degree()} draws an undirected network in which every node has exactly the degree given, with no self-loop and no
pair of nodes tied twice; {opt outdegree()} and {opt indegree()} do the same for the out-degrees and in-degrees of a
directed network. The degrees are a list of whole numbers, one for each node, or a numeric variable whose first {it:nodes}
observations hold them, for example the degrees of an observed network from {help nwdegree}. Use a variable for long lists.
All networks with these degrees are about equally likely: a network with the degrees is first built (Havel-Hakimi; directed:
Kleitman-Wang) and then randomized by {opt swaps()} random tie swaps, which exchange the partners of two ties (a-b and c-d
become a-d and c-b) whenever that makes no self-loop and no repeated tie, so the degrees never change. This is the method
{cmd:edge.switching.simple} of R's {cmd:igraph::sample_degseq()}. The network is unweighted. A random network with the degrees
of an observed one is the usual baseline for asking whether a pattern (clustering, reciprocity, segregation) goes beyond what
the degrees alone produce; {help nwcug} with {opt condition(degrees)} runs such a test and {help nwpermute} with {opt swap}
rewires a copy of the observed network itself.

{pstd}
Not every list of degrees can be the degrees of a network: their sum must be even (directed: the out-degrees and the
in-degrees must have the same sum), no node can have more than {it:nodes} - 1 ties, and more conditions follow from these
(Erdos and Gallai 1960). {cmd:nwrandom} stops with error 198 when no network has the degrees. For example, three nodes
cannot all have degree 1, and in {cmd:degree(3 3 1 1)} the two nodes of degree 3 would give every other node at least
degree 2. {opt degree()} cannot be combined with {opt prob()}, {opt density()}, {opt census()}, {opt weights()} or
{opt selfloop}. The draws use the native plugin of nwcommands 3.17.0 or later.

	{cmd:. nwrandom 8, degree(3 3 2 2 2 2 1 1)}
	{cmd:. nwuse glasgow, nwclear}
	{cmd:. nwdegree glasgow1, generate(od id)}
	{cmd:. nwrandom 50, outdegree(od) indegree(id) name(glasgow_null)}



{title:Supported network types}

{pstd}
Binary: yes (only structural tie placement - see Weighted). Directed: yes, via {opt undirected} (default is directed); with degrees, {opt degree()} draws an undirected network and {opt outdegree()} {opt indegree()} a directed one. Weighted: yes, via {opt weights()} - a Stata expression assigning each placed tie's value, independent of the placement mechanism itself ({opt density()}/{opt prob()}/{opt census()}). Signed: not checked. Two-mode: not applicable - this generator always produces a one-mode network.

{title:Examples}
	
	{cmd:. nwclear}
	{cmd:. nwrandom 50, prob(.1)}
	{cmd:. nwrandom 15, density(0.5)}
	{cmd:. nwrandom 20, prob(.3) ntimes(5)}
	{cmd:. nwrandom 10, prob(.2) undirected}
	{cmd:. nwrandom 200, census(100 2000)}
	{cmd:. nwrandom 10, density(.2) weights(0.1, 0.3, 0.6)}
	{cmd:. nwrandom 8, degree(3 3 2 2 2 2 1 1)}

{title:Stored results}

	{bf:nwrandom} stores the following in {bf:r()}:
		  
	Macros
	  {bf:r(netlist)}	list of new networks
	  
{title:Limits}

{pstd}
{opt prob()} above 2,000 nodes draws the ties as a list from the same random numbers as the matrix version (the same seed gives
the same network). {opt density()} above 5,000 nodes draws the positions of the ties directly instead of shuffling all {it:n}^2
cells: a different random-number stream (and the same distribution); with 5,000 nodes or fewer the shuffle is used, so earlier seeds
give the same networks. {opt weights()} and {opt census()} still work on the matrix. Measured in Stata/BE, density 0.0001: 5,000
nodes 11 seconds (shuffle), 10,000 nodes 0.1 seconds, 20,000 nodes 0.2 seconds ({opt density(.0002)}; 56 seconds at 10,000 and a
timeout at 20,000 before); {opt prob(.0002)} at 20,000 nodes 2.8 seconds (killed at 12 GB before).

{title:See also}

	{help nwsmall}, {help nwpref}, {help nwlattice}, {help nwring}, {help nwcug}, {help nwpermute}

last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.17.3, 9 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
