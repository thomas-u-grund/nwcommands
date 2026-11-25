{smcl}
{* *! version 2.0.0  8jul2016}{...}
{marker topic}
{helpb nwtopical##information:[NW-2.4] Information}

{title:Title}

{p2colset 5 18 22 2}{...}
{p2col :nwtriads  {hline 2}}Triad census of a network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwtriads}
[{help netname}]
[{cmd:,}
{opt plot}
{opt expected}
{opt name(string)}
{opt saving(filename)}
{opt export(filename[, options])}
{it:twoway_options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt plot}}Draw the 16 triad types as small pictures with their counts{p_end}
{synopt:{opt expected}}With {opt plot}: the expected count of every type under random dyad types (dyad census fixed) under the count{p_end}
{synopt:{opt name(string)}}Name for the graph created by {opt plot}; default = {bf:triads}{p_end}
{synopt:{opt sav:ing(filename)}}Save the graph to a {cmd:.gph} file; an existing file is replaced{p_end}
{synopt:{opt exp:ort(filename[, options])}}Write the graph with {helpb graph export}; the file extension sets the format{p_end}
{synopt:{it:twoway_options}}Other options of {helpb twoway}, applied last; without {opt plot}, {opt saving()}, {opt export()} and these options give an error{p_end}
{p2colreset}{...}

{title:Description}

{pstd}
Returns the triad census of the network. This is a way to characterize a network based on its triads.

{pstd}
Each unique triad (triple of nodes {it:i}, {it:j}, and {it:k})
in a directed network can be one of the following:

	003  = i,j,k, empty triad.
	012  = i->j, k, triad with a single directed edge.
	102  = i<->j, k, triad with a reciprocated tie between two vertices.
	021D = i<-j->k, triadic out-star.
	021U = i->j<-k triadic in-star.
	021C = i->j->k, directed line.
	111D = i<->j<-k
	111U = i<->j->k.
	030T = i->j<-k, i->k.
	030C = i<-j<-k, i->k.
	201  = i<->j<->k.
	120D = i<-j->k, i<->k.
	120U = i->j<-k, i<->k.
	120C = i->j->k, i<->k.
	210  = i->j<->k, i<->k.
	300  = i<->j<->k, i<->k,  complete triad.
 
 {pstd}
 This is the so called MAN notation. As in {help nwdyads} it characterized a triad
 by the number of 1) mutual dyads, 2) asymmetric dyads and 3) null dyads. For example,
 MAN = 102 means that there is one mutual dyad and two null dyads.

{pstd}
{opt plot} draws each of the 16 triad types as a small picture of three nodes and their
ties, with the MAN code and the number of triads of that type underneath. On an undirected
network it draws the four types an undirected network can have (003, 102, 201, 300).
{help nwdyads} has the same option for the dyad census.


{title:Network types}

{pstd}
{bf:Directed:} the census is defined for directed networks; on an undirected one only {bf:_003}, {bf:_102}, {bf:_201}
and {bf:_300} can be non-zero (with a note). {bf:Valued:} tie values are ignored (with a note). {bf:Two-mode:} same as
for the bipartite graph read as a one-mode network (no triangles; transitivity 0; use {help nwclustering}).
{bf:Signed:} negative values are not treated specially. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
The census is counted in the compiled graph plugin (the native kernel of {cmd:nwcommands}) when the plugin of your platform has it,
and in Mata otherwise; both give the same counts. It follows Batagelj and Mrvar (2001, {it:Social Networks} 23: 237-243): triads with at least two ties are
enumerated from the neighbours of each node, the empty triads {bf:_003} are obtained by subtraction. A network with self-loops always takes the Mata route. The count of empty triads {bf:r(_003)} is an exact integer.{p_end}
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}

{title:Examples}
	
{com}. nwwebuse glasgow, nwclear
{res}
{com}. nwtriads glasgow3
{res}
{txt}    Triad census: {res} glasgow3{txt}

{txt}{ralign 10:003}{col 12}{c |}{ralign 10:012}{col 24}{c |}{ralign 10:021D}{col 36}{c |}{ralign 10:021U}{col 48}{c |}
{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}
{res}{ralign 10:16086}{col 12}{c |}{ralign 10:1401}{col 24}{c |}{ralign 10:4}{col 36}{c |}{ralign 10:8}{col 48}{c |}

