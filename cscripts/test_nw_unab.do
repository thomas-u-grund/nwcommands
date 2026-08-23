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



