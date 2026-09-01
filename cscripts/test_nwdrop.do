cscript

do unw_core.do

nwclear
nwset, mat((1,1,0\0,0,0\1,0,0)) name("first")
nwset, mat((1,1,0\0,0,0\1,0,0)) name("second")
nwdrop first
nwset
assert `"`r(nets)'"' == `" second"'
assert         r(networks) == 1

nwdrop _all
nwset
assert         r(networks) == 0

nwclear
nwset, mat((1,1,0\0,0,0\1,0,0)) name("first")
nwset, mat((1,1,0\0,0,0\1,0,0)) name("second")
nwdrop second if _n < 2
nwsummarize second
assert         r(density)       == 0
assert         r(arcs_value)    == 0
assert         r(arcs)          == 0
assert         r(maxval)        == 0
assert         r(minval)        == 0
assert         r(missing_edges) == 2
assert         r(selfloops)     == 0
assert         r(nodes)         == 2
assert         r(id)            == 2

nwclear
nwset, mat((1,1,0\0,0,0\1,0,0)) name("second")
gen test = _N - _n
nwdrop second in 1
nwsummarize
assert         r(density)       == 0
assert         r(arcs_value)    == 0
assert         r(arcs)          == 0
assert         r(maxval)        == 0
assert         r(minval)        == 0
assert         r(missing_edges) == 2
assert         r(selfloops)     == 0
assert         r(nodes)         == 2
assert         r(id)            == 1

nwclear
nwset, mat((1,1,0\0,0,0\1,0,0)) name("second")
gen test = _N - _n
nwdrop second if test == 2
nwsummarize
assert         r(density)       == 0
assert         r(arcs_value)    == 0
assert         r(arcs)          == 0
assert         r(maxval)        == 0
assert         r(minval)        == 0
assert         r(missing_edges) == 2
assert         r(selfloops)     == 0
assert         r(nodes)         == 2
assert         r(id)            == 1

nwclear
nwset, mat((1,1,0\0,0,0\1,0,0)) name("second")
gen test = _N - _n
nwdrop if round(test) == 2

* --- failure paths: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482), both for the
* whole-network-drop path and the if/in row-drop path.
nwclear
nwset, mat((1,1,0\0,0,0\1,0,0)) name("first")
capture noisily nwdrop nonexistent
assert _rc == 482
capture noisily nwdrop nonexistent if _n < 2
assert _rc == 482

nwclear
capture noisily nwdrop first
assert _rc == 482





