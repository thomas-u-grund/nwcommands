cscript

do unw_core.do

nwclear
nwrandom 5, prob(1) name(mynet)
nwrename mynet newname
nwname
assert "`r(netname)'" == "newname"




