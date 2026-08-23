cscript

do unw_core.do

nwclear
set obs 10
gen x = 1
nwexpand x

nwsummarize
assert         r(density)       == 1
assert         r(edges_sum)     == 45
assert         r(edges)         == 45
assert         r(maxval)        == 1
assert         r(minval)        == 1
assert         r(missing_edges) == 10
assert         r(selfloops)     == 0
assert         r(nodes)         == 10

nwclear
set obs 10
gen x = _n
nwexpand x, mode(dist) 

nwsummarize
assert         r(density)       == 1
assert         r(arcs_value)    == 0
assert         r(arcs)          == 90
assert         r(maxval)        == 9
assert         r(minval)        == -9
assert         r(missing_edges) == 10
assert         r(selfloops)     == 0
assert         r(nodes)         == 10

nwexpand x, mode(absdist) nodes(3)
nwsummarize
assert         r(density)       == 1
assert         r(edges_sum)     == 4
assert         r(edges)         == 3
assert         r(maxval)        == 2
assert         r(minval)        == 1
assert         r(missing_edges) == 3
assert         r(selfloops)     == 0
assert         r(nodes)         == 3






