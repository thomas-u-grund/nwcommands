cscript

do unw_core.do
nwrandom 5, prob(.1) name(mynet1)
nwrandom 5, prob(.1) name(mynet2)
nwrandom 5, prob(.1) name(other)
nw_unab nets : my*
di "`nets'"
mata: st_global("r(unab)", "`nets'")

assert `"`r(unab)'"'     == `"mynet1 mynet2"'
assert `"`r(netlist)'"'  == `"mynet1 mynet2"'
assert `"`r(networks)'"' == `"2"'

* --- failure path: min() is passed straight through to Stata's own
* `unab', which enforces it - a pattern matching zero networks with
* min(1) required is rejected, not silently returned as an empty list.
capture noisily nw_unab nets2 : bogus_pattern_xyz*, min(1)
assert _rc != 0



