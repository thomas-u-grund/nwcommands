{smcl}
{* *! version 1.0.0  11nov2014}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwpref {hline 2}}Generate a preferential-attachment network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwpref} 
{it:{help int:nodes}}
[{cmd:,}
{opth m0(int)} 
{opth m(int)} 
{opth prob(float)} 
{opt weights(p1, p2,...)}
{opt undirected}
{opt name}({it:{help newnetname}})
{opt xvars}
{opth ntimes(int)}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:nodes}}number of nodes{p_end}
{synopt:{opth m0(int)}}number of connected nodes at start; default = 2{p_end}
{synopt:{opth m(int)}}number of connections each new node forms; default = 2{p_end}
{synopt:{opth prob(float)}}probability that new node connects to existing nodes uniformly at random; default = 0{p_end}
{synopt:{opt weights(p1, p2,...)}}probabilities p_k for tie weights k{p_end}
{synopt:{opt undirected}}generate an undirected network; default = directed{p_end}
{synopt:{opt name}({it:{help newnetname}})}name of the new network{p_end}
{synopt:{opt xvars}}generate Stata variables for the network{p_end}
{synopt:{opth ntimes(int)}}number of small-world networks to be generated; default = 1{p_end}

{title:Description}

{pstd}
{cmd:nwpref} generates a (un-)directed, (un-)weighted preferential-attachment network using the Barabasi-Albert (1999) model. The network 
begins with an initial connected network of {it:m_0} nodes. One new node is added 
to the network at each time {it:t}. The preferential attachment process is stated as follows:

{pstd}
With a probability {it:0 <= prob <= 1}, this new node connects to {it:m <= m_0} nodes
uniformly at random.

{pstd} 
With a probability {it:1 - prob}, this new node connects to {it:m} existing nodes with a 
probability proportional to their current (in-)degree.

{pstd}
With option {bf:weights(}{it:p1, p2,...}{bf:)} the command generates a weighted network. Here,
{it:p_k} stands for the probability to sample tie weight {it:k}. The probabilities {it:p1, p2..., pn}
do not necessarily have to sum up to one; they are standardized. For example, the following
assigns a tie weight to each tie because of option {bf:weights()}. In this case,
{bf:weights(0.0, 0.3,0.7)} indicates that tie weight 1 should be sampled with probability 0.0, tie weight 2 with
probability 0.3 and tie weight 3 with probability 0.7. 

	{cmd}. nwpref 20, prob(1) undirected weights(0.0, 0.3, 0.7)
{txt}



{title:Supported network types}

{pstd}
Binary: yes (only structural attachment - see Weighted). Directed: yes, via {opt undirected} (default is directed). Weighted: yes, via {opt weights()} - a Stata expression assigning each new tie's value, independent of the preferential-attachment mechanism itself (which is always driven by degree, not tie value). Signed: not checked. Two-mode: not applicable - this generator always produces a one-mode network.

{title:References}

{pstd}
Barabasi, A-L., Albert, R. (1999). Emergence of scaling in random networks. {it:Science} 286(54439),
509-512.


{title:Examples}
	
	{cmd:. nwclear}
	{cmd:. nwpref 20, undirected}
	{cmd:. nwplot, layout(circle)}
	
	{cmd:. nwpref 20, prob(1) undirected}
	{cmd:. nwplot, layout(circle)}

	
{title:See also}

	{help nwsmall}, {help nwrandom}, {help nwlattice}, {help nwring}

last certified : 24 Aug 2026
