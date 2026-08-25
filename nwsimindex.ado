/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwsimindex {hline 2}}Common-neighbor similarity indices between all node pairs{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwsimindex}
[{it:{help netname}}]
[{cmd:,}
{opt measure(string)}
{opth name(newnetname)}
{opt xvars}
{opt replace}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt measure(common|jaccard|dice|cosine|adamicadar)}}Which similarity index to compute; default = {it:jaccard}{p_end}
{synopt:{opth name(newnetname)}}Name of the new similarity network; default = {it:simindex}{p_end}
{synopt:{opt xvars}}Generate Stata variables for the new network{p_end}
{synopt:{opt replace}}Replace an existing network of the same name{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwsimindex} computes a common-neighbor similarity index (Liben-Nowell and Kleinberg 2007) for
every pair of nodes and stores the result as a new, valued, undirected network {help newnetname}
(default: {it:simindex}). These indices measure how much two nodes' neighborhoods overlap - a
standard building block for link prediction, structural-equivalence/role analysis, and as an input
to blockmodeling or one-mode projection (see {help nw2project}).

{pstd}
All calculations use the undirected neighbor sense: for directed networks, a node's neighbor set is
the union of its out- and in-neighbors (the same convention {help nwkcore} uses), since neighborhood
overlap is a direction-agnostic question. {it:measure} is one of:

{p 8 12 2}{bf:common}{p_end}
{p 12 12 2}the raw count of shared neighbors, {it:|N(i) intersect N(j)|}{p_end}
{p 8 12 2}{bf:jaccard} (default){p_end}
{p 12 12 2}{it:|N(i) intersect N(j)| / |N(i) union N(j)|}{p_end}
{p 8 12 2}{bf:dice}{p_end}
{p 12 12 2}the Sorensen-Dice coefficient, {it:2|N(i) intersect N(j)| / (|N(i)| + |N(j)|)}{p_end}
{p 8 12 2}{bf:cosine}{p_end}
{p 12 12 2}the Salton cosine similarity, {it:|N(i) intersect N(j)| / sqrt(|N(i)| * |N(j)|)}{p_end}
{p 8 12 2}{bf:adamicadar}{p_end}
{p 12 12 2}Adamic-Adar, {it:sum over shared neighbors k of 1/log(degree(k))} - weights rare
(low-degree) shared neighbors more heavily than common ones{p_end}

{pstd}
The similarity of a node with itself is not defined and is set to missing, as are any pairs where
the underlying formula is undefined - most notably {bf:cosine} between two isolate nodes (0/0). This
mirrors how {help nwgeodesic} reports an undefined diameter/radius rather than silently coercing an
undefined value to 0.


{title:Supported network types}

{pstd}
Binary: yes (only) - similarity is computed from binary neighbor-set overlap; tie values are ignored. Directed: yes - each node's neighbor set is the union of its out- and in-neighbors (the same convention {help nwkcore} uses). Weighted: not applicable. Signed: not applicable. Two-mode: not checked.

{title:Stored results}

	Scalars
	  {bf:r(nodes)}		number of nodes

	Macros
	  {bf:r(measure)}	the measure used
	  {bf:r(netname)}	name of the new similarity network

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwsimindex flomarriage, measure(jaccard)}
	{cmd:. nwsummarize simindex, matonly}

{title:References}

{pstd}
Liben-Nowell, D., Kleinberg, J. (2007). The link-prediction problem for social networks. {it:Journal
of the American Society for Information Science and Technology} 58(7), 1019-1031.

{pstd}
Adamic, L.A., Adar, E. (2003). Friends and neighbors on the Web. {it:Social Networks} 25(3), 211-230.

{title:See also}

	{help nwsimilar}, {help nw2project}, {help nwkcore}, {help nwburt}

***/

capture program drop nwsimindex
program nwsimindex, rclass
	version 12
	syntax [anything(name=netname)][, measure(string) name(string) xvars replace]

	local measure = lower("`measure'")
	if "`measure'" == "" {
		local measure "jaccard"
	}
	_opts_oneof "common jaccard dice cosine adamicadar" "measure" "`measure'" 6556

	nw_syntax `netname'

	if "`name'" == "" {
		local name "simindex"
	}
	// replace, when given, reuses the exact requested name (drop then
	// recreate) rather than silently auto-incrementing to a different one
	// - the ordinary, non-surprising meaning of "replace" elsewhere in this
	// package (e.g. nwkcore's generate()/replace). nw_validate's own
	// r(validname) auto-increments unconditionally on a name collision,
	// which is only applied here when replace was NOT given.
	nw_validate `name'
	if "`r(exists)'" == "true" {
		if "`replace'" == "" {
			di "{txt}Warning! Switched to netname {res}`r(validname)'{txt} because {res}`name'{txt} already in use."
			local name = r(validname)
		}
		else {
			capture nwdrop `name'
		}
	}

	tempname __nw_sim
	mata: `__nw_sim' = `netobj'->calculate_similarity_index("`measure'")

	nwset, mat(`__nw_sim') name(`name') undirected labs(`labs')
	mata: mata drop `__nw_sim'

	nw_syntax `name'
	mata: `netobj'->set_valued(1)

	return scalar nodes = `nodes'
	return local measure "`measure'"
	return local netname "`name'"

	di "{hline 40}"
	di "{txt}  Similarity network: {res}`name'"
	di "{txt}  Measure: {res}`measure'"
	di "{txt}  Nodes: {res}`nodes'"
	di "{hline 40}"

	if "`xvars'" != "" {
		nwload `name'
	}
end
