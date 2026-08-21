cscript

do unw_core.do



nwclear
set obs 4
gen ego = "Peter"
gen alter = "LiU"
gen value = 1
replace ego = "Thomas" in 2
replace alter = "LiU" in 2
replace value = 1 in 2
replace ego = "Peter" in 3
replace alter = "Oxford" in 3
replace value = 7 in 3
replace ego = "Thomas" in 4
replace alter = "Oxford" in 4
replace value = 5 in 4
nw2fromedge ego alter value, name(mynet)

// project(1) is persons (ego = ego/alter's first edgelist variable,
// "ego" = Peter/Thomas) - matching nw2fromedge.ado's own documented
// worked example exactly (Peter/Thomas sharing institutions LiU/
// Oxford). Was "project(2)" here, silently passing only because of a
// since-fixed nw2fromedge bug that assigned node modes by *position*
// (nodes numbered by sorting persons' and institutions' labels
// *together*) rather than by which edgelist variable a label actually
// came from - "LiU"/"Oxford" happen to sort alphabetically before
// "Peter"/"Thomas", so the old bug swapped mode1/mode2 for this exact
// dataset and made project(2) silently mean "persons" instead of
// "institutions". Now that nw2fromedge assigns modes by actual label
// origin, project(1) is the one that means persons - reconfirmed
// directly against the doc's own hand-worked values (unchanged).
nw2project mynet, project(1) name(minmax_test)
mata: p = nw.nws.pdefs[nw.nws.get_index_of("minmax_test")]
mata: st_numscalar("r(minmax)", p->edge_weight(1,2))
assert reldif(r(minmax), 5) < 1e-8

nw2project mynet, project(1) name(min_test) stat(min)
mata: p = nw.nws.pdefs[nw.nws.get_index_of("min_test")]
mata: st_numscalar("r(min)", p->edge_weight(1,2))
assert reldif(r(min), 1) < 1e-8

nw2project mynet, project(1) name(max_test) stat(max)
mata: p = nw.nws.pdefs[nw.nws.get_index_of("max_test")]
mata: st_numscalar("r(max)", p->edge_weight(1,2))
assert reldif(r(max), 7) < 1e-8

nw2project mynet, project(1) name(sum_test) stat(sum)
mata: p = nw.nws.pdefs[nw.nws.get_index_of("sum_test")]
mata: st_numscalar("r(sum)", p->edge_weight(1,2))
assert reldif(r(sum), 14) < 1e-8

nw2project mynet, project(1) name(mean_test) stat(mean)
mata: p = nw.nws.pdefs[nw.nws.get_index_of("mean_test")]
mata: st_numscalar("r(mean)", p->edge_weight(1,2))
assert reldif(r(mean), 3.5) < 1e-8

di "=== ALL 5 STAT FORMULAS MATCH THE DOCUMENTED WORKED EXAMPLE EXACTLY ==="

// project(2) is now correctly institutions (LiU/Oxford, 2 of them) -
// swapped from the pre-fix "project(1)" for the same reason as above.
nw2project mynet, project(2) name(inst_test)
mata: p = nw.nws.pdefs[nw.nws.get_index_of("inst_test")]
mata: st_numscalar("r(nodes)", p->get_nodes())
assert r(nodes) == 2

nwclear
set obs 6
gen ego = "A"
gen alter = "X"
replace ego = "B" in 2
replace alter = "X" in 2
replace ego = "A" in 3
replace alter = "Y" in 3
replace ego = "B" in 4
replace alter = "Y" in 4
replace ego = "A" in 5
replace alter = "Z" in 5
replace ego = "C" in 6
replace alter = "Z" in 6
nw2fromedge ego alter, name(unvnet)
nw2project unvnet, project(1) name(unv_test)
mata: p = nw.nws.pdefs[nw.nws.get_index_of("unv_test")]
mata: p->get_nodenames()
mata: st_numscalar("r(AB)", p->has_edge(1,2))
mata: st_numscalar("r(AC)", p->has_edge(1,3))
mata: st_numscalar("r(BC)", p->has_edge(2,3))
mata: st_numscalar("r(AB_val)", p->edge_weight(1,2))
mata: st_numscalar("r(AC_val)", p->edge_weight(1,3))
assert r(AB) == 1
assert r(AC) == 1
assert r(BC) == 0
assert r(AB_val) == 2
assert r(AC_val) == 1
di "=== UNVALUED SHARED-COUNT DEFAULT VERIFIED ==="

nwclear
nwset, mat((0,0,0\0,0,0\0,0,0)) name(disconnected_bip) labs(P1,P2,P3)
mata: p3 = nw.nws.pdefs[nw.nws.get_index_of("disconnected_bip")]
mata: p3->set_2mode(1)
mata: p3->set_modes(("1","1","2"))
nw2project disconnected_bip, project(1) name(isolate_test)
mata: p4 = nw.nws.pdefs[nw.nws.get_index_of("isolate_test")]
mata: st_numscalar("r(nodes)", p4->get_nodes())
mata: st_numscalar("r(edges)", rows(p4->edgelist()))
assert r(nodes) == 2
assert r(edges) == 0
di "=== ISOLATE/EMPTY-PROJECTION CASE VERIFIED ==="

nwclear
nwset, mat((0,1\1,0)) name(onemode)
capture nw2project onemode, project(1)
assert _rc == 198
di "=== NON-TWO-MODE ERROR HANDLING VERIFIED ==="

capture nw2project mynet, project(3)
assert _rc == 198
di "=== INVALID project() ERROR HANDLING VERIFIED ==="


* --- replace semantics: reuse the exact requested name, not an
* auto-incremented one (regression test for a real bug found while
* building nwsimindex - see docs/CERTIFICATION.md)
nwclear
set obs 4
gen ego2 = "Peter"
gen alter2 = "LiU"
gen value2 = 1
replace ego2 = "Thomas" in 2
replace alter2 = "LiU" in 2
replace ego2 = "Peter" in 3
replace alter2 = "Oxford" in 3
replace ego2 = "Thomas" in 4
replace alter2 = "Oxford" in 4
nw2fromedge ego2 alter2 value2, name(mynet2)

nw2project mynet2, project(2) name(collideproj)
nw2project mynet2, project(2) name(collideproj)
capture nw_syntax collideproj_1, other(_check)
assert _rc == 0
di "=== NAME COLLISION AUTO-INCREMENTS VERIFIED ==="

nw2project mynet2, project(2) name(collideproj) replace
* r(nodes)/r(ties) display line bugfix regression, checked immediately
* (nw_syntax below is itself r-class and would otherwise clobber these):
* the display line used to silently show blank via a bare `r(nodes)'
* macro-lookup (no such local exists), r(nodes)/r(ties) were correct
* all along - only the *display* line was ever affected.
assert r(nodes) == 2
assert r(ties) == 2

capture nw_syntax collideproj, other(_check)
assert _rc == 0
capture nw_syntax collideproj_2, other(_check)
assert _rc != 0
di "=== REPLACE REUSES EXACT NAME VERIFIED ==="
