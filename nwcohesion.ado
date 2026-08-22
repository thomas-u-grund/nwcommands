/***
{smcl}
{* *! version 1.0.0  22aug2026 author: Thomas Grund}{...}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwcohesion {hline 2} Moody-White structural cohesion hierarchy{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwcohesion}
[{it:{help netlist}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's own highest cohesion level; default = {it:_cohesion}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwcohesion} computes the full, multi-level Moody and White (2003) cohesive-blocking hierarchy:
starting from the whole network, it recursively finds ever-more-cohesive nested sub-blocks, using
{help nwkcomponents}' own single-level k-component primitive (vertex connectivity via node-splitting
max-flow, Menger's theorem) applied repeatedly at increasing connectivity levels. Where
{help nwkcomponents} answers "which nodes form a block of at least connectivity {opth k(int)}?" for
one chosen {opth k(int)}, {cmd:nwcohesion} answers the fuller question: "what is the complete nested
structure, from the whole network down to its most cohesive cores, and how cohesive is each level?" -
with no {opth k(int)} to choose, since every level actually present in the network is found and
reported.

{pstd}
Each block's own connectivity level is its network's ACTUAL vertex connectivity (not merely the
level searched for) - a disconnected network's own top block is reported at level 0, a network
joined only by a single cut vertex at level 1, and so on. Levels found deeper in the hierarchy can
skip values (e.g. a level-1 block can have level-3 children directly, with no level-2 block ever
appearing) - a well-documented real property of structural cohesion, not a limitation of this
implementation.

{pstd}
Like {help nwkcomponents}, blocks can genuinely overlap (a cutset remains a shared member of every
sub-block its removal reveals) and nest (a child block's own node set is always a strict subset of
its parent's), so the complete structure is returned via {bf:r(cohesion_matrix)} (a blocks-by-nodes
0/1 membership matrix, one row per block found at ANY level of the hierarchy) and
{bf:r(cohesion_levels)} (a parallel column vector giving each row's own connectivity level).
{opth generate(newvarname)} (default {it:_cohesion}) stores, per node, the HIGHEST level of any
block that node belongs to - the standard node-level structural-cohesion summary statistic - and is
always well-defined for every node (even an isolate gets its own top-block level, typically 0),
unlike {help nwkcomponents}' own {it:_kcompnum}, which is missing for nodes that don't qualify for
the one requested {opth k(int)}.

{title:Stored results}

	Scalars
	  {bf:r(blocks)}	number of cohesive blocks found across the whole hierarchy

	Matrices
	  {bf:r(cohesion_matrix)}	blocks-by-nodes 0/1 membership matrix, one row per block at any level
	  {bf:r(cohesion_levels)}	blocks-by-1 column vector of each row's own connectivity level

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcohesion flomarriage}


{title:References}

{pstd}
Moody, J., White, D.R. (2003). Structural cohesion and embeddedness: a hierarchical concept of
social groups. {it:American Sociological Review} 68(1), 103-127.

{pstd}
Kanevsky, A. (1993). Finding all minimum-size separating vertex sets in a graph. {it:Networks}
23(6), 533-541.

{pstd}
Even, S. (1979). {it:Graph Algorithms}. Computer Science Press. (the vertex-splitting max-flow
reduction for vertex connectivity)


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (vertex connectivity has no directed
generalization here, matching {help nwkcomponents}). Weighted: not used. Signed: not checked.
Two-mode: not checked. Computationally more expensive than a single {help nwkcomponents} call, since
each block found is itself recursively re-decomposed - fine for the moderate network sizes typical
of SNA datasets.

{title:See also}

	{help nwkcomponents}, {help nwcomponents}, {help nwclique}, {help nwkplex}

***/

capture program drop nwcohesion
program nwcohesion, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace silent]
	set more off

	nw_syntax `netname', max(9999)

	if `networks' > 1 {
		local i = 1
	}

	qui foreach netname_temp in `netname' {
		nw_syntax `netname_temp'

		local netgenerate "`generate'"
		if "`netgenerate'" == "" {
			local netgenerate = "_cohesion"
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

		tempname __nw_hier __nw_cohnum
		mata: `__nw_hier' = `netobj'->calculate_cohesion_hierarchy()
		mata: st_numscalar("nw_nblocks", rows(`__nw_hier'))
		mata: st_matrix("nw_cohesionmatrix", `__nw_hier'[.,2..cols(`__nw_hier')])
		mata: st_matrix("nw_cohesionlevels", `__nw_hier'[.,1])
		mata: `__nw_cohnum' = colmax(`__nw_hier'[.,2..cols(`__nw_hier')] :* `__nw_hier'[.,1])'

		capture drop `netgenerate'`i'
		gen `netgenerate'`i' = .
		mata: st_store((1::`nodes'), "`netgenerate'`i'", `__nw_cohnum')
		mata: mata drop `__nw_hier' `__nw_cohnum'

		return scalar blocks = nw_nblocks
		return matrix cohesion_matrix = nw_cohesionmatrix
		return matrix cohesion_levels = nw_cohesionlevels
		local lblocks = nw_nblocks

		// see nwbrokerage.ado's own header comment: the "already exists"
		// probe above leaves _rc stale even after a fully successful
		// run - reset explicitly and silently.
		capture confirm variable `netgenerate'`i', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Cohesive blocks found: {res}`lblocks'"
			noi sum `netgenerate'`i'
			noi di " "
		}
		local i = `=`i' + 1'
	}
end
