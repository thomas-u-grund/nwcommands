cscript

do unw_core.do

* nwsymmetrize is a pure alias for nwsym (harmonisation phase, naming
* convention: spelled-out verb, discoverable name). Confirms it forwards
* arguments/options and stored results identically to nwsym itself -
* not a re-implementation, so this mirrors (a subset of) test_nwsym.do.

nwclear
nwset, mat((1,1,0\0,0,0\1,0,0))
mata: sym = (*nw.nws.pdefs[1]->get_matrix()) == (*nw.nws.pdefs[1]->get_matrix())'
mata: st_numscalar("s", sym)
assert s == 0

nwsymmetrize
mata: sym = (*nw.nws.pdefs[1]->get_matrix()) == (*nw.nws.pdefs[1]->get_matrix())'
mata: st_numscalar("s", sym)
assert s == 1

nwclear
nwset, mat((1,2,0\4,0,0\1,0,0))
nwsymmetrize, mode(min)
mata: sym = (*nw.nws.pdefs[1]->get_matrix())[1,2]
mata: st_numscalar("s", sym)
assert s == 2

* check
nwclear
nwset, mat((0,1\1,0))
nwsymmetrize, check
assert `"`r(is_symmetric)'"' == `"true"'

* generate() forwarding, leaves original untouched
nwclear
nwset, mat((1,2,0\4,0,0\1,0,0)) name(mynet)
nwsymmetrize mynet, mode(mean) generate(symcopy)
mata: assert((*nw.nws.pdefs[nw.nws.get_index_of("mynet")]->get_matrix())[1,2] == 2)
mata: assert((*nw.nws.pdefs[nw.nws.get_index_of("symcopy")]->get_matrix())[1,2] == 3)

* replace/generate() mutual exclusion forwards through unchanged
nwclear
nwset, mat((1,2,0\4,0,0\1,0,0)) name(mynet)
capture noisily nwsymmetrize mynet, replace generate(x)
assert _rc == 198

di "=== nwsymmetrize alias VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* nwsym's own nw_syntax passthrough (error 482).
capture noisily nwsymmetrize nonexistent
assert _rc == 482
