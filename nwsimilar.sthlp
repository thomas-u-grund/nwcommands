{smcl}
{* *! version 1.0.0  21april2015}{...}
{marker topic}
{helpb nwtopical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nwtopical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}


{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwsimilar {hline 2}}Generate node similarities{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwsimilar} 
[{it:{help netname}}]
{cmd:,}
[{opt type}({it:{help nwsimilar##type:type}})
{opt context}({it:{help nwsimilar##context:context}})
{opt name}({it:{help newnetname}})
{opt xvars}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt type}({it:{help nwsimilar##type:type}})}Type of similarity between two nodes; default = pearson{p_end}
{synopt:{opt context}({it:{help nwsimilar##context:context}})}Context definition for similarity calculation; default = both (alias: {opt mode()}, kept for backward compatibility - {help nwdissimilar}, this command's own sibling, uses {opt context()} for the identical concept){p_end}
{synopt:{opt name}({it:{help newnetname}})}Name of the new similarity network; default = {it:_similar}{p_end}
{synopt:{opt xvars}}Generate Stata variables for the network{p_end}
{synopt:{opt force}}Run the command although its matrices would not fit in memory (it stops with r(484) above about 12,900 nodes otherwise){p_end}

{synoptset 15 tabbed}{...}
{marker type}{...}
{p2col:{it:type}}{p_end}
{p2line}
{p2col:{cmd: pearson}}Calculate Pearson correlation for tie vectors of two nodes{p_end}
{p2col:{cmd: hamming}}Calculate Hamming distance between the tie vectors of two nodes{p_end}
{p2col:{cmd: jaccard}}Calculate the Jaccard coefficient of the tie vectors of two nodes (shared neighbours divided by the neighbours of either node; with {cmd:context(both)} the out- and in-neighbours are pooled){p_end}
{p2col:{cmd: matches}}Calculate percentage of matches in tie vectors of two nodes{p_end}
{p2col:{cmd: crossproduct}}Calculate the cross-product of the tie vectors of two nodes, the sum over all other nodes k of w_ik*w_jk (the number of common contacts in a binary network){p_end}

{synoptset 15 tabbed}{...}
{marker context}{...}
{p2col:{it:mode}}{p_end}
{p2line}
{p2col:{cmd: both}}Calculate dissimilarity between nodes based on both in- and outgoing ties{p_end}
{p2col:{cmd: incoming}}Calculate dissimilarity between nodes based on incoming ties only{p_end}
{p2col:{cmd: outgoing}}Calculate dissimilarity between nodes based on outgoing ties only{p_end}



{title:Description}

{pstd}
This command calculates the similarities between all nodes {it:i} and {it:j} and saves the result in a new network. The similarity between two nodes reflects how similar these nodes
are regarding the ties they have to other nodes (tie vectors). 

{pstd}
By default, the similarity is calculated based on both incoming and outgoing ties ({bf:mode(both)}). With {bf:mode(incoming)} the similarity
between two nodes {it:i} and {it:j} is calculated only based on the ties they receive (columns). Option {bf:mode(outgoing)} only considers outgoing ties (rows) when calculating the similarity
between nodes. Practially, option {bf:mode(both)} stacks the vector of outgoing and incoming ties.


{pstd}
{bf:Pearson similarity:}

{pstd}
This measure calculates the Pearson correlation coefficient for two tie vectors of nodes {it:i} and {it:j}. See {help nwcorrelate##nodes:here for more information} on this (see also {help nwcorrelate}. 


{pstd}
{bf:Hamming similarity:}

{pstd}
The Hamming similarity is the number of entries in the tie vectors of nodes {it:i} and {it:j} that are identical. Notice that the Hamming similarity treats joint
absence as similarity as well.

{pmore}
{it:D_ij = sum(i_outvec :== j_outvec) + sum(i_invec :== j_invec)}


{pstd}
{bf:Jaccard similarity:}

{pstd}
The Jaccard similarity (or Jaccard index) of two tie vectors A and B is the the number of ties that exist in both A and B divided by 
the total number of ties that exist either in A or in B. When the tie profiles of nodes {it:i} and {it:j} are exactly the same the Jaccard index equals 1. In contrast to the
Hamming similarity, the Jaccard similarity does not consider non-ties. 

{pmore}
{it:D_ij = sum(A :!= 0 and B :!= 0) / sum(A :!= 0 or B :!= 0)}


{pstd}
{bf:Matches similarity:}

{pstd}
Simply gives the percentage of dyads (tie or non-tie) that nodes {it:i} and {it:j} have in common with the same alters. Notice that {it:i} and {it:j} are excluded from
from these alters.

{pmore}
{it:D_ij = (sum(i_outvec :== j_outvec) + sum(i_invec :== j_invec)) / 2 * (n - 1)}


{pstd}
{bf:Cross-product similarity:}

{pstd}
Calculates the cross-product of the tie vectors of nodes {it:} and {it:j}

{pmore}
{it:D_ij = (sum(i_outvec :* j_outvec) + sum(i_invec :* j_invec))}


{title:Example}

{cmd:. nwwebuse florentine}
{cmd:. nwsimilar flomarriage}

{cmd:. nwsimilar flomarriage, type(hamming) mode(outgoing)}


{title:Two-mode networks}

{pstd}
Two-mode: yes - a node is compared with the other nodes of its own mode, over the nodes of the other mode (the profile of a person is the set of groups); pairs of nodes from different modes are missing ({cmd:sna::sedist}, {cmd:stats::cor} on the incidence matrix).

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes ({bf:mode()} lets you restrict the comparison to incoming or
outgoing ties only). Weighted: {bf:pearson} (via {help nwcorrelate}) and {bf:crossproduct} use
tie weights directly; {bf:hamming}/{bf:jaccard}/{bf:matches} binarize each tie before comparing,
so tie strength does not affect these three. Signed: not checked. Two-mode: yes - a node is compared with the other nodes of its own mode, over the nodes of the other mode (the profile of a person is the set of groups); pairs of nodes from different modes are missing ({cmd:sna::sedist}, {cmd:stats::cor} on the incidence matrix). The similarity network itself always
carries a genuine (non-missing) diagonal (a node is maximally similar to itself) and inherits
its source network's own node labels, so it can be compared directly against the source network
node-for-node.

{title:Limits}

{pstd}
With the native plugin of nwcommands 3.10.0 or later (plugin generation 12) the cells are formed from the stored ties and not from
dense matrix products: 5,000 nodes of the same network take 0.4 seconds for every type (1.0 to 1.2 seconds with the Mata code, 3.2 seconds for
{opt type(pearson)} after the fix of its repeated evaluation, 10.6 seconds in earlier versions). The results are those of the Mata code
(differences below 1e-13). A network with missing tie values, and a platform whose plugin is older, use the Mata code.

{pstd}
The result is a dense {it:n}-by-{it:n} valued network. Measured in Stata/BE, random directed network with 10 ties per
node: 5,000 nodes 1.1 seconds and 1.9 GB, 10,000 nodes 4 seconds and 7 GB. About 9 matrices of that size are held at once: above
about 12,900 nodes the command stops at once with r(484) and a message with the memory needed (28.8 GB at 20,000 nodes); option
{opt force} runs it anyway. The node labels of the new network are the labels of the old one at any size
(they used to be damaged above about 900 nodes).

{title:See also}

	{help nwdissimilar}, {help nwcorrelate}, {help nwhierarchy}

{hline}
{pstd}{it:nwcommands version 3.13.0, 31 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
