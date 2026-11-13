* xt_meas_brokerage_similarity.do -- extended tests for nwbrokerage, nwsimmelian, nwshared and nwsimindex.
* Run with Stata 17; every check passes since the fixes of the measure suite (fixes-xt).
*
* Covers: the five Gould-Fernandez roles on the directed path 1 -> 2 -> 3 for every grouping (checked
* against sna::brokerage), a closed two-path (1 -> 3 present) is not a brokerage, r(pairs), a string group
* variable (r(109)), the user's scalar brk_pairs; Simmelian ties of an undirected triangle with a tail, of
* a mutual and of a cyclic directed triangle, name exists (r(483)) and nwreplace; shared partners on ties
* (triangle with a tail, K4), directed needs undirected (r(198)); nwsimindex common, jaccard, dice,
* cosine, adamicadar on the path 1-2-3 (hand-derived), measure() errors, name collision rename, r().
* Run from the repository root.

clear all
set more off
set graphics off
do unw_core.do
run cscripts/xt_meas_00_helpers.do
xt_minit xt_meas_brokerage_similarity
nwclear

* ---------------------------------------------------------------- (1) nwbrokerage
* sna::brokerage(m, cl)$raw.nli[2, ] for m = 1 -> 2 -> 3 (columns w_I w_O b_IO b_OI b_O t):
*   cl (1,1,1): 1 0 0 0 0 1   coordinator
*   cl (1,1,2): 0 0 1 0 0 1   representative
*   cl (2,1,1): 0 0 0 1 0 1   gatekeeper
*   cl (1,2,1): 0 1 0 0 0 1   consultant (itinerant)
*   cl (1,2,3): 0 0 0 0 1 1   liaison
*   with the tie 1 -> 3 added, cl (1,1,1): 0 0 0 0 0 0
capture program drop xt_role
program xt_role
	args g1 g2 g3 role
	nwclear
	clear
	nwset, mat((0,1,0\0,0,1\0,0,0)) name(dp3) directed
	set obs 3
	gen grp = cond(_n == 1, `g1', cond(_n == 2, `g2', `g3'))
	nwbrokerage dp3, group(grp) generate(b)
	xa r(pairs) == 1
	foreach r in coordinator gatekeeper representative consultant liaison {
		local e = cond("`r'" == "`role'", 1, 0)
		xa b_`r'[2] == `e'
		xa b_`r'[1] == 0 & b_`r'[3] == 0
	}
end
xt_role 1 1 1 coordinator
xt_role 1 1 2 representative
xt_role 2 1 1 gatekeeper
xt_role 1 2 1 consultant
xt_role 1 2 3 liaison
* a closed two-path is no brokerage (sna excludes i -> j -> k when i -> k exists)
nwclear
clear
nwset, mat((0,1,1\0,0,1\0,0,0)) name(tr) directed
set obs 3
gen grp = 1
nwbrokerage tr, group(grp) generate(bt)
xa r(pairs) == 0
xa bt_coordinator[2] == 0
* errors
gen str1 sg = "a"
capture nwbrokerage tr, group(sg) generate(bs)
xa _rc == 109
capture nwbrokerage tr, group(grp)
xa _rc == 198
capture nwbrokerage tr, generate(bx)
xa _rc == 198
capture nwbrokerage tr, group(grp) generate(bt)
xa _rc == 110
* SUSPECTED BUG: nwbrokerage.ado stores the count in a Stata scalar called brk_pairs and leaves it behind
scalar brk_pairs = -1
nwbrokerage tr, group(grp) generate(bt) replace
xa scalar(brk_pairs) == -1    // fixed: CONFIRMED BUG M9
di "(1) nwbrokerage: ok"

