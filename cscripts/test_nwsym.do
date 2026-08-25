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

* moderate-severity pass, manipulation_transform group: noreplace was a
* dead option - a network was always symmetrized/replaced in place when
* generate() was not given, regardless of noreplace. Implemented:
* noreplace without generate() now errors clearly.
nwclear
nwset, mat((1,2,0\4,0,0\1,0,0)) name(noreplacetest)
capture noisily nwsym noreplacetest, noreplace mode(max)
assert _rc == 198
mata: assert((*nw.nws.pdefs[nw.nws.get_index_of("noreplacetest")]->get_matrix())[1,2] == 2)
nwsym noreplacetest, noreplace generate(noreplacetest_g) mode(max)
assert _rc == 0
mata: assert((*nw.nws.pdefs[nw.nws.get_index_of("noreplacetest")]->get_matrix())[1,2] == 2)
mata: assert((*nw.nws.pdefs[nw.nws.get_index_of("noreplacetest_g")]->get_matrix())[1,2] == 4)
di "=== noreplace REGRESSION VERIFIED ==="

