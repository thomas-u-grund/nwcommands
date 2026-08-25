cscript

do unw_core.do

* moderate-severity pass, manipulation_subset group: nwrestore had no
* dedicated test file at all - it was only exercised incidentally inside
* test_nwpreserve.do's own happy-path scenario, which always calls a
* separate nwclear before nwrestore, masking the "data in memory would
* be lost" bug that used to block the canonical preserve/modify/restore
* workflow. Covers: (1) that canonical workflow directly; (2)
* nothing-to-restore and its _rc; (3) restoring twice in a row.

* --- (1) canonical preserve -> modify (without nwclear) -> restore
nwclear
nwrandom 5, prob(1) name(mynet)
gen tag = "orig"
nwpreserve
replace tag = "modified"
capture noisily nwrestore
assert _rc == 0
assert tag[1] == "orig"
di "=== canonical preserve/modify/restore REGRESSION VERIFIED ==="

* --- (2) nothing-to-restore: reports cleanly and leaves _rc == 0
nwclear
capture erase _nw_temp.nwdta
nwrestore
assert _rc == 0
di "=== nothing-to-restore REGRESSION VERIFIED ==="

* --- (3) restoring twice in a row: the second restore is itself a
* nothing-to-restore case, since the temp file is erased once consumed.
nwclear
nwrandom 4, prob(1) name(mynet2)
nwpreserve
nwclear
nwrestore
assert _rc == 0
nwsummarize
assert r(nodes) == 4
capture noisily nwrestore
assert _rc == 0
di "=== restore-twice REGRESSION VERIFIED ==="
