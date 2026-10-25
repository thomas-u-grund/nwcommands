{smcl}
{* *! version 1.0.0  31aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##information:[NW-2.4] Information}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwmotifs {hline 2}}4-node undirected motif/graphlet census{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwmotifs}
[{it:{help netname}}]
[{cmd:,}
{opt silent}
{opt plot}
{opt name(string)}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt plot}}Draw a bar chart of the 7 category counts{p_end}
{synopt:{opt name(string)}}Name for the graph created by {opt plot}; default = {bf:motifs}{p_end}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwmotifs} classifies every induced 4-node subgraph of the network into one of 6
"motif" shapes (Milo et al. 2002's own term for a small, recurring, structurally-distinct
connectivity pattern), plus a residual bucket for the other, disconnected 4-node cases - the
same "every case exhaustively accounted for" census convention {help nwtriads}'s own 3-node
MAN census already established one dimension down, generalized here to 4 nodes.

{pstd}
The 6 connected shapes, by increasing edge count:

    path     = a-b-c-d, an open 3-edge chain (degrees 1,2,2,1)
    star     = a tied to b, c, and d, with b/c/d mutually untied (degrees 3,1,1,1)
    cycle    = a-b-c-d-a, a closed 4-edge square (degrees 2,2,2,2)
    paw      = a triangle plus one pendant tie (degrees 3,2,2,1)
    diamond  = the complete graph on 4 nodes minus one edge (degrees 3,3,2,2)
    k4       = the complete graph on 4 nodes (degrees 3,3,3,3)

{pstd}
Every other 4-node induced subgraph (empty, a single tie, either of the two 2-edge shapes, or
a triangle plus an isolated 4th node) is disconnected and is reported under {bf:disconnected}
instead - none of these is a meaningful connected structural pattern in the motif sense.
{bf:path}+{bf:star}+{bf:cycle}+{bf:paw}+{bf:diamond}+{bf:k4}+{bf:disconnected} always sums to
exactly the total number of 4-node combinations in the network.

{pstd}
Classified by (edge count, sorted degree sequence) alone - a COMPLETE invariant for 4-node
graphs (every one of the 11 non-isomorphic 4-vertex graphs has its own unique combination of
the two), so no general graph-isomorphism check is needed.

{pstd}
{cmd:nwmotifs} reports a plain census with no significance test of its own - it needs none:
because every count is published as an ordinary {cmd:r()} scalar, {help nwcug}'s existing
{opt stat()}/{opt rname()} template machinery already works against it unmodified, the same
"compose with existing infrastructure" pattern {help nwlambda} uses with {help nwhierarchy}.
To test whether a shape is over- or under-represented relative to a random graph of the same
size and density:

{phang2}{cmd:. nwcug mynet, stat(nwmotifs ##net##, silent) rname(cycle) condition(density)}{p_end}

{pstd}
substituting {bf:path}/{bf:star}/{bf:cycle}/{bf:paw}/{bf:diamond}/{bf:k4} for whichever shape's
prevalence is of interest, and {opt condition(census)} for a directed network to hold the
mutual/asymmetric/null dyad counts fixed instead of just density (see {help nwcug} for the full
set of conditioning/tail/reps options this test supports).

{pstd}
{opt plot} draws a bar chart of the 7 category counts, via this package's own established
preserve/rebuild-a-plotting-dataset/restore convention - the same one {help nwcug}'s own
{opt plot} option and {help nwtriads}'s own {opt plot} option (its 3-node analogue) use.
Grayscale by design, matching every other plot this package produces.

{title:Valued networks}

{pstd}
This measure uses the presence of ties only (R has no weighted form of it either). On a valued network ({help nwnetworktypes}) the command prints the line "(note: tie values are ignored; this measure is binary)" once (not with {opt silent} or {cmd:quietly}) and treats every tie as present. To choose which ties count, make a binary copy with {help nwdichotomize} first.

{title:Supported network types}

{pstd}
Binary: yes. Directed: the command still runs, but every tie is treated as undirected (a
directed 4-node census has 218 distinct isomorphism classes and is not attempted here); a note
is printed to this effect. Weighted: not applicable (a motif census is inherently a binary
count). Signed: not checked. Two-mode: not checked. Requires at least 4 nodes.

{title:Limits}

{pstd}
The census is not obtained by listing the {it:n}({it:n}-1)({it:n}-2)({it:n}-3)/24 four-node sets. The numbers of
stars, paths, 4-cycles, triangles with a pendant tie, diamonds and complete 4-sets are counted as subgraphs from the
degrees, the triangles on each tie and the common neighbours of node pairs (time proportional to the number of ties
times the largest degree), and turned into counts of {it:induced} subgraphs with the exact inclusion relations between
the six connected shapes; the disconnected count is the remainder of the total. The result is identical to the
enumeration. Measured in Stata/BE on a random network with 10 ties drawn per node: 300 / 1,000 / 5,000 nodes take
0.007 / 0.015 / 0.06 seconds (the enumeration did not finish in 3 minutes at 300 nodes). Counts are exact up to the
size of a 64-bit integer; stored as Stata scalars they are exact up to 9 x 10^15 (about 20,000 nodes' worth of
four-node sets).

{title:Stored results}

    Scalars
      {bf:r(path)}          count of 4-node path (P4) subgraphs
      {bf:r(star)}          count of 4-node star (K1,3) subgraphs
      {bf:r(cycle)}         count of 4-node cycle (C4/square) subgraphs
      {bf:r(paw)}           count of paw (triangle + pendant) subgraphs
      {bf:r(diamond)}       count of diamond (K4 minus one edge) subgraphs
      {bf:r(k4)}            count of complete-graph (K4) subgraphs
      {bf:r(disconnected)}  count of every other, disconnected 4-node case

    Macros
      {bf:r(netname)}       name of the network

{title:Examples}

    {cmd:. nwwebuse florentine, nwclear}
    {cmd:. nwmotifs flomarriage}
    {cmd:. nwcug flomarriage, stat(nwmotifs ##net##, silent) rname(cycle) condition(density)}

{title:References}

{pstd}
Milo, R., Shen-Orr, S., Itzkovitz, S., Kashtan, N., Chklovskii, D., Alon, U. (2002). Network
Motifs: Simple Building Blocks of Complex Networks. {it:Science} 298(5594), 824-827.

{title:See also}

    {help nwtriads}, {help nwcug}, {help nwclustering}

last certified : 31 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.5.0, 25 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
