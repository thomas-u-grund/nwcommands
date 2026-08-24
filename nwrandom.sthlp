{smcl}
{* *! version 2.0.0, 1dec2016: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}

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
{opt weights(p1, p2,...)}
{opt undirected}
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
{synopt:{opt weights(p1, p2,...)}}probabilities p_k for tie weights k{p_end}
{synopt:{opt undirected}}generate an undirected network; default = directed{p_end}
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
Either {bf:prob()}, {bf:density()} or {bf:census()} needs to be specified.

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



{title:Supported network types}

{pstd}
Binary: yes (only structural tie placement - see Weighted). Directed: yes, via {opt undirected} (default is directed). Weighted: yes, via {opt weights()} - a Stata expression assigning each placed tie's value, independent of the placement mechanism itself ({opt density()}/{opt prob()}/{opt census()}). Signed: not checked. Two-mode: not applicable - this generator always produces a one-mode network.

{title:Examples}
	
	{cmd:. nwclear}
	{cmd:. nwrandom 50, prob(.1)}
	{cmd:. nwrandom 15, density(0.5)}
	{cmd:. nwrandom 20, prob(.3) ntimes(5)}
	{cmd:. nwrandom 10, prob(.2) undirected}
	{cmd:. nwrandom 200, census(100 2000)}
	{cmd:. nwrandom 10, density(.2) weights(0.1, 0.3, 0.6)}

{title:Stored results}

	{bf:nwrandom} stores the following in {bf:r()}:
		  
	Macros
	  {bf:r(netlist)}	list of new networks
	  
{title:See also}

	{help nwsmall}, {help nwpref}, {help nwpref}, {help nwlattice}, {help nwring}

last certified : 24 Aug 2026