{txt}{ralign 10:021C}{col 12}{c |}{ralign 10:030T}{col 24}{c |}{ralign 10:030C}{col 36}{c |}{ralign 10:102}{col 48}{c |}
{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}
{res}{ralign 10:7}{col 12}{c |}{ralign 10:1}{col 24}{c |}{ralign 10:0}{col 36}{c |}{ralign 10:1969}{col 48}{c |}

{txt}{ralign 10:120D}{col 12}{c |}{ralign 10:120U}{col 24}{c |}{ralign 10:120C}{col 36}{c |}{ralign 10:111D}{col 48}{c |}
{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}
{res}{ralign 10:3}{col 12}{c |}{ralign 10:28}{col 24}{c |}{ralign 10:33}{col 36}{c |}{ralign 10:4}{col 48}{c |}

{txt}{ralign 10:111U}{col 12}{c |}{ralign 10:201}{col 24}{c |}{ralign 10:210}{col 36}{c |}{ralign 10:300}{col 48}{c |}
{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}
{res}{ralign 10:1}{col 12}{c |}{ralign 10:17}{col 24}{c |}{ralign 10:26}{col 36}{c |}{ralign 10:12}{col 48}{c |}

{txt}     Transitivity: {res}.4830508474576271

{pstd}
{txt}This example shows, e.g. that in the {it:glasgow3} network, there are 12 triads where all nodes {it:i}, {it:j} and {it:k} are directely connected with each other.


{title:Saving and exporting the graph}

{pstd}
{opt name()} names the graph in memory, {opt saving()} writes it to a {cmd:.gph} file and {opt export()} writes it with {helpb graph export}: the file extension sets the format, and {cmd:width()} and the
other {cmd:graph export} options follow a comma. A graph or file of the same name is replaced; a trailing {cmd:, replace} is accepted and ignored. Other options go to {helpb twoway} and come last, so they
replace the defaults. 

{phang2}{cmd:. nwwebuse florentine, nwclear}{p_end}
{phang2}{cmd:. nwtriads flomarriage, plot export(triads.png, width(1200))}{p_end}

{title:Expected counts}

{pstd}
{opt expected} adds, under every count of the {opt plot}, the number of triads of that type expected when the three kinds of dyad (mutual, asymmetric, null) are placed at random on the node pairs with
the dyad census of the network fixed, and an asymmetric tie points either way with probability 1/2.
This is the uniform distribution over the networks with the same dyad census (Holland, P. W., and S. Leinhardt. 1976. Local structure in social networks. {it:Sociological Methodology} 7: 1-45), the
null model of {helpb nwcug} with {opt condition(census)} and of {helpb nwrandom} with {opt census()}. With D = n(n-1)/2 dyads, M mutual, A asymmetric and N null ones, a type with m mutual, a
asymmetric and k null dyads
(the digits of its name) and w labelled forms (1, 6, 3, 3, 3, 6, 6, 6, 6, 2, 3, 3, 3, 6, 6, 1 in the order of the table above) has the expected count C(n,3) w (M)m (A)a (N)k / (2^a (D)3), where (x)j = x(x-1)...(x-j+1).
The formula is exact, not an approximation by simulation. {helpb nwcug} compares one statistic at a time with a null distribution; {opt expected} shows all types at once, without simulation.
A two-mode and a valued network stop with error 198 ({helpb nwdichotomize} first). {opt expected} needs {opt plot}.

{phang2}{cmd:. nwwebuse florentine, nwclear}{p_end}
{phang2}{cmd:. nwtriads flomarriage, plot expected export(triads_expected.png, width(1100))}{p_end}

{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(_003)}}number of empty triads{p_end}
{synopt:{bf:r(_012)}, {bf:r(_102)}, ...}number of triads of each of the other MAN types listed above ({bf:r(_021D)}, {bf:r(_021U)}, {bf:r(_021C)},
{bf:r(_111D)}, {bf:r(_111U)}, {bf:r(_030T)}, {bf:r(_030C)}, {bf:r(_201)}, {bf:r(_120D)}, {bf:r(_120U)}, {bf:r(_120C)}, {bf:r(_210)}){p_end}
{synopt:{bf:r(_300)}}number of complete triads{p_end}
{synopt:{bf:r(transitivity)}}transitivity (global clustering coefficient, see {help nwclustering}); 0 for a two-mode network{p_end}
		
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(name)}}name of the network (alias: {bf:r(netname)}){p_end}
		
		
{title:See also}

	{help nwdyads}

{hline}
{pstd}{it:nwcommands version 3.37.2, 25 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
