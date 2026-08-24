/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwkcomponents {hline 2}}Maximal k-component enumeration{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwkcomponents}
[{it:{help netlist}}]
[{cmd:,}
{opth k(int)}
{opth generate(newvarname)}
{opt replace}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth k(int)}}Minimum vertex connectivity required; default = 2{p_end}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's largest qualifying k-component size; default = {it:_kcompnum}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwkcomponents} enumerates every maximal k-component (Kanevsky 1993) in the network(s) in
{help netlist} - a subgraph with {it:vertex connectivity} of at least {opth k(int)}, meaning at least
{opth k(int)} nodes would have to be removed from it to disconnect it (or reduce it to a single
node). A k-component is a genuine strengthening of an ordinary connected component (which is just
the {opth k(int)}=1 case - {help nwcomponents} already implements that, more cheaply, via a simple
reachability search rather than a connectivity computation): {opth k(int)}=2 excludes single
cut-vertices/bridges that would fracture the group, {opth k(int)}=3 additionally excludes any
2-node cutset, and so on. This directly formalizes the intuition that a group connected only by a
single "weak link" is less cohesive than one where {it:several independent} paths connect every
pair of members.

{pstd}
{opth k(int)} defaults to 2 - the smallest level that is a genuine refinement of
{help nwcomponents}' own plain connectivity - and must be at least 1 ({help nwcomponents} already
covers that trivial case directly). Vertex connectivity is computed via the standard node-splitting
reduction to max-flow (Even 1979) combined with Menger's theorem (the minimum vertex set separating
any two non-adjacent nodes equals the maximum flow between them in the split graph); the network's
own overall k-components are then found by the standard recursive decomposition also underlying
Moody and White's (2003) cohesive blocking - see {help nwkcomponents##algorithm:Algorithm} below for
the one respect in which this command deliberately does less than the full Moody-White procedure.

{pstd}
Like cliques/k-plexes/n-cliques/n-clans, k-components can genuinely overlap - the nodes whose
removal disconnects a graph (a cutset) remain shared members of every resulting sub-block their
removal reveals, not assigned to just one side - so {cmd:nwkcomponents} follows the same output
shape as {help nwclique}/{help nwkplex}/{help nwnclique}: a single per-node "largest qualifying
k-component size" summary variable ({opth generate(newvarname)}, default {it:_kcompnum}), plus the
complete overlapping structure in {bf:r(kcomp_matrix)} (a k-components-by-nodes 0/1 membership
matrix) and {bf:r(kcomponents)} (count). Unlike those commands there is no {opt minsize()} - a
k-component's own minimum possible size is already {opth k(int)}+1 (a smaller set cannot reach
connectivity {opth k(int)} at all, since the maximum possible connectivity of an s-node graph is
s-1), so there is no equivalent "trivial small case" to filter out separately.

{marker algorithm}{...}
{title:Algorithm}

{pstd}
{cmd:nwkcomponents} computes k-components for exactly the single level {opth k(int)} requested, not
the full Moody-White hierarchy (which recursively re-applies this same procedure at every
increasing connectivity level found, building a complete nested tree from the whole network down to
its most cohesive core). Computing just one target level directly is both simpler to verify by hand
and matches how {help nwkplex}/{help nwnclique} already expose their own single-parameter cohesion
concepts in this package - a full recursive multi-level hierarchy, if wanted later, would be a
natural, separate follow-on built on the same {opth k(int)}-level primitive this command already
provides, not a reason to withhold the single-level version now.

{title:Stored results}

	Scalars
	  {bf:r(kcomponents)}	number of maximal k-components found

	Matrices
	  {bf:r(kcomp_matrix)}	k-components-by-nodes 0/1 membership matrix, one row per maximal k-component

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwkcomponents flomarriage}
	{cmd:. nwkcomponents flomarriage, k(3) replace}


{title:References}

