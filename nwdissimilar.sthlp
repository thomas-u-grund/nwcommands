{smcl}
{* *! version 1.0.0  21april2014}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nw_topical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}


{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwdissimilar {hline 2}}Generate node dissimilarities{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwdissimilar} 
[{it:{help netname}}]
{cmd:,}
[{opt type}({it:{help nwdissimilar##type:type}})
{opt context}({it:{help nwdissimilar##context:context}})
{opt name}({it:{help newnetname}})
{opt xvars}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt type}({it:{help nwdissimilar##type:type}})}Type of dissimilarity between two nodes; default = euclidean{p_end}
{synopt:{opt context}({it:{help nwdissimilar##context:context}})}Context definition for dissimilarity calculation; default = both{p_end}
{synopt:{opt name}({it:{help newnetname}})}Name of the new dissimilarity network; default = {it:_dissimilar}{p_end}
{synopt:{opt xvars}}Generate Stata variables for the network{p_end}

{synoptset 15 tabbed}{...}
{marker type}{...}
{p2col:{it:type}}{p_end}
{p2line}
{p2col:{cmd: euclidean}}Calculate Euclidean distance between the tie vectors of two nodes{p_end}
{p2col:{cmd: manhatten}}Calculate Manhatten distance between the tie vectors of two nodes{p_end}
{p2col:{cmd: hamming}}Calculate Hamming distance between the tie vectors of two nodes{p_end}
{p2col:{cmd: jaccard}}Calculate Jaccard distance between the tie vectors of two nodes{p_end}
{p2col:{cmd: nonmatches}}Calculate percentage of non-matches in tie vectors of two nodes{p_end}

{synoptset 15 tabbed}{...}
{marker context}{...}
{p2col:{it:context}}{p_end}
{p2line}
{p2col:{cmd: both}}Calculate dissimilarity between nodes based on both in- and outgoing ties{p_end}
{p2col:{cmd: incoming}}Calculate dissimilarity between nodes based on incoming ties only{p_end}
{p2col:{cmd: outgoing}}Calculate dissimilarity between nodes based on outgoing ties only{p_end}


{title:Description}

{pstd}
This command calculates the dissimilarities between all nodes {it:i} and {it:j} and saves the result in a new network. The dissimilarity between two nodes reflects how dissimilar these nodes
are regarding the ties they have to other nodes (tie vectors). 

{pstd}
By default, the dissimilarity is calculated based on both incoming and outgoing ties ({bf:context(both)}). With {bf:context(incoming)} the dissimilarity
between two nodes {it:i} and {it:j} is calculated only based on the ties they receive (columns). Option {bf:context(outgoing)} only considers outgoing ties (rows) when calculating the dissimilarity
between nodes. Practially, option {bf:context(both)} stacks the vector of outgoing and incoming ties.


{pstd}
{bf:Euclidean distance:}

{pstd}
The Euclidean distance between two tie vectors is equal to the square root of the sum of the squared differences between them.  That is, the
strength of actor A's tie to C is subtracted from the strength of actor B's tie to C, and the difference is squared.  This is then repeated across
all the other actors (D, E, F, etc.), and summed.  The square root of the sum is then taken.

{pmore}
{it:D_ij = sqrt(sum((i_outvec :- j_outvec):^2) + sum((i_invec :- j_invec):^2))}


{pstd}
{bf:Manhatten distance:}

{pstd}
This distance is simply the sum of the absolute difference between the actor's ties to each alter, summed across the alters.

{pmore}
{it:D_ij = sum(abs(i_outvec :- j_outvec)) + sum(abs(i_invec :- j_invec))}


{pstd}
{bf:Hamming distance:}

{pstd}
The Hamming distance is the number of entries in the tie vector for one actor that would need to be changed in order to make it identical
to the tie vector of the other actor.  These differences could be either adding or dropping a tie, so the Hamming distance treats joint
absence as similarity.

{pmore}
{it:D_ij = sum(i_outvec :!= j_outvec) + sum(i_invec :!= j_invec)}


{pstd}
{bf:Jaccard distance:}

{pstd}
The Jaccard distance is simply: 1 - Jaccard index. The Jaccard index of two tie vectors A and B is the the number of ties that exist in both A and B divided by 
the total number of ties that exist either in A or in B. When the tie profiles of nodes {it:i} and {it:j} are exactly the same the Jaccard index equals 1. 

{pmore}
{it:D_ij = 1 - sum(A :!= 0 and B :!= 0) / sum(A :!= 0 or B :!= 0)}


{pstd}
{bf:Nonmatches distance:}

{pstd}
Simply gives the percentage of dyads (tie or non-tie) that nodes {it:i} and {it:j} have in NOT common with the same alters. Notice that {it:i} and {it:j} are excluded from
from these alters.

{pmore}
{it:D_ij = 1 - (sum(i_outvec :== j_outvec) + sum(i_invec :== j_invec)) / 2 * (n - 1)



{title:Example}

{cmd:. webnwuse florentine}
{cmd:. nwdissimilar flomarriage}

{cmd:. nwdissimilar flomarriage, type(hamming) context(outgoing)}


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes ({bf:context()} lets you restrict the comparison to incoming or
outgoing ties only, which only matters for a directed network - an undirected network's
in-ties and out-ties are identical, so all three {bf:context()} values agree). Weighted:
{bf:euclidean}/{bf:manhatten} use tie weights directly in their distance formula (a genuinely
weighted-aware comparison); {bf:hamming}/{bf:jaccard}/{bf:nonmatches} binarize each tie
({it:present vs. absent}) before comparing, so tie strength does not affect these three - not
checked for automatic behavior beyond this, choose {bf:type()} to match whether tie strength
should matter. Signed: not checked - a negative tie weight participates in {bf:euclidean}/
{bf:manhatten}'s arithmetic like any other value, and in the binarizing types' {cmd: != 0} test
like any nonzero value, but no dedicated signed-network semantics exist. Two-mode: not
supported - operates on the network's own square adjacency matrix; a genuinely two-mode
(non-square, disjoint node-set) input is not checked and not expected to behave sensibly.
The dissimilarity network itself always carries a genuine (non-missing) diagonal of 0 (a node
is never dissimilar from itself) and inherits its source network's own node labels by default,
so it can be compared directly against the source network node-for-node.

{title:See also}

	{help nwsimilar}, {help nwcorrelate}, {help nwhierarchy}
