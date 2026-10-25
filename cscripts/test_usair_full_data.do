cscript

* Full US airport network usair_full (OpenFlights, ODbL): counts, components, attributes.
* Loaded from the local data folder with nwuse (the code path of nwwebuse).
* Run from the repository root.

do unw_core.do

nwuse data/usair_full, nwclear
nwset
assert `"`r(nets)'"' == " usair_full"
nwsummarize usair_full
assert r(nodes) == 549
assert r(arcs) == 5450
assert "`r(directed)'" == "true"
assert "`r(mode2)'" == "false"

* attributes
foreach v in iata name city lat lon {
	confirm variable `v'
}
assert iata == _nwnode
assert name != "" & city != ""
qui count if _nwnode == "ATL"
assert r(N) == 1
assert name == "Hartsfield Jackson Atlanta International Airport" if _nwnode == "ATL"
assert city == "Atlanta" if _nwnode == "ATL"

* three connected components: 541, 4 and 4 airports
nwcomponents usair_full, generate(comp)
qui tab comp
assert r(r) == 3
qui count if comp == 1
assert r(N) == 541
qui count if comp != 1
assert r(N) == 8

* degrees stored in the file agree with the network
nwdegree usair_full, generate(od id)
assert od == _outdegree & id == _indegree
assert _degree == _outdegree + _indegree
qui sum _degree
assert r(max) == 305
assert _degree == 305 if _nwnode == "ATL"

display "test_usair_full_data: PASS"
