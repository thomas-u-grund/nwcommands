{smcl}
{* *! version 2.0.0  1dec2016: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwdyadprob {hline 2}}Generate a network based on tie probabilities{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwdyadprob} 
[{it:{help netname}}]
[{cmd:,}
{opt mat(matamatrix)}
{opth density(float)}
{opt weights(p1, p2,...)}
{opth name(netname)}
{opt xvars}
{opt undirected}
{opt labs}({it:lab1 lab2 ...})]


{synoptset 21 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mat}({it:matrix})}Mata matrix (or Mata expression) with tie probabilities{p_end}
{synopt:{opth density(float)}}density of the new network{p_end}
{synopt:{opt weights(p1, p2,...)}}probabilities p_k for tie weights k{p_end}
{synopt:{opth name(netname)}}name of the new random network{p_end}
{synopt:{opt xvars}}generate Stata variables for the network{p_end}
{synopt:{opt undirected}}generate undirected network{p_end}
{synopt:{opt labs}({it:lab1 lab2 ...})}overwrite node labels{p_end}


{title:Description}

{pstd}
{cmd:nwdyadprob} generates a (un-)directed random network where each tie {it:x_ij} has the 
probability {it:p_ij} to exist. The values for {it:p_ij} are derived either 1) from the tie values
of network {help netname} or 2) from a Mata matrix (or Mata expression) specified in {bf:mat()}. When both are given,
{it:netname} is used. The command can be used to create all sorts of networks.

{pstd}
When no {bf:density()} is given, each tie {it:x_ij} is drawn independently with probability {it:p_ij}. Let {it:e_ij} be
the tie values of network {help netname}. When all of them lie between 0 and 1, {it:p_ij = e_ij}. Otherwise they are
transformed to probabilities first: {it:p_ij} = invlogit({it:e_ij}). The values in {bf:mat()} are used as they are.

{pstd}
With {bf:density(}{it:d}{bf:)}, exactly {it:n}({it:n}-1){it:d} ties (half as many with {opt undirected}) are drawn
without replacement, with inclusion probabilities proportional to the tie values {it:e_ij} of {help netname} (or to the
values in {bf:mat()}). The values are relative weights and are used as they are, also when they are larger than 1; they
cannot be negative. The command stops with an error when fewer dyads have a non-zero weight than ties are requested.

{pstd}
With option {bf:weights(}{it:p1, p2,...}{bf:)} the command generates a weighted network. Here,
{it:p_k} stands for the probability to sample tie weight {it:k}. The probabilities {it:p1, p2..., pn}
do not necessarily have to sum up to one; they are standardized.


{title:Remarks}

{pstd}
The program needs no additional packages: the weighted sampling of ties is built in (it gives the same sample as the user-written {bf:gsample}, for the same random-number seed). Nothing is downloaded
or installed.


{title:Network types}

{pstd}
{bf:Directed:} directed by default; {opt undirected} gives an undirected network. {bf:Valued:} {opt weights()} draws tie
values, only without {opt density()} (with {opt density()} it stops with an error). {bf:Two-mode:} not applicable - the command
always creates a one-mode network. {bf:Signed:} not checked. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
With {opt mat()} the probabilities are an {it:n}-by-{it:n} matrix held by you plus three copies in the command: 20,000 nodes
3.1 seconds. {opt density()} weights all dyads and is refused above 7,071 nodes.


{title:Example}

{pstd} 
The following example generates a network where ties are more likely to exist between nodes 
with similar {it:gender} and different {it:race}.

{pstd}
First, we generate two variables {it:gender} and {it:race}. 
	
	{cmd:. nwclear}
	{cmd:. set obs 10}
	{cmd:. gen gender = (_n > 5) + 2}
	{cmd:. gen race = int(0.5 + uniform())}

{pstd}
Next, we generate two expanded networks for each of the two variables (see {help nwexpand}). Basically, 
we generate for each variable a matrix {it:M} where {it:M_ij} = 1 when nodes {it:i} and {it:j} have the same
score on an attribute. And these matrices {it:M} are used to generate new networks.

	{cmd:. nwexpand gender}
	{cmd:. nwexpand race}
	
{pstd}
This creates the following networks.

	{com}. nwset
	{res}{txt}(2 networks)
	{hline 20}
		{res}same_gender
		{res}same_race{txt}

{pstd}
Having a closer look at the new network {it:same_gender}, shows the network that {help nwexpand} created.		
	
	{com}. nwsummarize same_gender, matonly

	       1    2    3    4    5    6    7    8    9   10
	   {c TLC}{hline 51}{c TRC}
	 1 {c |}  {res} 0                                             {txt}  {c |}
	 2 {c |}  {res} 1    0                                        {txt}  {c |}
	 3 {c |}  {res} 1    1    0                                   {txt}  {c |}
	 4 {c |}  {res} 1    1    1    0                              {txt}  {c |}
	 5 {c |}  {res} 1    1    1    1    0                         {txt}  {c |}
	 6 {c |}  {res} 0    0    0    0    0    0                    {txt}  {c |}
	 7 {c |}  {res} 0    0    0    0    0    1    0               {txt}  {c |}
	 8 {c |}  {res} 0    0    0    0    0    1    1    0          {txt}  {c |}
	 9 {c |}  {res} 0    0    0    0    0    1    1    1    0     {txt}  {c |}
	10 {c |}  {res} 0    0    0    0    0    1    1    1    1    0{txt}  {c |}
	   {c BLC}{hline 51}{c BRC}
	 
{pstd}
In the next step, we generate a network {it:dyadweight} on the basis of {it:same_gender} and
{it:same_race}.

{pstd}
As an example, we want that in the final network 1) ties between nodes with the same gender 
are overrepresented and 2) ties between nodes with the same race are underrepresented. This generates
tie probabilitities according to this request.  
	
	{cmd:. nwgen dyadweight = exp(5 * same_gender) * exp((-5) * same_race)}

{pstd}
Check out the tie values created in this way:

	{cmd:. nwsummarize dyadweight, matonly}
	
{pstd}
Finally, we create a new network based on tie probabilities defined in network {it:dyadweight}.

	{cmd:. nwdyadprob dyadweight, density(0.1)}
	
{pstd}
The result can be nicely plotted in the following way:

	{cmd:. nwplot, color(gender) layout(circle) title("gender, homophily = exp(5)")}
	{cmd:. graph save g4, replace}
	{cmd:. nwplot, color(race) layout(circle) title("race, homophily = exp(-5)")}
	{cmd:. graph save g5, replace}
	{cmd:. graph combine g4.gph g5.gph }


{title:See also}

	{help nwhomophily}, {help nwgen}, {help nwexpand}

{hline}
{pstd}{it:nwcommands version 3.20.1, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
