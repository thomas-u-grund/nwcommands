cscript

do unw_core.do

nwclear
nwrandom 5, prob(1) name(mynet)
nwrename mynet newname
nwname
assert "`r(netname)'" == "newname"


nwname newname, newdirected(false) newselfloop(true) newvalued(true) newtitle("Test")
nwname
assert "`r(netname)'" == "newname"
assert "`r(title)'" == "Test"
assert "`r(valued)'" == "true"
assert "`r(selfloop)'" == "true"
assert "`r(directed)'" == "false"



