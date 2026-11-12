{smcl}
{* *! version 2.0.0  7jul2016}{...}
{marker topic}
{helpb nwtopical##information:[NW-2.4] Information}

{title:Title}

{p2colset 9 16 22 2}{...}
{p2col :nwdyads  {hline 2}}Dyad census{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwdyads} 
[{it:{help netname}}]
[{cmd:,}
{opt plot}
{opt name(string)}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt plot}}Draw the dyad types as small pictures with their counts{p_end}
{synopt:{opt name(string)}}Name for the graph created by {opt plot}; default = {bf:dyads}{p_end}
{p2colreset}{...}

{pstd}
{it:netname} may be a list of networks or a wildcard such as {cmd:lazega_*}, as in {help nwsummarize}; the census is shown for each network and the {cmd:r()} results are those of the last one.


{title:Description}

{pstd}
Returns the dyad census of a network (or a list of networks). This is a way to characterize a network based on its dyads.

{pstd}
In directed networks, each dyad (pair of nodes {it:i} and {it:j}) can be one of the following:

{pmore}
1) M: mutually connected: {it:M_ij = M_ji = 1}

{pmore}
2) A: asymmetrically connected: {it:M_ij = 1}, but {it:M_ji = 0} 

{pmore}
3) N: not connected at all: {it:M_ij = M_ji = 0}


{pstd}
In undirected network, each dyad (pair of nodes {it:i} and {it:j}) can be one of the following:

{pmore}
1) M: connected: {it:M_ij = M_ji = 1}

{pmore}
2) N: unconnected:  {it:M_ij = M_ji = 0}

{pstd}
The command also returns the reciprocity of the network.

{pmore}
{it:reciprocity = M / (M + A)}


{title:Network types}

{pstd}
{bf:Directed:} mutual, asymmetric and null dyads; an undirected network has mutual and null dyads only. {bf:Valued:} tie
values are ignored (every tie counts as present; the command prints a note). {bf:Two-mode:} yes - the null dyads are
counted over the pairs of nodes from different modes; reciprocity is shown as n/a. {bf:Signed:} not applicable. See
{help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
A network held as stored ties is counted from its ties (each tie is matched with its reverse): 20,000 nodes 0.08 seconds and 0.2 GB
in Stata/BE.


{title:Examples}
	
	{cmd:. nwwebuse florentine}
	{com}. nwdyads flomarriage
	{res}
	{txt}    Dyad census: {res} flomarriage{txt}

	{txt}{ralign 10:Mutual}{col 20}{c |}{ralign 10:Null}
	{hline 11}{c +}{hline 11}
	{res}{ralign 10:20}{col 20}{c |}{ralign 10:100}

	{com}. nwdyads flomarriage, plot

	{com}. nwwebuse glasgow
	{com}. nwdyads glasgow3
	{res}
	{txt}    Dyad census: {res} glasgow3{txt}

	{txt}{ralign 10:Mutual}{col 20}{c |}{ralign 10:Asym}{col 32}{c |}{ralign 10:Null}
	{hline 11}{c +}{hline 11}{c +}{hline 11}
	{res}{ralign 10:45}{col 20}{c |}{ralign 10:32}{col 32}{c |}{ralign 10:1148}{txt}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(_100)}}mutual dyads{p_end}
{synopt:{bf:r(_010)}}asymmetric dyads{p_end}
{synopt:{bf:r(_001)}}null dyads{p_end}
{synopt:{bf:r(reciprocity)}}M / (M + A){p_end}
	  
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(name)}}name of network{p_end}
{synopt:{bf:r(netname)}}name of network (same as {bf:r(name)}){p_end}


{title:See also}

	{help nwtriads}

{hline}
{pstd}{it:nwcommands version 3.21.0, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
