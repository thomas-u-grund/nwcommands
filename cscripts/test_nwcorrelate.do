cscript

do unw_core.do

nwclear
set obs 4
gen v1 = 0
gen v2 = (_n == 3)
gen v3 = (_n < 3)
gen v4 = 0
gen v5 = (_n < 3)
nwset v*, name(netfromvar1)

nwcorrelate
assert `"`r(context)'"'  == `"outgoing"'
assert `"`r(corrname)'"' == `"_corr"'
assert `"`r(name)'"'     == `"netfromvar1"'
assert reldif( r(avg_corr)  , -.3333333333333333) <  1E-8

nwsummarize _corr

assert `"`r(valued)'"'   == `"true"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"_corr"'
assert `"`r(name)'"'     == `"_corr"'
assert `"`r(labs)'"'     == `"n1,n2,n3,n4"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n1 n2 n3 n4"'

assert         r(nodes)         == 4
assert         r(density)       == 1
assert         r(arcs_value)    == -4
assert         r(arcs)          == 12
assert         r(maxval)        == 1
assert         r(minval)        == -1
assert         r(missing_edges) == 4
assert         r(selfloops)     == 0
assert         r(id)            == 2

nwdrop _corr

drop _all
set obs 4
gen v1 = 1
gen v2 = (_n == 3)
gen v3 = (_n < 2)
gen v4 = 0
gen v5 = (_n < 2)
nwset v*, name(netfromvar2)

nwcorrelate netfromvar1 netfromvar1
assert `"`r(name_1)'"' == `"netfromvar1"'
assert `"`r(name_2)'"' == `"netfromvar1"'
assert         r(corr) == 1

nwset
assert `"`r(nets)'"' == `" netfromvar1 netfromvar2"'
assert         r(networks) == 2

nwcorrelate netfromvar1 netfromvar2
assert `"`r(name_1)'"' == `"netfromvar1"'
assert `"`r(name_2)'"' == `"netfromvar2"'
assert reldif( r(corr)  , .2927700218845599 ) <  1E-8

gen x = _n

nwcorrelate netfromvar1, attribute(x) mode(absdistinv)


assert `"`r(name_1)'"' == `"netfromvar1"'
assert `"`r(name_2)'"' == `"absdistinv_x"'
assert reldif( r(corr)  , .2581988897471612 ) <  1E-8







