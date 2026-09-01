cscript

do unw_core.do

nwclear
nwset, mat((1,1,0\0,0,0\1,0,0))
mata: sym = (*nw.nws.pdefs[1]->get_matrix()) == (*nw.nws.pdefs[1]->get_matrix())'
mata: st_numscalar("s", sym)
assert s == 0

nwsym
mata: sym = (*nw.nws.pdefs[1]->get_matrix()) == (*nw.nws.pdefs[1]->get_matrix())'
mata: st_numscalar("s", sym)
assert s == 1

nwclear
nwset, mat((1,2,0\4,0,0\1,0,0))
nwsym, mode(min)
mata: sym = (*nw.nws.pdefs[1]->get_matrix())[1,2]
mata: st_numscalar("s", sym)
assert s == 2

nwclear
nwset, mat((1,2,0\4,0,0\1,0,0))
nwsym, mode(max)
mata: sym = (*nw.nws.pdefs[1]->get_matrix())[1,2]
mata: st_numscalar("s", sym)
assert s == 4

nwclear
nwset, mat((1,2,0\4,0,0\1,0,0))
nwsym, mode(sum)
mata: sym = (*nw.nws.pdefs[1]->get_matrix())[1,2]
mata: st_numscalar("s", sym)
assert s == 6

nwclear
nwset, mat((1,2,0\4,0,0\1,0,0))
nwsym, mode(mean)
mata: sym = (*nw.nws.pdefs[1]->get_matrix())[1,2]
mata: st_numscalar("s", sym)
assert s == 3

// r(is_symmetric) is documented above ("true" or "false") - a
// numeric-scalar bug meant it was actually stored as 0/1 until fixed
// during the sparse-backend migration (nwfromedge.ado's own auto-
// symmetrize-detection call was silently comparing against the
// documented string form the whole time, so it never actually fired).
// Guard both the string type and both outcomes directly here.
nwclear
nwset, mat((0,1\1,0))
nwsym, check
assert `"`r(is_symmetric)'"' == `"true"'

nwclear
nwset, mat((0,1\0,0)) directed
nwsym, check
assert `"`r(is_symmetric)'"' == `"false"'

nwclear
nwset, mat((1,2,0\4,0,0\1,0,0))  name(mynet)
nwsym, mode(mean) generate(test)
nwsummarize test

assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"test"'
assert `"`r(name)'"'     == `"test"'
assert `"`r(labs)'"'     == `"n1,n2,n3"'
assert `"`r(valued)'"'   == `"true"'
assert `"`r(directed)'"' == `"false"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n1 n2 n3"'

assert reldif( r(density)        , .6666666666666666 ) <  1E-8
assert reldif( r(edges_sum)      , 3.5               ) <  1E-8
assert         r(edges)         == 2
assert         r(maxval)        == 3
assert         r(minval)        == 0
assert         r(missing_edges) == 3
assert         r(selfloops)     == 0
assert         r(nodes)         == 3
assert         r(id)            == 2


nwsummarize mynet
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"mynet"'
assert `"`r(name)'"'     == `"mynet"'
assert `"`r(labs)'"'     == `"n1,n2,n3"'
assert `"`r(valued)'"'   == `"true"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n1 n2 n3"'

assert reldif( r(density)        , .5                ) <  1E-8
assert         r(arcs_value)    == 7
assert         r(arcs)          == 3
assert         r(maxval)        == 4
assert         r(minval)        == 0
assert         r(missing_edges) == 3
assert         r(selfloops)     == 0
assert         r(nodes)         == 3
assert         r(id)            == 1

* harmonisation pass: `noreplace' replaced by a plain `replace' (cannot be
* declared alongside `noreplace' in the same syntax line - Stata's parser
* silently fails to populate `replace' when both are present, see
* nwsym.ado's own header comment and docs/CERTIFICATION.md). `replace' is
* an explicit, no-behavior-change synonym for the existing default
* (in-place symmetrization); it errors when combined with generate(),
* since the two request opposite outcomes.
nwclear
nwset, mat((1,2,0\4,0,0\1,0,0)) name(replacetest)
capture noisily nwsym replacetest, replace generate(x) mode(max)
assert _rc == 198
mata: assert((*nw.nws.pdefs[nw.nws.get_index_of("replacetest")]->get_matrix())[1,2] == 2)

* `replace' alone: in-place, identical to the bare-call default.
nwclear
nwset, mat((1,2,0\4,0,0\1,0,0)) name(replacetest)
nwsym replacetest, replace mode(max)
assert _rc == 0
mata: assert((*nw.nws.pdefs[nw.nws.get_index_of("replacetest")]->get_matrix())[1,2] == 4)

* bare call (no replace, no generate()) still symmetrizes in place -
* unchanged default, since ~8 other commands call nwsym bare internally.
nwclear
nwset, mat((1,2,0\4,0,0\1,0,0)) name(replacetest)
nwsym replacetest, mode(max)
assert _rc == 0
mata: assert((*nw.nws.pdefs[nw.nws.get_index_of("replacetest")]->get_matrix())[1,2] == 4)

* generate() alone: unchanged, original untouched, new copy created.
nwclear
nwset, mat((1,2,0\4,0,0\1,0,0)) name(replacetest)
nwsym replacetest, generate(replacetest_g) mode(max)
assert _rc == 0
mata: assert((*nw.nws.pdefs[nw.nws.get_index_of("replacetest")]->get_matrix())[1,2] == 2)
mata: assert((*nw.nws.pdefs[nw.nws.get_index_of("replacetest_g")]->get_matrix())[1,2] == 4)
di "=== replace/generate() REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwsym nonexistent
assert _rc == 482

