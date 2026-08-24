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




* --- alpha-audit regression: id() was completely non-functional -
* nw_syntax's own unprefixed c_local side effect clobbered this
* program's own `id' local before it was ever consulted, so
* `nwname, id(N)' always silently acted on the CURRENT network
* regardless of N.
nwclear
nwrandom 4, prob(.3) name(idA)
nwrandom 4, prob(.3) name(idB)
nwname, id(1)
assert r(netname) == "idA"
assert r(id) == 1
di "=== id() REGRESSION VERIFIED ==="

* moderate-severity pass, information_census group: newvars(string) was a
* fully dead option (removed); newcaption()/newprovenance() are real,
* working options that had zero documentation and zero test coverage
* before this.
nwclear
nwrandom 5, prob(.3) name(nX)
nwname nX, newcaption("cap text") newprovenance("prov text")
nwname nX
assert `"`r(caption)'"' == "cap text"
assert `"`r(provenance)'"' == "prov text"
di "=== newcaption()/newprovenance() REGRESSION VERIFIED ==="
