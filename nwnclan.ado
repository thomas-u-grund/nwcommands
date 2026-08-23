/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwnclan {hline 2}}Maximal n-clan enumeration{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwnclan}
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
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's largest maximal-n-clan membership size; default = {it:_nclannum}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opth minsize(int)}}Smallest n-clan size to report; default = 3{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwnclan} enumerates every maximal n-clan (Mokken 1979) in the network(s) in {help netlist} - an
{help nwnclique:n-clique} (see that command for the base concept and {opth n(int)}) that additionally
requires every pair of its own members to be reachable from one another {it:while staying inside the
group}, within {opth n(int)} steps. An ordinary n-clique only guarantees each pair's shortest path in
the {it:whole} network is within {opth n(int)} - that path may run through a node that is not itself
one of the n-clique's own members, a known limitation of the plain n-clique concept (Alba 1973).
n-clans fix exactly that: every member must be able to reach every other member using only paths that
never leave the group.

{pstd}
{cmd:nwnclan} works by first enumerating every maximal n-clique (the same computation
{help nwnclique} itself performs) and then keeping only the ones whose own induced subgraph - built
from the {it:original} network, restricted to just that n-clique's members - has every pair of
members within {opth n(int)} steps of {it:each other, using only ties between members}. This matches
the standard treatment of n-clans in the literature: a maximal n-clique that fails this check is
simply not reported as a clan at all, rather than being replaced with some smaller, clan-qualifying
subset of itself - a genuine, deliberate limitation of the concept, not a shortcut taken here. Every
n-clan is therefore also an n-clique, but not every n-clique is an n-clan; on a network with no
"shortcut" structure (e.g. a network where every node's shortest paths to everyone else already stay
within whatever locally-dense region it belongs to) the two coincide exactly.

{pstd}
Like n-cliques, n-clans genuinely overlap, so {cmd:nwnclan} follows {help nwnclique}'s own output
shape: a single per-node "largest maximal n-clan membership size" summary variable
({opth generate(newvarname)}, default {it:_nclannum}), plus the complete overlapping structure in
{bf:r(nclan_matrix)} and {bf:r(nclans)}. {opth minsize(int)} defaults to 3, matching
{help nwclique}/{help nwnclique}.

{title:Stored results}

	Scalars
	  {bf:r(nclans)}		number of maximal n-clans found meeting {opth minsize(int)}

	Matrices
	  {bf:r(nclan_matrix)}	n-clans-by-nodes 0/1 membership matrix, one row per maximal n-clan

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwnclan flomarriage}
	{cmd:. nwnclan flomarriage, n(3)}


{title:References}

{pstd}
Mokken, R.J. (1979). Cliques, clubs and clans. {it:Quality and Quantity} 13(2), 161-173.

{pstd}
Alba, R.D. (1973). A graph-theoretic definition of a sociometric clique. {it:Journal of Mathematical
Sociology} 3(1), 113-126.

{pstd}
Wasserman, S., Faust, K. (1994). {it:Social Network Analysis: Methods and Applications}. Cambridge
University Press. (cliques and cohesive subgroups)


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (same reasoning {help nwnclique} already
applies). Weighted: not used for membership. Signed: not checked. Two-mode: not checked. Inherits
{help nwnclique}'s own worst-case exponential enumeration cost, plus an additional per-candidate
induced-subgraph diameter check - fine for the moderate network sizes typical of SNA datasets.

{title:See also}

	{help nwnclique}, {help nwclique}, {help nwkplex}, {help nwkcomponents}, {help nwgeodesic}, {help nwkcore}

***/

capture program drop nwnclan
program nwnclan, rclass
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
			local netgenerate = "_nclannum"
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

		tempname __nw_nclan __nw_sizes __nw_nclannum
		mata: `__nw_nclan' = `netobj'->calculate_nclan_filtered(`n', `minsize')
		mata: `__nw_sizes' = rowsum(`__nw_nclan')
		mata: st_numscalar("nw_nnclan", rows(`__nw_nclan'))
		mata: st_matrix("nw_nclanmatrix", (rows(`__nw_nclan') > 0 ? `__nw_nclan' : J(1, `nodes', 0)))
		mata: `__nw_nclannum' = (rows(`__nw_nclan') > 0 ? editvalue(colmax(`__nw_nclan' :* `__nw_sizes')', 0, .) : J(`nodes', 1, .))

		capture drop `netgenerate'`i'
		gen `netgenerate'`i' = .
		mata: st_store((1::`nodes'), "`netgenerate'`i'", `__nw_nclannum')
		mata: mata drop `__nw_nclan' `__nw_sizes' `__nw_nclannum'

		return scalar nclans = nw_nnclan
		return matrix nclan_matrix = nw_nclanmatrix
		local lnclan = nw_nnclan

		// see nwbrokerage.ado's own header comment: the "already
		// exists" probe above leaves _rc stale even after a fully
		// successful run - reset explicitly and silently.
		capture confirm variable `netgenerate'`i', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Maximal `n'-clans (size >= `minsize'): {res}`lnclan'"
			noi sum `netgenerate'`i'
			noi di " "
		}
		local i = `=`i' + 1'
	}
end