{pstd}
Kanevsky, A. (1993). Finding all minimum-size separating vertex sets in a graph. {it:Networks}
23(6), 533-541.

{pstd}
Moody, J., White, D.R. (2003). Structural cohesion and embeddedness: a hierarchical concept of
social groups. {it:American Sociological Review} 68(1), 103-127.

{pstd}
Even, S. (1979). {it:Graph Algorithms}. Computer Science Press. (the vertex-splitting max-flow
reduction for vertex connectivity)

{pstd}
Wasserman, S., Faust, K. (1994). {it:Social Network Analysis: Methods and Applications}. Cambridge
University Press. (k-components and structural cohesion)


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (vertex connectivity in the classical
Moody-White sense has no directed generalization here, the same reasoning {help nwclique}/
{help nwkplex}/{help nwnclique} already apply). Weighted: not used - only tie presence/absence
affects connectivity. Signed: not checked. Two-mode: not checked. Vertex-connectivity computation
via max-flow is polynomial per pair, but {cmd:nwkcomponents} computes it between {it:every}
non-adjacent pair (a deliberately simple, definitely-correct brute-force rather than the smaller
reference-vertex subset a more optimized algorithm would use - see {help nwclique}'s own
"Supported network types" section for the same trade-off philosophy applied there), and the overall
recursive decomposition can call this repeatedly - fine for the moderate network sizes typical of
SNA datasets, not recommended for very large or very dense networks.

{title:See also}

	{help nwcomponents}, {help nwclique}, {help nwkplex}, {help nwnclique}, {help nwnclan}, {help nwkcore}

***/

capture program drop nwkcomponents
program nwkcomponents, rclass
	version 12
	syntax [anything(name=netname)][, k(int 2) GENerate(string) replace silent]
	set more off

	if `k' < 1 {
		di "{err}k() must be at least 1; k(1) is exactly a connected component - use {help nwcomponents} for that case."
		error 198
	}

	nw_syntax `netname', max(9999)

	if `networks' > 1 {
		local i = 1
	}

	qui foreach netname_temp in `netname' {
		nw_syntax `netname_temp'

		local netgenerate "`generate'"
		if "`netgenerate'" == "" {
			local netgenerate = "_kcompnum"
		}

		capture confirm variable `netgenerate'`i', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`i'} already exists; specify {bf:replace}"
			err 99
		}

		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		nw_syntax `netname_temp'

		tempname __nw_kcomp __nw_sizes __nw_kcompnum
		mata: `__nw_kcomp' = `netobj'->calculate_kcomponents(`k')
		mata: `__nw_sizes' = rowsum(`__nw_kcomp')
		mata: st_numscalar("nw_nkcomp", rows(`__nw_kcomp'))
		mata: st_matrix("nw_kcompmatrix", (rows(`__nw_kcomp') > 0 ? `__nw_kcomp' : J(1, `nodes', 0)))
		mata: `__nw_kcompnum' = (rows(`__nw_kcomp') > 0 ? editvalue(colmax(`__nw_kcomp' :* `__nw_sizes')', 0, .) : J(`nodes', 1, .))

		capture drop `netgenerate'`i'
		gen `netgenerate'`i' = .
		mata: st_store((1::`nodes'), "`netgenerate'`i'", `__nw_kcompnum')
		mata: mata drop `__nw_kcomp' `__nw_sizes' `__nw_kcompnum'

		return scalar kcomponents = nw_nkcomp
		return matrix kcomp_matrix = nw_kcompmatrix
		local lkcomp = nw_nkcomp

		// see nwbrokerage.ado's own header comment: the "already
		// exists" probe above leaves _rc stale even after a fully
		// successful run - reset explicitly and silently.
		capture confirm variable `netgenerate'`i', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Maximal `k'-components: {res}`lkcomp'"
			noi sum `netgenerate'`i'
			noi di " "
		}
		local i = `=`i' + 1'
	}
end
