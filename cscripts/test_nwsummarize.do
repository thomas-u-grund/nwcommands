cscript

do unw_core.do

set obs 4
gen x = 1
gen y = 0
gen z = 0
nwset x y z

nwsummarize
assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"network"'
assert `"`r(name)'"'     == `"network"'
assert `"`r(labs)'"'     == `"x,y,z"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"x y z"'

assert         r(nodes)         == 3
assert reldif( r(density)        , .3333333333333333 ) <  1E-8
assert         r(arcs_value)    == 2
assert         r(arcs)          == 2
assert         r(maxval)        == 1
assert         r(minval)        == 0
assert         r(missing_edges) == 3
assert         r(selfloops)     == 0
assert         r(id)            == 1

nwsym
nwsummarize, detail

assert `"`r(valued)'"'   == `"false"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"network"'
assert `"`r(name)'"'     == `"network"'
assert `"`r(labs)'"'     == `"x,y,z"'
assert `"`r(directed)'"' == `"false"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"x y z"'

assert         r(nodes)         == 3
assert         r(reciprocity)   == 1
assert         r(transitivity)  == 0
assert reldif( r(density)        , .6666666666666666 ) <  1E-8
assert         r(dg_central)    == 1
assert         r(edges_sum)     == 2
assert         r(edges)         == 2
assert         r(maxval)        == 1
assert         r(minval)        == 0
assert         r(missing_edges) == 3
assert         r(selfloops)     == 0
assert         r(id)            == 1

tempfile f
nwsummarize, save(`f')
use `f', clear
assert edges[1] == 2

nwsummarize, mat

* --- alpha-audit regression: nwsummarize's own detail block referenced
* an undefined local (`thisname') instead of the real target `netname',
* so reciprocity/transitivity/centralization silently came from
* whichever network happened to be CURRENT, not the requested target.
* Separately, save() crashed on a quoted filename (the normal/defensive
* idiom for a tempfile or a path containing spaces) - only bare
* unquoted paths worked.
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(netFirst) directed labs(A,B,C)
nwset, mat((1,1,1\1,1,1\1,1,1)) name(netSecond) directed selfloop labs(A,B,C)
nwsummarize netFirst, detail
assert r(reciprocity) == 0
di "=== detail-block target-network REGRESSION VERIFIED ==="

nwclear
nwrandom 5, prob(.3) name(sA)
tempfile out1
capture noisily nwsummarize sA, save("`out1'")
assert _rc == 0
di "=== save() quoted-filename REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwsummarize nonexistent
assert _rc == 482
