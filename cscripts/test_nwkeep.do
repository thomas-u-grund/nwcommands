cscript

do unw_core.do

nwclear
nwset, mat((1,1,0\0,0,0\1,0,0)) name("first")
nwset, mat((1,1,0\0,0,0\1,0,0)) name("second")
nwkeep first

nwset
assert `"`r(nets)'"' == `" first"'
assert         r(networks) == 1

nwclear
nwset, mat((1,1,0\0,0,0\1,0,0)) name("first")
nwset, mat((1,1,0\0,0,0\1,0,0)) name("second")
nwset, mat((1,1,0\0,0,0\1,0,0)) name("first2")
nwkeep f*
nwset
assert `"`r(nets)'"' == `" first first2"'
assert         r(networks) == 2

nwclear
nwset, mat((1,1,0\0,0,0\1,0,0)) name("first")
nwkeep if _n < 3
nwsummarize
assert reldif( r(density)        , .5                ) <  1E-8
assert         r(arcs_value)    == 1
assert         r(arcs)          == 1
assert         r(maxval)        == 1
assert         r(minval)        == 0
assert         r(missing_edges) == 2
assert         r(selfloops)     == 0
assert         r(nodes)         == 2
assert         r(id)            == 1

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482), both for the
* whole-network-keep path and the if/in row-keep path.
nwclear
nwset, mat((1,1,0\0,0,0\1,0,0)) name("first")
capture noisily nwkeep nonexistent
assert _rc == 482
capture noisily nwkeep nonexistent if _n < 2
assert _rc == 482



