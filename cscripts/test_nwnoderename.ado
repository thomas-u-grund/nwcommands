cscript

do unw_core.do

nwclear
nwrandom 5, prob(1) name(mynet) labs(x1, x2, x3, x4, x5)
nwnoderename mynet, old(x1) new(mr smith)
assert `r(success)' == 1
assert _nwnode[1] == "mr smith"

capture nwnoderename mynet, old(x1) new(test)
assert `r(success)' == 0





