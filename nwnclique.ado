/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwnclique {hline 2}}Maximal n-clique enumeration{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwnclique}
[{it:{help netlist}}]
[{cmd:,}
{opth n(int)}
{opth generate(newvarname)}
{opt replace}
{opth minsize(int)}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth n(int)}}Maximum geodesic distance allowed between any two members; default = 2{p_end}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's largest maximal-n-clique membership size; default = {it:_ncliquenum}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opth minsize(int)}}Smallest n-clique size to report; default = 3{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwnclique} enumerates every maximal n-clique in the network(s) in {help netlist} - a
generalization of an ordinary clique (Luce 1950) where every pair of members need only be within
geodesic distance {opth n(int)} of {it:each other in the network as a whole}, rather than directly
tied. A plain clique is the special case {opth n(int)}=1 (distance-1 "neighbors" are exactly direct
ties) - {help nwclique} already handles that case with a cheaper, purpose-built algorithm, so
{cmd:nwnclique} requires {opth n(int)} >= 2.

{pstd}
Because n-clique membership is judged by whole-network distance, a pair of members can qualify even
though the shortest path between them runs through a node that is not itself part of the n-clique -
a well-known limitation of the concept (Alba 1973): an n-clique's own members are not guaranteed to
be reachable from one another {it:while staying inside the group}. {help nwnclan} adds exactly that
extra requirement.

{pstd}
Like cliques, n-cliques genuinely overlap - a node can belong to several at once - so {cmd:nwnclique}
follows {help nwclique}'s own output shape: a single per-node "largest maximal n-clique membership
size" summary variable ({opth generate(newvarname)}, default {it:_ncliquenum}), plus the complete
overlapping structure in {bf:r(nclique_matrix)} (an n-cliques-by-nodes 0/1 membership matrix) and
{bf:r(ncliques)} (count). {opth minsize(int)} filters out n-cliques smaller than the given size
before generating and returning results, matching {help nwclique}'s own default of 3 (a dyad or an
isolated node is technically a maximal n-clique too, but rarely what "n-clique" is meant to convey).
A node that belongs to no n-clique meeting {opth minsize(int)} gets a missing value in the generated
variable, not a spurious 0.

{title:Stored results}

	Scalars
	  {bf:r(ncliques)}		number of maximal n-cliques found meeting {opth minsize(int)}

	Matrices
	  {bf:r(nclique_matrix)}	n-cliques-by-nodes 0/1 membership matrix, one row per maximal n-clique

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwnclique flomarriage}
	{cmd:. nwnclique flomarriage, n(3) replace}


{title:References}

{pstd}
Luce, R.D. (1950). Connectivity and generalized cliques in sociometric group structure.
{it:Psychometrika} 15(2), 169-190.

{pstd}
Alba, R.D. (1973). A graph-theoretic definition of a sociometric clique. {it:Journal of Mathematical
Sociology} 3(1), 113-126.

{pstd}
Wasserman, S., Faust, K. (1994). {it:Social Network Analysis: Methods and Applications}. Cambridge
University Press. (cliques and cohesive subgroups)


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (an n-clique's own definition has no directed
generalization, the same reasoning {help nwclique}/{help nwkplex} already apply). Weighted: not
used for membership - {opth n(int)} counts hops, not tie strength, though the underlying distance
calculation ({help nwgeodesic}'s own unweighted, {cmd:alpha(0)}-equivalent convention) is unaffected
by weight either way. Signed: not checked. Two-mode: not checked - operates on the network's own
square adjacency matrix. Maximal n-clique enumeration inherits {help nwclique}'s own worst-case
exponential behaviour (a mathematical property of maximal-clique-family problems in general) - fine
for the moderate network sizes typical of SNA datasets, not specially guarded against here.

{title:See also}

	{help nwnclan}, {help nwclique}, {help nwkplex}, {help nwkcomponents}, {help nwgeodesic}, {help nwkcore}

***/

capture program drop nwnclique
program nwnclique, rclass
	version 12
	syntax [anything(name=netname)][, n(int 2) GENerate(string) replace minsize(int 3) silent]
	set more off

	if `n' < 2 {
		di "{err}n() must be at least 2; n(1) is exactly a clique - use {help nwclique} for that case."
		error 198
	}

	if `minsize' < 1 {
		di "{err}minsize() must be a positive integer."
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
			local netgenerate = "_ncliquenum"
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

		tempname __nw_nclq __nw_sizes __nw_nclqnum
		mata: `__nw_nclq' = `netobj'->calculate_nclique_filtered(`n', `minsize')
		mata: `__nw_sizes' = rowsum(`__nw_nclq')
		mata: st_numscalar("nw_nncliq", rows(`__nw_nclq'))
		mata: st_matrix("nw_ncliquematrix", (rows(`__nw_nclq') > 0 ? `__nw_nclq' : J(1, `nodes', 0)))
		mata: `__nw_nclqnum' = (rows(`__nw_nclq') > 0 ? editvalue(colmax(`__nw_nclq' :* `__nw_sizes')', 0, .) : J(`nodes', 1, .))

		capture drop `netgenerate'`i'
		gen `netgenerate'`i' = .
		mata: st_store((1::`nodes'), "`netgenerate'`i'", `__nw_nclqnum')
		mata: mata drop `__nw_nclq' `__nw_sizes' `__nw_nclqnum'

		return scalar ncliques = nw_nncliq
		return matrix nclique_matrix = nw_ncliquematrix
		local lncliq = nw_nncliq

		// see nwbrokerage.ado's own header comment: the "already
		// exists" probe above leaves _rc stale even after a fully
		// successful run - reset explicitly and silently.
		capture confirm variable `netgenerate'`i', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Maximal `n'-cliques (size >= `minsize'): {res}`lncliq'"
			noi sum `netgenerate'`i'
			noi di " "
		}
		local i = `=`i' + 1'
	}
end
