{smcl}
{* *! version 2.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwhierarchy {hline 2}}Hierarchical clustering of nodes (role/position analysis){p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwhierarchy}
[{it:{help netname}}]
{cmd:,}
[{opt context}({it:{help nwdissimilar##context:context}})
{opt type}({it:{help nwdissimilar##type:type}})
{opt linkage}({it:{help cluster linkage:linkage}})
{opth groups(int)}
{opth equivgen(newvarname)}
{opt replace}]

{p 8 17 2}
{cmdab: nwhierarchy}
{cmd:,}
{opt dismat(matname)}
[{opt linkage}({it:{help cluster linkage:linkage}}) {opth groups(int)} {opth equivgen(newvarname)} {opt replace}]

{p 8 17 2}
{cmdab: nwhierarchy}
{cmd:,}
{opth disnet(netname)}
[{opt linkage}({it:{help cluster linkage:linkage}}) {opth groups(int)} {opth equivgen(newvarname)} {opt replace}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt type}({it:{help nwdissimilar##type:type}})}Type of dissimilarity between two nodes; default = euclidean{p_end}
{synopt:{opt context}({it:{help nwdissimilar##context:context}})}Context definition for dissimilarity calculation; default = both{p_end}
{synopt:{opt linkage}({it:{help cluster linkage:linkage}})}Clustering linkage method (e.g. {cmd:singlelinkage}, {cmd:averagelinkage}, {cmd:completelinkage}); default = {cmd:singlelinkage}{p_end}
{synopt:{opth groups(int)}}Cut the resulting dendrogram into this many role/position equivalence classes, generated as an ordinary Stata variable{p_end}
{synopt:{opth equivgen(newvarname)}}Name of the variable {opth groups(int)} generates; default = {it:_role}. Ignored unless {opth groups(int)} is specified (alias: {opt generate()}, matching {help nwcommunity}/{help nwspectral}'s own naming in this same group){p_end}
{synopt:{opt replace}}Replace an existing {opth equivgen(newvarname)} variable{p_end}

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
{cmd:nwhierarchy} performs hierarchical clustering of a network's nodes based on their pairwise
structural dissimilarity (by default, computed the same way {help nwdissimilar} computes it - see
that command's own {opt type()}/{opt context()} options, which {cmd:nwhierarchy} passes straight
through) and returns a Stata {help cluster:cluster analysis} object built via {help clustermat}.

{pstd}
{opt dismat()}, {opt disnet()}, and {opt type()}/{opt context()} are three alternative ways to supply
the pairwise dissimilarity {cmd:nwhierarchy} clusters on, not independent options - the single
{cmd:syntax} statement accepts all of them together with no validation, so if more than one is given,
only one is actually used: {opt dismat()} wins if specified at all; otherwise {opt disnet()} wins if
specified; otherwise {opt type()}/{opt context()} (computed via {help nwdissimilar}) is used. The
others are silently ignored, not combined or warned about - specify only one.

{pstd}
This is the clustering step of a three-stage {bf:role/position analysis} workflow: {help nwdissimilar}
(or {help nwsimilar}, inverted) computes how structurally similar every pair of nodes is; {cmd:nwhierarchy}
builds a dendrogram from those distances; and {opth groups(int)} (below) cuts that dendrogram into a
fixed number of role/position equivalence classes, generated as an ordinary per-node Stata variable -
directly analogous to {help nwcomponents}' own single component-id-variable output, except the
partition here is by structural role rather than by connectivity.

{pstd}
{opth groups(int)}, when specified, additionally cuts the dendrogram into exactly that many groups
(via Stata's own {cmd:cluster generate ..., groups()}) and stores the result in {opth equivgen(newvarname)}
(default {it:_role}) - one call in place of first working out {cmd:clustermat}'s own auto-generated
cluster-object name (never itself returned in {cmd:r()}, so it cannot otherwise be recovered
programmatically) and then calling {cmd:cluster generate} by hand. Without {opth groups(int)}, {cmd:nwhierarchy}
behaves exactly as before - only the cluster object itself is created (usable with {help cluster} and
{help clustermat}'s own full postestimation suite, e.g. {help nwdendrogram} or {cmd:cluster dendrogram}
directly), and no {it:_role}-style variable is generated.

{title:Stored results}

{pstd}
{cmd:nwhierarchy} is {cmd:rclass}. The following are only set when {opth groups(int)} is specified:

	Scalars
	  {bf:r(groups)}		number of role/position groups requested

	Macros
	  {bf:r(rolevar)}		name of the generated role/position variable

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwhierarchy flomarriage}
	{cmd:. cluster dendrogram _clus_1}

{pstd}
The full role/position workflow, cutting directly to a usable per-node role variable:

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwhierarchy flomarriage, groups(3)}
	{cmd:. tab _role}
	{cmd:. nwdendrogram _nwhierarchy_role, label(_nwnode)}

{pstd}
Using a specific dissimilarity type/context, and a custom variable name:

	{cmd:. nwhierarchy flomarriage, type(hamming) context(outgoing) groups(3) equivgen(role3)}

{title:Supported network types}

{pstd}
Same network-type support as the underlying dissimilarity computation - see
{help nwdissimilar:nwdissimilar}'s own "Supported network types" section when using the
default {opt context()}/{opt type()} form. The {opt dismat()} and {opt disnet()}
forms bypass {cmd:nwdissimilar} entirely and use whatever matrix/network you supply directly -
{cmd:nwhierarchy} does not itself validate that it is a genuine dissimilarity matrix (symmetric,
zero diagonal, nonnegative). Stata's own {help clustermat} (which does the actual clustering)
requires a matrix with no missing values, including on the diagonal.

{title:See also}

	{help nwdissimilar}, {help nwsimilar}, {help nwcomponents}, {help cluster}, {help clustermat},
	{help nwdendrogram}

last certified : 24 Aug 2026
