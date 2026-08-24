cscript

clear mata
do unw_core.do
set more off

nwclear
nwrandom 20, prob(1)
mata: z = (*nw.nws.pdefs[1]->get_matrix())[1,1]
mata: st_numscalar("z", z)
assert z == .
nwsummarize
assert r(arcs) == 380

nwclear
nwrandom 20, prob(1) selfloop
mata: z = (*nw.nws.pdefs[1]->get_matrix())[1,1]
mata: st_numscalar("z", z)
assert z == 1
nwsummarize
assert r(arcs) == 400

nwclear
nwrandom 5, prob(.1) ntimes(5)
nwset
assert `r(networks)' == 5

nwclear
nwrandom 10, density(.1)
nwsummarize
assert `r(density)' == 0.1

nwclear
nwrandom 10, census(10 10)
nwdyads
assert `r(_100)' == 10
assert `r(_010)' == 10

nwclear
nwrandom 10, census(10 10) name(mynet)
assert `"`r(netlist)'"'  == `"mynet"'


nwclear
nwrandom 10, census(10 10) name(mynet) ntimes(3)
assert `"`r(netlist)'"' == `"mynet_1 mynet_2 mynet_3"'


nwclear
nwrandom 5, prob(1) weights(0.0, 0., 1)
nwsummarize

assert         r(nodes)         == 5
assert         r(density)       == 1
assert         r(arcs_value)    == 60
assert         r(arcs)          == 20
assert         r(maxval)        == 3
assert         r(minval)        == 3
assert         r(missing_edges) == 5
assert         r(selfloops)     == 0
assert         r(id)            == 1











* --- alpha-audit regression: ntimes()>1's recursive self-call never
* forwarded weights() - every generated network silently came back
* unweighted (plain 0/1) regardless of the requested weights().
nwclear
set seed 42
nwrandom 10, prob(1) ntimes(2) weights(0,0,1)
nwvalue random_1[1,3]
assert r(value) == 3
nwvalue random_2[1,3]
assert r(value) == 3
di "=== ntimes()>1 + weights() REGRESSION VERIFIED ==="

* moderate-severity pass, generators_structural group: a trailing `*'
* wildcard used to silently accept and discard any misspelled option
* instead of erroring, unlike every sibling generator in this group.
nwclear
capture noisily nwrandom 5, prob(.5) thisoptiondoesnotexist(123)
assert _rc == 198
di "=== unknown-option rejection REGRESSION VERIFIED ==="
