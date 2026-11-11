{smcl}
{* *! 15jul2016 Thomas Grund}{...}
{marker topic}
{helpb nwtopical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwpermute {hline 2}}Generate a permutation of a network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwpermute} 
[{it:{help netname}}]
[{cmd:,}
{opth generate(newnetname)}
{opt replace}
{opt nwreplace}
{opt xvars}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newnetname)}}Save permutation as new network{p_end}
{synopt:{opt replace}}Replace existing network with permutation{p_end}
{synopt:{opt nwreplace}}Overwrite the network named in {opt generate()} if it already exists; without it the command stops with an error{p_end}
{synopt:{opt xvars}}Generate Stata variables for the network{p_end}
{synopt:{opt swap}}exchange the partners of two ties at random (Maslov and Sneppen) instead of permuting the labels; keeps every node's degree (directed: out-degree and in-degree; two-mode: both degree sequences) and the tie values{p_end}
{synopt:{opt swaps(#)}}the number of attempted exchanges with {opt swap}; default = ten times the number of ties{p_end}


{title:Description}

{pstd}
Produces a random permutation of the network {help netname}. In such a permutation, the nodes are randomly
reshuffled, while the overall structure of the network remains the same. Either option {bf:replace} or {bf:generate} needs to 
be specified. 

{pstd}
With {opt swap}, the ties are rewired instead: two ties a-b and c-d, picked at random, become a-d and c-b (in an undirected
network, a-d and c-b or a-c and b-d, at random), unless that would make a self-loop or tie a pair that is tied already.
Every node keeps its degree (in a directed network its out-degree and its in-degree), a tie keeps its value, and everything
else about the network is randomized. {opt swaps()} sets the number of attempted exchanges (some are refused). This is the
rewiring of R's {cmd:igraph::rewire(g, keeping_degseq())}: a random network with the degrees of the observed one, the usual
baseline for a pattern that may follow from the degrees alone (see {help nwcug} with {opt condition(degrees)}, and
{help nwrandom} with {opt degree()} for a network drawn from a list of degrees). Self-loops and ties with a missing value stay
where they are. For a one-mode network, {opt swap} uses the native plugin of nwcommands 3.17.0 or later; the exchanges are
drawn from the seed ({cmd:set seed}).

	{cmd:. nwuse glasgow, nwclear}
	{cmd:. nwpermute glasgow1, swap generate(glasgow1_swapped)}

{pstd}
A simple example illustrates what the command does. First, we generate a regular lattice network. 
 
	{com}. nwclear
	. nwlattice 3 3
	{com}. nwsummarize lattice, matonly

	     1   2   3   4   5   6   7   8   9
	  {c TLC}{hline 37}{c TRC}
	1 {c |}  {res}0                                {txt}  {c |}
	2 {c |}  {res}1   0                            {txt}  {c |}
	3 {c |}  {res}0   1   0                        {txt}  {c |}
	4 {c |}  {res}1   0   0   0                    {txt}  {c |}
	5 {c |}  {res}0   1   0   1   0                {txt}  {c |}
	6 {c |}  {res}0   0   1   0   1   0            {txt}  {c |}
	7 {c |}  {res}0   0   0   1   0   0   0        {txt}  {c |}
	8 {c |}  {res}0   0   0   0   1   0   1   0    {txt}  {c |}
	9 {c |}  {res}0   0   0   0   0   1   0   1   0{txt}  {c |}
	  {c BLC}{hline 37}{c BRC}

{pstd}
Now, let us permute the network {it:lattice}.
		
	{com}. nwpermute lattice, replace
	{com}. nwsummarize lattice, matonly

	     1   2   3   4   5   6   7   8   9
	  {c TLC}{hline 37}{c TRC}
	1 {c |}  {res}0                                {txt}  {c |}
	2 {c |}  {res}1   0                            {txt}  {c |}
	3 {c |}  {res}0   0   0                        {txt}  {c |}
	4 {c |}  {res}0   0   1   0                    {txt}  {c |}
	5 {c |}  {res}1   0   0   0   0                {txt}  {c |}
	6 {c |}  {res}0   1   0   1   0   0            {txt}  {c |}
	7 {c |}  {res}0   0   0   0   1   0   0        {txt}  {c |}
	8 {c |}  {res}0   0   1   0   0   0   1   0    {txt}  {c |}
	9 {c |}  {res}0   1   0   1   1   0   0   1   0{txt}  {c |}
	  {c BLC}{hline 37}{c BRC}

{pstd}
The structure of the network remains exactly the same, however, the nodes have a different order. Often,
such a permutation is desired to recalculate network statistics (and derive standard errors and confidence intervals for 
these statistics) while keeping the overall structure of the network constant (see more {help nwqap}, {help nwcorrelate}).	
	
	

{title:Two-mode networks}

{pstd}
Two-mode: yes - the labels are permuted within the modes, so that no tie ever joins two nodes of the same mode ({cmd:tnet::rg_reshuffling_tm}); {opt swap} exchanges the partners of two ties at random and keeps both degree sequences ({cmd:bipartite::swap.web}). {opt swap} works on the list of ties (no n x n matrix) in a kernel of the native plugin when your platform's plugin has it: 100,000 attempts on 5,669 ties take 0.02 seconds; the random exchanges are drawn from the seed ({cmd:set seed}) and are the same on every platform with that kernel, but are not the draws of the Mata routine.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes ({opt swap} keeps out-degrees and in-degrees). Weighted: yes - tie values move with their ties under the random relabeling (a pure permutation of the existing adjacency matrix) and under {opt swap}. Signed: yes, values including negative are preserved. Two-mode: yes - the labels are permuted within the modes, so that no tie ever joins two nodes of the same mode ({cmd:tnet::rg_reshuffling_tm}); {opt swap} exchanges the partners of two ties at random and keeps both degree sequences ({cmd:bipartite::swap.web}).

{title:Example}

{pstd}
	
	{cmd:. nwclear}
	{cmd:. nwrandom 10, prob(.1) name(mynet)}
	{cmd:. nwplot mynet, lab layout(circle)}
	{cmd:. nwpermute mynet, replace}
	{cmd:. nwplot mynet, lab layout(circle)}

{title:Limits}

{pstd}
A network held as stored ties is relabelled tie by tie, with the same permutation for the same seed. 20,000 nodes 0.2 seconds
in Stata/BE (killed at 12 GB before).

{title:See also}

	{help nwqap}, {help nwcorrelate}

last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.18.0, 11 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