* ---------------------------------------------------------------- (2) nwsimmelian
nwclear
clear
* undirected triangle 1-2-3 with a tail 3-4: the three triangle ties are Simmelian, 3-4 is not
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(tt) undirected
nwsimmelian tt
nwsummarize _simmelian
xa r(edges) == 3
nwtomata _simmelian, mat(S)
xm assert(S[1,2] == 1 & S[2,3] == 1 & S[3,4] == 0)
* name exists: r(483); nwreplace replaces
capture nwsimmelian tt
xa _rc == 483
nwsimmelian tt, nwreplace
nwsimmelian tt, name(sim2)
nwsummarize sim2
xa r(edges) == 3
* directed: a triangle of mutual ties is Simmelian; a cycle 1 -> 2 -> 3 -> 1 is not
nwset, mat((0,1,1\1,0,1\1,1,0)) name(dm) directed
nwsimmelian dm, name(sdm)
nwsummarize sdm
xa r(arcs) == 6
nwset, mat((0,1,0\0,0,1\1,0,0)) name(dc) directed
nwsimmelian dc, name(sdc)
nwsummarize sdc
xa r(arcs) == 0
* the source network is unchanged
nwsummarize tt
xa r(edges) == 4
mata: mata drop S
di "(2) nwsimmelian: ok"

* ---------------------------------------------------------------- (3) nwshared
nwclear
clear
* triangle with a tail: each triangle tie has 1 shared partner, the tail tie 0
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(tt) undirected
nwshared tt
nwtomata _shared, mat(S)
xm assert(S[1,2] == 1 & S[1,3] == 1 & S[2,3] == 1)
xm assert(S[3,4] == 0 & S[1,4] == 0)
* K4: 2 shared partners on every tie
nwset, mat(J(4,4,1) - I(4)) name(k4) undirected
nwshared k4, name(sk4)
nwtomata sk4, mat(S)
xm assert(S[1,2] == 2 & S[3,4] == 2)
* valued: the values are ignored
nwset, mat(2.5 * (J(4,4,1) - I(4))) name(k4v) undirected
nwshared k4v, name(sk4v)
nwtomata sk4v, mat(S)
xm assert(S[1,2] == 2)
* directed needs undirected
nwset, mat((0,1,1\0,0,1\0,0,0)) name(d3) directed
capture nwshared d3, name(sd3)
xa _rc == 198
capture nwname sd3
xa _rc != 0
nwshared d3, name(sd3) undirected
nwtomata sd3, mat(S)
xm assert(S[1,2] == 1)
* name exists, replace/nwreplace, both together
capture nwshared tt
xa _rc == 483
nwshared tt, replace
capture nwshared tt, replace nwreplace
xa _rc == 198
mata: mata drop S
di "(3) nwshared: ok"

* ---------------------------------------------------------------- (4) nwsimindex
nwclear
clear
* path 1-2-3: N(1) = {2}, N(2) = {1,3}, N(3) = {2}
nwset, mat((0,1,0\1,0,1\0,1,0)) name(p3) undirected
foreach m in common jaccard dice cosine {
	nwsimindex p3, measure(`m') name(s_`m')
	xa "`r(measure)'" == "`m'" & r(nodes) == 3 & "`r(netname)'" == "s_`m'"
	nwtomata s_`m', mat(S)
	* (1,3) share their only neighbour: 1 for every measure; (1,2) share none: 0
	xm assert(abs(S[1,3] - 1) < 1e-12 & S[1,2] == 0)
}
* adamicadar: the shared neighbour 2 has degree 2 -> 1 / ln(2)
nwsimindex p3, measure(adamicadar) name(s_aa)
nwtomata s_aa, mat(S)
xm assert(abs(S[1,3] - 1/ln(2)) < 1e-12)
* measure() is not case sensitive; jaccard is the default
nwsimindex p3, measure(JACCARD) name(s_up)
xa "`r(measure)'" == "jaccard"
nwsimindex p3, name(s_def)
xa "`r(measure)'" == "jaccard"
* the result network is valued and undirected
nwsummarize s_def
xa "`r(valued)'" == "true" & "`r(directed)'" == "false"
* errors and name collisions
capture nwsimindex p3, measure(pearson) name(s_x)
xa _rc == 6556
capture nwname s_x
xa _rc != 0
* an existing name without replace: a new name is chosen (warning), r(netname) says which
nwsimindex p3, name(s_def)
xa "`r(netname)'" != "s_def"
nwsimindex p3, name(s_def) replace
xa "`r(netname)'" == "s_def"
mata: mata drop S
di "(4) nwsimindex: ok"

nwclear
xt_mend
di "ALL PASS"
