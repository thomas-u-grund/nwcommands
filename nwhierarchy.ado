/***
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

***/

capture program drop nwhierarchy
program nwhierarchy, rclass
	// was the deprecated _nwsyntax wrapper, which only re-exports 4
	// locals (netobj/id/netname/networks) - the same bug class fixed
	// repeatedly elsewhere this session. Nothing below actually
	// referenced any of the locals that wrapper fails to export
	// (confirmed empirically - this file ran correctly even before
	// this change), but switched to the modern nw_syntax anyway for
	// consistency with the rest of the package and to keep the new
	// groups()/equivgen() code below (added in this same unit) safe
	// against ever needing one of those locals in the future.
	syntax [anything(name=netname)] [, dismat(string) disnet(string) linkage(string) type(string) context(string) clear add GROUPS(int -1) EQUIVgen(string) generate(string) replace * ]
	// Naming consistency (moderate-severity pass, community_spectral
	// group): the rest of this group (nwcommunity/nwspectral) and the
	// wider package convention both use `generate()' for "write a
	// per-node partition-id variable" - this command's own help text
	// even describes `equivgen()''s own output as mirroring
	// nwcomponents' `generate()'-produced output shape exactly. Added
	// `generate()' as a working alias, kept `equivgen()' for backward
	// compatibility.
	if "`equivgen'" != "" & "`generate'" != "" {
		di "{err}Specify only one of {bf:equivgen()} or {bf:generate()} (they are the same option) - not both."
		error 198
	}
	if "`generate'" != "" {
		local equivgen "`generate'"
	}
	nw_syntax `netname'

	if "`clear'" == "" & "`add'" == "" {
		local add = "add"
	}

	if "`linkage'" == "" {
		local linkage = "singlelinkage"
	}

	if "`dismat'" == "" {
		local dismat "mymat"
		if "`disnet'" != "" {
			nwtomatafast `disnet'
			mata: st_matrix("`dismat'", `r(mata)')
		}
		else {
			nwdissimilar `netname', type(`type') context(`context') name(_temp_dissimilar)
			nwtomatafast _temp_dissimilar
			mata: st_matrix("`dismat'", `r(mata)')
			nwdrop _temp_dissimilar
		}
	}

	// groups() closes the "role/position analysis" workflow this
	// command was originally packaged for: nwdissimilar computes
	// structural-equivalence distances, nwhierarchy (via clustermat)
	// builds a dendrogram from them, but turning that dendrogram into
	// a single per-node "which equivalence class does this node
	// belong to" variable previously required the caller to already
	// know Stata's own cluster-analysis postestimation syntax
	// (cluster generate ..., groups(#)) and, less obviously, the
	// auto-generated cluster-object name clustermat picks when none is
	// given (_clus_1, _clus_2, ... - not returned in r(), so it
	// cannot be recovered programmatically). groups() does exactly
	// that hand-off internally, using a fixed, deterministic cluster
	// name of its own (dropped and recreated on every call, matching
	// nwcomponents'/nwclique's own generate()/replace convention) so
	// the resulting role/position variable is available as an ordinary
	// Stata variable in one call, mirroring nwcomponents' own
	// component-id-variable output shape exactly.
	if `groups' > 0 {
		local nwhier_clustername "_nwhierarchy_role"
		capture cluster drop `nwhier_clustername'
		clustermat `linkage' `dismat', name(`nwhier_clustername') `add' `clear' `options'

		local netgenerate "`equivgen'"
		if "`netgenerate'" == "" {
			local netgenerate = "_role"
		}
		capture confirm variable `netgenerate', exact
		if _rc == 0 & "`replace'" == "" {
			di "{err}Variable {bf:`netgenerate'} already exists; specify {bf:replace}"
			err 99
		}
		capture drop `netgenerate'
		cluster generate `netgenerate' = groups(`groups'), name(`nwhier_clustername')
		return scalar groups = `groups'
		return local rolevar "`netgenerate'"
	}
	else {
		clustermat `linkage' `dismat', `options' `add' `clear'
	}
	qui nwload `netname', labelonly
end








	
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
