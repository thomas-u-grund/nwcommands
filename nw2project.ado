/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nw2project {hline 2} One-mode projection of a two-mode network}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nw2project}
[{it:{help netname}}]
{cmd:,}
{opt project(1|2)}
[{opth name(newnetname)}
{opt stat(string)}
{opt xvars}
{opt replace}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt project(1|2)}}Mode/level to collapse to{p_end}
{synopt:{opth name(newnetname)}}Name of the new one-mode network; default = {it:project}{p_end}
{synopt:{opt stat(min|max|minmax|sum|mean)}}How to combine tie values on a valued two-mode network; default = {it:minmax}{p_end}
{synopt:{opt xvars}}Do not generate Stata variables for the new network{p_end}
{synopt:{opt replace}}Replace an existing network of the same name{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
Sometimes one wants to collapse a two-mode network to a one-mode network. This is called a one-mode
projection. Such a projection is a simplification of the network to nodes of one level only. The level
to which one wants to collapse is specified in option {bf:project()}.

{pstd}
For example, this loads a two-mode network and projects it onto level 1:

	{cmd:. nw2project mynet, project(1) name(myproject1)}

{pstd}
By default, a one-mode projection on one level generates ties between nodes (on this level) when they
have at least one network neighbor on the other level in common.

{pstd}
When the source network is {bf:unvalued}, the tie value in the projection is simply the number of
shared neighbors on the other level (e.g. the number of institutions two people share).

{pstd}
When the source network is {bf:valued}, option {bf:stat()} controls how the tie values of the two
original ties (ego-to-shared-neighbor and alter-to-shared-neighbor) are combined, for every shared
neighbor, into a single projected tie value:

{p 8 12 2}{bf:stat(min)}{p_end}
{p 12 12 2}the overall minimum across all ego/alter-to-shared-neighbor tie values{p_end}
{p 8 12 2}{bf:stat(max)}{p_end}
{p 12 12 2}the overall maximum across all ego/alter-to-shared-neighbor tie values{p_end}
{p 8 12 2}{bf:stat(sum)}{p_end}
{p 12 12 2}the sum across all ego/alter-to-shared-neighbor tie values{p_end}
{p 8 12 2}{bf:stat(mean)}{p_end}
{p 12 12 2}the mean across all ego/alter-to-shared-neighbor tie values{p_end}
{p 8 12 2}{bf:stat(minmax)} (default){p_end}
{p 12 12 2}for each shared neighbor, take the minimum of the ego/alter tie values to that
neighbor, then take the maximum of those minima across all shared neighbors -
substantively, the strongest shared bond{p_end}

{pstd}
For example, suppose Peter and Thomas are both affiliated with Oxford (Peter: 7 years, Thomas: 5
years) and LiU (Peter: 1 year, Thomas: 1 year). Then:

		{c TLC}{hline 12}{c -}{hline 8}{c TRC}
		{c |} stat      {c |} value  {c |}
		{c LT}{hline 12}{c -}{hline 8}{c RT}
		{c |} min       {c |}   1    {c |}
		{c |} max       {c |}   7    {c |}
		{c |} sum       {c |}  14    {c |}
		{c |} mean      {c |} 3.5    {c |}
		{c |} minmax    {c |}   5    {c |}
		{c BLC}{hline 12}{c -}{hline 8}{c BRC}

{title:Stored results}

	Scalars
	  {bf:r(nodes)}		number of nodes in the projected network
	  {bf:r(ties)}		number of ties in the projected network


{title:Supported network types}

{pstd}
Binary: yes. Directed: not checked - the source two-mode network's ties are treated as undirected
affiliations. Weighted: {bf:W1}, native - an unvalued source network projects to a shared-neighbor
{it:count} (the standard bipartite-projection tie weight); a valued source network projects using
{opt stat()}'s explicit choice of combination rule (see above) - tie strength is never silently
discarded or reinterpreted as a distance. Signed: not checked. Two-mode: {bf:T3} - this command's
entire purpose is projecting a two-mode network down to one mode, so the projection is always
explicit and user-requested (via {opt project()}), never a silent side effect of some other
operation - the canonical, correct way to project in this package.


{title:See also}

	{help nw2set}, {help nw2fromedge}, {help nw2toedge}, {help nw2clustering}

***/

capture program drop nw2project
program nw2project, rclass
	version 12
	syntax [anything(name=netname)], PROJECT(integer) [name(string) stat(string) xvars replace]

	if `project' != 1 & `project' != 2 {
		di "{err}project() must be 1 or 2"
		error 198
	}

	local stat = lower("`stat'")
	if "`stat'" == "" {
		local stat "minmax"
	}
	_opts_oneof "min max minmax sum mean" "stat" "`stat'" 6556

	nw_syntax `netname'

	if "`is2mode'" != "true" {
		di "{err}Network {bf:`netname'} is not a two-mode network; nw2project requires a two-mode network (see {help nw2set})."
		error 198
	}

	if "`name'" == "" {
		local name "project"
	}
	// replace, when given, reuses the exact requested name (drop then
	// recreate) rather than silently auto-incrementing to a different one.
	// nw_validate's own r(validname) auto-increments unconditionally on a
	// name collision; unconditionally taking it (as this line used to)
	// meant replace never actually replaced anything - name was already
	// switched to the incremented name before the "if replace" block
	// below even ran, so that block dropped a network that was never
	// going to be reused anyway. Found and fixed while building
	// nwsimindex, which had copied this same pattern - see its own
	// docs/CERTIFICATION.md entry.
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

	tempname __nw_names __nw_edges

	mata: `__nw_names' = nw2project_names(`netobj', `project')
	mata: `__nw_edges' = nw2project_edges(`netobj', `project', "`stat'")

	mata: st_numscalar("nodes", cols(`__nw_names'))
	mata: st_numscalar("ties", rows(`__nw_edges'))

	mata: nw.nws.add("`name'")
	nw_syntax `name'
	mata: `netobj'->create_by_name_sparse(`__nw_names')
	mata: `netobj'->set_directed(0)
	mata: `netobj'->set_edge_from_triplets(`__nw_edges'[.,1], `__nw_edges'[.,2], `__nw_edges'[.,3], 0)
	mata: `netobj'->set_valued(1)

	mata: mata drop `__nw_names' `__nw_edges'

	return scalar nodes = nodes
	return scalar ties = ties

	di "{hline 40}"
	di "{txt}  Projected network: {res}`name'"
	di "{txt}  Level: {res}`project'"
	// A bare local-macro-style reference to r(nodes) here would treat
	// "r(nodes)" as a LOCAL MACRO NAME to look up, not an r-class scalar
	// reference, so it silently expands to "" (Stata does not error on an
	// undefined local) - that was the original bug. An expression-
	// substitution reference to r(nodes) is not the fix either: a
	// "return scalar" statement only PUBLISHES r() to the caller when
	// this program actually exits, so r(nodes) reads as missing from
	// inside the same program body that just set it (confirmed via an
	// isolated repro before settling on this fix - a subtlety worth
	// remembering). The underlying Stata scalars "nodes"/"ties" set via
	// st_numscalar() above ARE immediately readable within this scope, so
	// reference those directly instead of the not-yet-published
	// r()-result.
	di "{txt}  Nodes: {res}`=nodes'"
	di "{txt}  Ties: {res}`=ties'"

	if "`xvars'" == "" {
		nwload `name'
	}
end

capture mata: mata drop nw2project_sel()
capture mata: mata drop nw2project_names()
capture mata: mata drop nw2project_edges()
mata:

/*
	Global node indices (column vector, 1..n) of the nodes at the requested
	two-mode level. modes is a string ROW vector, so selectindex() (which
	preserves input orientation) returns a row vector too - transposed here
	to the column-vector convention nw2project_edges() indexes throughout.
*/
real matrix nw2project_sel(pointer(class nw_def scalar) scalar p, real scalar level){
	return(selectindex(p->get_modes() :== strofreal(level))')
}

string rowvector nw2project_names(pointer(class nw_def scalar) scalar p, real scalar level){
	real matrix sel
	sel = nw2project_sel(p, level)
	return(p->get_nodenames()[1, sel'])
}

/*
	Standard bipartite-projection algorithm: for each selected-level node i,
	visit its other-level neighbors q; for each q, visit q's same-level
	neighbors j (i's "co-members" via q) and accumulate the requested
	statistic over every (i,j) pair that shares at least one such q.
	Complexity is O(sum_i deg(i) * avg_deg(neighbor)) - the standard,
	expected cost for this algorithm (same as igraph/NetworkX bipartite
	projection), not O(n^2): a sparse affiliation network yields a cheap
	projection regardless of how many total nodes exist at the far level.
	Returns an nout x 3 (ego_local, alter_local, weight) matrix using local
	1..nsel indices into nw2project_names()'s output, symmetric (each pair
	appears twice, (a,b) and (b,a)) since a projection is always undirected.
*/
real matrix nw2project_edges(pointer(class nw_def scalar) scalar p, real scalar level, string scalar stat){
	real scalar nsel, valued, oa, ob, oi, oq, k, l, wiq, wjq, thismin, val, nout
	real matrix sel, localidx, nb, nb2
	real matrix minval, maxval, sumval, cntval, minmaxval, sharedcount
	real matrix ego_tmp, alter_tmp, weight_tmp, out

	sel = nw2project_sel(p, level)
	nsel = rows(sel)
	valued = p->is_valued_boolean()

	localidx = J(p->get_nodes(), 1, 0)
	for (oa=1; oa<=nsel; oa++){
		localidx[sel[oa,1], 1] = oa
	}

	minval = J(nsel, nsel, .)
	maxval = J(nsel, nsel, .)
	minmaxval = J(nsel, nsel, .)
	sumval = J(nsel, nsel, 0)
	cntval = J(nsel, nsel, 0)
	sharedcount = J(nsel, nsel, 0)

	for (oa=1; oa<=nsel; oa++){
		oi = sel[oa,1]
		nb = p->neighbors(oi)
		for (k=1; k<=rows(nb); k++){
			oq = nb[k,1]
			wiq = p->edge_weight(oi, oq)
			nb2 = p->neighbors(oq)
			for (l=1; l<=rows(nb2); l++){
				ob = localidx[nb2[l,1], 1]
				if (ob > oa){
					wjq = p->edge_weight(nb2[l,1], oq)
					sharedcount[oa,ob] = sharedcount[oa,ob] + 1
					sumval[oa,ob] = sumval[oa,ob] + wiq + wjq
					cntval[oa,ob] = cntval[oa,ob] + 2
					if (minval[oa,ob] == . | wiq < minval[oa,ob]) minval[oa,ob] = wiq
					if (minval[oa,ob] == . | wjq < minval[oa,ob]) minval[oa,ob] = wjq
					if (maxval[oa,ob] == . | wiq > maxval[oa,ob]) maxval[oa,ob] = wiq
					if (maxval[oa,ob] == . | wjq > maxval[oa,ob]) maxval[oa,ob] = wjq
					thismin = min((wiq,wjq))
					if (minmaxval[oa,ob] == . | thismin > minmaxval[oa,ob]) minmaxval[oa,ob] = thismin
				}
			}
		}
	}

	ego_tmp = J(nsel*nsel, 1, 0)
	alter_tmp = J(nsel*nsel, 1, 0)
	weight_tmp = J(nsel*nsel, 1, 0)
	nout = 0

	for (oa=1; oa<=nsel; oa++){
		for (ob=(oa+1); ob<=nsel; ob++){
			if (sharedcount[oa,ob] > 0){
				if (!valued){
					val = sharedcount[oa,ob]
				}
				else if (stat == "min"){
					val = minval[oa,ob]
				}
				else if (stat == "max"){
					val = maxval[oa,ob]
				}
				else if (stat == "sum"){
					val = sumval[oa,ob]
				}
				else if (stat == "mean"){
					val = sumval[oa,ob] / cntval[oa,ob]
				}
				else {
					val = minmaxval[oa,ob]
				}
				nout = nout + 1
				ego_tmp[nout,1] = oa
				alter_tmp[nout,1] = ob
				weight_tmp[nout,1] = val
				nout = nout + 1
				ego_tmp[nout,1] = ob
				alter_tmp[nout,1] = oa
				weight_tmp[nout,1] = val
			}
		}
	}

	if (nout == 0){
		return(J(0,3,0))
	}
	out = J(nout,3,0)
	out[.,1] = ego_tmp[(1::nout),1]
	out[.,2] = alter_tmp[(1::nout),1]
	out[.,3] = weight_tmp[(1::nout),1]
	return(out)
}
end
