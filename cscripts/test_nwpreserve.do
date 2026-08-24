cscript

do unw_core.do

nwclear
nwrandom 7, density(1) name(mynet) 
nwset
assert `r(networks)' == 1
gen x = "test"
nwpreserve

nwclear
nwset
assert `r(networks)' == 0
assert `=_N' == 0

nwrestore
assert `=_N' == 7
assert x[1] == "test"


* --- alpha-audit regression: nwrestore used to fail (r999, "data in
* memory would be lost") in the CANONICAL preserve/modify/restore
* workflow whenever any network was still registered at restore time
* (i.e. whenever nwclear wasn't manually called first, defeating the
* whole point of a preserve/restore pair) - nwrestore.ado's own
* internal nwuse call passed plain `clear' where only nwuse's own
* `nwclear' option token actually suppresses that guard.
nwclear
nwrandom 5, prob(1) name(mynet)
gen tag = "orig"
nwpreserve
replace tag = "modified"
capture noisily nwrestore
assert _rc == 0
assert tag[1] == "orig"
di "=== canonical preserve/modify/restore REGRESSION VERIFIED ==="

* moderate-severity pass, manipulation_subset group: a second nwpreserve
* before an intervening nwrestore used to silently overwrite the first
* snapshot with no warning, unlike Stata's own preserve ("already
* preserved").
nwclear
nwrandom 3, prob(1) name(pnetA)
nwpreserve
assert _rc == 0
nwclear
nwrandom 5, prob(1) name(pnetB)
capture noisily nwpreserve
assert _rc == 621
nwclear
nwrestore
nwsummarize
assert r(nodes) == 3
di "=== double-preserve guard REGRESSION VERIFIED ==="
