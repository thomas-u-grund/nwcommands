cscript

do unw_core.do

* Creating a network must not cost time proportional to the number of networks already stored.
* Every Mata statement that names a class member or a library function costs time proportional to the number of stored
* networks (the Mata compiler resolves identifiers against all live class instances), and nwunab built a dataset with one
* variable per stored network on every call; creating k networks was O(k^2): 1000 random networks of 50 nodes took 80 s.
* The registry readers now run as compiled functions (nwf_*() in unw_core.do) and nwunab/_nwsyntax skip the dataset
* for an exact network name.  What is left is the per-call overhead of the remaining statements: creating the 600th
* network costs about 4 times the first (it was about 8 times); a create takes about 13 statements instead of 130.

* 1. correctness of names, ids, order, and the properties read through the batched readers
nwclear
forvalues k = 1/60 {
	quietly nwrandom 6, prob(.3) name(g`k') undirected
}
nwset
assert r(networks) == 60
local nets "`r(nets)'"
local expect ""
forvalues k = 1/60 {
	local expect "`expect' g`k'"
}
assert `"`=strtrim("`nets'")'"' == `"`=strtrim("`expect'")'"'
foreach k in 1 17 60 {
	nwname g`k'
	assert r(id) == `k'
	assert "`r(name)'" == "g`k'"
	assert "`r(netname)'" == "g`k'"
	assert r(nodes) == 6
	assert "`r(directed)'" == "false"
	assert "`r(valued)'" == "false"
	assert "`r(mode2)'" == "false"
	assert "`r(selfloop)'" == "false"
	assert "`r(temporal)'" == "false"
}
* ids by name and by position agree; an abbreviation still resolves (wildcards and ranges through unab)
nwname, id(33)
assert "`r(name)'" == "g33"
nwunab got : g4*, max(20)
assert `r(networks)' == 11
nwunab got : g5 g6, max(2)
assert "`r(netlist)'" == "g5 g6"
capture nwname nosuchnet
assert _rc == 482
capture nwunab got : g5 g6, max(1)
assert _rc != 0
* the current network is the last one created; a dropped network leaves the others in order
nwcurrent
assert "`r(current)'" == "g60"
nwdrop g10
nwset
assert r(networks) == 59
nwname g11
assert r(id) == 10
nwrename g11 h11
nwname h11
assert r(id) == 10
capture nwname g11
assert _rc == 482
* a duplicate name is refused, replace works
capture nwrandom 6, prob(.3) name(g12)
assert _rc != 0
nwset, mat(J(6,6,0)) name(g12) replace
* replace drops the network and registers the new one last
nwname g12
assert r(id) == 59
nwset
assert r(networks) == 59

* 2. speed: the time per network must not grow in proportion to the number of stored networks
nwclear
timer clear
forvalues b = 1/6 {
	timer on `b'
	forvalues j = 1/100 {
		local k = (`b' - 1) * 100 + `j'
		quietly nwrandom 50, prob(.1) name(r`k')
	}
	timer off `b'
}
quietly timer list
local first = r(t1)
local last = r(t6)
di "first block (networks 1-100): " %6.2f `first' " s; last block (501-600): " %6.2f `last' " s; ratio " %5.2f `last'/`first'
* before the fixes the ratio was 7 to 9 and the 600 networks took 20 s; now the ratio is about 4 and 600 networks take 2 s
* (the per-call cost of the Mata statements that remain still grows with the registry); the bounds leave room for a loaded machine
assert `last' < 5.5 * `first'
quietly timer list
local total = r(t1) + r(t2) + r(t3) + r(t4) + r(t5) + r(t6)
assert `total' < 10
nwset
assert r(networks) == 600
nwclear

di "PASS test_registry_speed"
