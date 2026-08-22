cscript

clear mata
do unw_core.do
set more off

nwclear
nwset, mat(J(4,4,2)) name("second")
nwset, mat(J(6,6,2)) name("second")
nwset
assert `"`r(nets)'"' == `" second second_1"'
assert         r(networks) == 2

nwclear
set obs 4
gen v1 = 0
gen v2 = (_n == 3)
gen v3 = (_n < 3)
gen v4 = 0
gen v5 = (_n < 3)

nwset v*, name(netfromvar)
nwset
assert `"`r(nets)'"'  == " netfromvar"
assert `"`r(networks)'"' == `"1"'

nwclear
nwset, mat(J(4,4,1)) labs(a,b)
mata: st_local("lab1", nw.nws.pdefs[1]->nodes[1])
assert "`lab1'" == "a"

nwclear
nwset, mat(J(4,4,1)) labs(a,b,c,d,e,f,g,h)
mata: st_local("lab1", nw.nws.pdefs[1]->nodes[1])
assert "`lab1'" == "a"

nwclear
nwset, mat(J(4,4,1)) labs(a,a)
mata: st_local("lab1", nw.nws.pdefs[1]->nodes[1])
rcof `"assert "`lab1'" == "a""' != 0

nwclear
set obs 4
gen v1 = 0
gen v2 = (_n == 3)
gen v3 = (_n < 3)
gen v4 = 0
gen v5 = (_n < 3)
gen nodelab = "mynode" + string(_n)

nwset v*, labsfromvar(nodelab)
mata: st_local("lab1", nw.nws.pdefs[1]->nodes[1])
assert "`lab1'" == "mynode1"

nwclear
set obs 4
gen v1 = 0
gen v2 = (_n == 3)
gen v3 = (_n < 3)
gen v4 = 0
gen v5 = (_n < 3)
gen nodelab = "mynode" + string(_n)

nwset v*, labsfromvar(nodelab) bipartite
mata: st_local("lab1", nw.nws.pdefs[1]->nodes[6])
assert "`lab1'" == "mynode1"

nwclear
nwset, mat(J(4,4,2)) name("second")
mata: st_numscalar("val", strtoreal(nw.nws.pdefs[1]->get_edgelist(0)[1,3]))
assert val == .

nwclear
nwset, mat(J(4,4,2)) name("second") selfloop
mata: st_numscalar("val", strtoreal(nw.nws.pdefs[1]->get_edgelist(0)[1,3]))
assert val == 2

nwclear
nwset, mat(J(4,4,2)) name("second") bipartite
mata: st_numscalar("val1", strtoreal(nw.nws.pdefs[1]->get_edgelist(0)[2,3]))
assert val1 == .
mata: st_numscalar("val2", strtoreal(nw.nws.pdefs[1]->get_edgelist(0)[5,3]))
assert val2 == 2

* vars() lets a caller explicitly name the Stata variables nwload will
* materialize this network into, overriding the auto-derived-from-node-
* names default - documented since at least this file's own doc header,
* but the option itself had been silently dropped from the syntax line
* at some point (found while fixing nwlattice.ado, which depends on it -
* "option vars() not allowed" on every call). Confirms both that the
* option is accepted again and that nwload actually produces variables
* under the requested names, not just that no error is thrown.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(mynet) vars(myvar1 myvar2 myvar3)
nwload
foreach v in myvar1 myvar2 myvar3 {
	capture confirm variable `v'
	assert _rc == 0
}
capture confirm variable n1
assert _rc != 0

* wrong count must error cleanly, not silently truncate/pad
nwclear
capture nwset, mat((0,1,1\1,0,1\1,1,0)) name(mynet) vars(myvar1 myvar2)
assert _rc != 0
