* Saving and loading must not lose the user's data or networks (nwsave, nwuse,
* nwappend, nwload). Run from the repository root (see RELEASING.md C0).
clear all
set more off
set seed 1
set varabbrev off

local root "`c(pwd)'"
local work "`c(tmpdir)'/nw_edge_saveload"
capture mkdir "`work'"
cd "`work'"

mata: G = (0,1,1,0 \ 0,0,1,0 \ 0,0,0,1 \ 1,0,0,0)
mata: V = (0,5,0 \ 0,0,2 \ 7,0,0)

* the ties of network net are the Mata matrix mat (diagonal aside)
capture program drop assert_ties
program assert_ties
	args net mat
	nwtomata `net', mat(__es_X)
	mata: _diag(__es_X, 0)
	mata: __es_Y = `mat'
	mata: _diag(__es_Y, 0)
	mata: assert(editmissing(__es_X, 0) == editmissing(__es_Y, 0))
end

* the networks in memory, their ties and the current one
capture program drop netstate
program netstate, rclass
	local s ""
	qui nwset
	local nets `r(nets)'
	foreach n of local nets {
		nwtomata `n', mat(__es_X)
		mata: st_local("m", invtokens(strofreal(vec(editmissing(__es_X, -77))'), ","))
		local s "`s'|`n':`m'"
	}
	qui nwcurrent
	return local state "current=`r(current)'`s'"
end

* ---------------------------------------------------------------------------
* variables named like networks (numeric and string) and like the file's own
* columns: ties and variables both survive
nwclear
nwset, mat(G) name(trust) directed
nwset, mat(V) name(friend) directed
clear
set obs 4
gen str40 _nwnode = "n" + string(_n)
gen trust = 10 * _n
label variable trust "my trust"
label define tl 10 "ten"
label values trust tl
gen str6 friend = "f" + string(_n)
gen _nw_running = -_n
gen _nw_ego = "mine"
gen _nw_uvar1 = 3
gen _nw_format = _n^2
gen _nw_userrow = 100 + _n
nwsave names, replace
nwuse names, nwclear
assert_ties trust G
assert_ties friend V
assert _N == 4
assert trust == 10 * _n
assert friend == "f" + string(_n)
assert _nw_running == -_n
assert _nw_ego == "mine"
assert _nw_uvar1 == 3
assert _nw_format == _n^2
assert _nw_userrow == 100 + _n
local lb : variable label trust
assert "`lb'" == "my trust"
local lb : value label trust
assert "`lb'" == "tl"
confirm variable _nwnode trust friend _nw_running, exact
capture confirm variable _nw_netname
assert _rc == 111
unab all : _all
assert `: word count `all'' <= 9

* the same with a two-mode network in the file
nwclear
clear
input str2 p str2 o
a x
b x
b y
end
nwfromedge p o, name(aff) twomode
nwset, mat(G) name(g1) directed
clear
nwload aff, labelonly
nwload g1, labelonly
gen aff = _n
gen g1 = "s" + string(_n)
local N = _N
nwtomata aff, mat(AFF)
nwsave two, replace
nwuse two, nwclear
assert_ties aff AFF
assert_ties g1 G
assert _N == `N'
assert aff == _n
assert g1 == "s" + string(_n)

* ---------------------------------------------------------------------------
* nwsave leaves data, c(filename), c(changed), sort order, frames and the
* current network as they were, after success and after failure
nwclear
nwset, mat(G) name(trust) directed
nwset, mat(V) name(friend) directed
nwcurrent trust
clear
set obs 6
gen id = _n
gen trust = 10 * _n
gen _nw_running = 5
gen _nw_ego = 1
label data "my data"
notes: keep this note
save userdata, replace
replace id = 100 in 1
sort trust id
datasignature
local sig "`r(datasignature)'"
netstate
local st "`r(state)'"
unab v0 : _all
qui frame dir
local fr0 "`r(frames)'"

capture program drop assert_untouched
program assert_untouched
	args sig st v0 fr0
	datasignature
	assert "`r(datasignature)'" == "`sig'"
	unab v1 : _all
	assert "`v1'" == "`v0'"
	assert "`c(filename)'" == "userdata.dta"
	assert c(changed) == 1
	assert "`: sortedby'" == "trust id"
	assert "`c(frame)'" == "default"
	qui frame dir
	assert "`r(frames)'" == "`fr0'"
	netstate
	assert `"`r(state)'"' == `"`st'"'
end

nwsave state1, replace
assert_untouched "`sig'" `"`st'"' "`v0'" "`fr0'"
* the file exists already
capture nwsave state1
assert _rc == 602
assert_untouched "`sig'" `"`st'"' "`v0'" "`fr0'"
* a directory that does not exist, and a bad option
capture nwsave "no/such/folder/x"
assert _rc != 0
assert_untouched "`sig'" `"`st'"' "`v0'" "`fr0'"
capture nwsave state2, notanoption
assert _rc != 0
assert_untouched "`sig'" `"`st'"' "`v0'" "`fr0'"
* the data label and the extra observations are in the file
nwuse state1, nwclear
assert _N == 10
qui count if id < .
assert r(N) == 6
local dl : data label
assert "`dl'" == "my data"
* nwsave without any network
nwclear
clear
set obs 3
gen z = _n
capture nwsave nonet, replace
assert _rc == 482
assert _N == 3 & c(k) == 1
capture confirm file nonet.nwdta
assert _rc != 0

* ---------------------------------------------------------------------------
* after nwuse, -save, replace- cannot write over the network file
nwclear
nwset, mat(G) name(trust) directed
clear
nwsave keepfile, replace
checksum keepfile.nwdta
local ck = r(checksum)
local len = r(filelen)
nwclear
clear
nwuse keepfile
assert `"`c(filename)'"' == ""
assert c(changed) == 1
capture save, replace
assert _rc != 0
checksum keepfile.nwdta
assert r(checksum) == `ck' & r(filelen) == `len'
nwuse keepfile, nwclear
assert `"`c(filename)'"' == ""
capture save, replace
assert _rc != 0
nwappend using keepfile, force
assert `"`c(filename)'"' == ""
capture save, replace
assert _rc != 0
checksum keepfile.nwdta
assert r(checksum) == `ck' & r(filelen) == `len'
nwclear
nwuse keepfile
assert_ties trust G
nwuse keepfile, nwclear nwappend
assert_ties trust G
assert _N == 4

* ---------------------------------------------------------------------------
* observations that belong to no node survive nwsave and nwuse
nwclear
nwset, mat(V) name(a) directed
clear
set obs 6
gen wage = _n * 100
nwsave rows, replace
assert _N == 6 & wage == _n * 100
nwuse rows, nwclear
qui count if wage < .
assert r(N) == 6
qui summarize wage
assert r(sum) == 2100
qui count if _nwnode != ""
assert r(N) == 3
assert_ties a V
* a file written before this version (no column _nw_userrow) keeps them too
preserve
use rows.nwdta, clear
drop _nw_userrow
save oldrows.nwdta, replace
restore
nwuse oldrows, nwclear
qui count if wage < .
assert r(N) == 6
assert _N == 9
assert_ties a V

* ---------------------------------------------------------------------------
* nwappend: data without _nwnode
nwclear
nwrandom 5, prob(.5) name(zz)
nwtomata zz, mat(ZZ)
clear
nwsave app, replace
nwclear
clear
set obs 8
gen income = _n * 10
gen str5 who = "p" + string(_n)
nwuse app, nwappend
assert _N == 13
assert income == _n * 10 if _n <= 8
assert who == "p" + string(_n) if _n <= 8
qui count if _nwnode != ""
assert r(N) == 5
assert_ties zz ZZ

* further observations with a blank _nwnode, a value in both places, a
* variable that is a string here and a number in the file
nwclear
clear
set obs 3
gen str40 _nwnode = "n" + string(_n)
gen age = 20 + _n
gen code = _n
gen both = _n
nwrandom 3, prob(.5) name(filenet)
nwsave app2, replace
nwclear
clear
set obs 6
gen str40 _nwnode = "n" + string(_n) if _n <= 2
gen income = _n * 10
gen str3 code = "c" + string(_n)
gen both = cond(_n == 1, 99, .)
nwset, mat((0,1 \ 1,0)) name(memnet)
local N0 = _N
nwuse app2, nwappend
assert _N == `N0' + 1
assert income == _n * 10 if _n <= 6
assert code == "c" + string(_n) if _n <= 6
confirm numeric variable code_2
assert code_2 == 1 if _nwnode == "n1"
assert code_2 == 3 if _nwnode == "n3"
assert age == 21 if _nwnode == "n1"
assert age == 23 if _nwnode == "n3"
assert both == 99 if _nwnode == "n1"
assert both == 2 if _nwnode == "n2"
assert both == 3 if _nwnode == "n3"
qui nwset
local nets `r(nets)'
assert "`nets'" == "memnet filenet"
* a user variable in the file named like a network already in memory
nwclear
nwrandom 3, prob(.5) name(g)
clear
nwsave app3src, replace
nwclear
nwset, mat(G) name(trust) directed
clear
set obs 4
gen str40 _nwnode = "n" + string(_n)
gen g = _n * 7
nwsave app3, replace
nwuse app3src, nwclear
nwuse app3, nwappend
assert g == 7 if _nwnode == "n1"
assert g == 28 if _nwnode == "n4"
assert_ties trust G

* ---------------------------------------------------------------------------
* a failed nwuse leaves data, networks and the current network as they were
nwclear
nwset, mat(G) name(good1) directed
nwset, mat(V) name(bad2) directed
clear
nwsave good, replace
use good.nwdta, clear
drop bad2
save incomplete.nwdta, replace
use good.nwdta, clear
tostring bad2, replace
replace bad2 = "x" + bad2
* passes the checks of the file and fails when the second network is built
save halfway.nwdta, replace
use good.nwdta, clear
replace _nw_nets = . in 1
save nonets.nwdta, replace
clear
set obs 2
gen _nw_format = "x"
save broken.nwdta, replace
clear
set obs 2
gen q = 1
save plain.dta, replace
file open h using garbage.nwdta, write replace
file write h "this is not a Stata file" _n
file close h

nwclear
nwset, mat(V) name(keepme) directed
nwset, mat(G) name(other) directed
nwcurrent keepme
clear
set obs 5
gen precious = _n
save userdata, replace
replace precious = 50 in 5
datasignature
local sig "`r(datasignature)'"
netstate
local st "`r(state)'"
unab v0 : _all

capture program drop assert_kept
program assert_kept
	args sig st v0
	datasignature
	assert "`r(datasignature)'" == "`sig'"
	unab v1 : _all
	assert "`v1'" == "`v0'"
	assert "`c(filename)'" == "userdata.dta"
	assert c(changed) == 1
	assert "`c(frame)'" == "default"
	netstate
	assert `"`r(state)'"' == `"`st'"'
end

foreach f in nosuchfile broken incomplete halfway nonets garbage {
	foreach o in nwclear nwappend {
		capture nwuse `f', `o'
		assert _rc != 0
		assert_kept "`sig'" `"`st'"' "`v0'"
	}
}
capture nwuse nosuchfile, nwclear
assert _rc == 601
capture nwuse incomplete, nwclear
assert _rc == 610
capture nwuse plain, nwappend
assert _rc == 610
assert_kept "`sig'" `"`st'"' "`v0'"
capture nwuse good
assert _rc == 999
assert_kept "`sig'" `"`st'"' "`v0'"
* a name in use
nwset, mat(G) name(good1) directed
netstate
local st2 "`r(state)'"
datasignature
local sig2 "`r(datasignature)'"
unab v2 : _all
capture nwuse good, nwappend
assert _rc == 483
assert_kept "`sig2'" `"`st2'"' "`v2'"
capture nwuse halfway, nwappend force
assert _rc != 0
assert_kept "`sig2'" `"`st2'"' "`v2'"
* and a failure when no network is in memory
nwclear
clear
set obs 3
gen z = _n
capture nwuse halfway
assert _rc != 0
assert _N == 3 & c(k) == 1
qui nwset
assert r(networks) == 0
nwuse good, nwclear
assert_ties good1 G
assert_ties bad2 V

* ---------------------------------------------------------------------------
* nwload and variables of the user that have the names of nodes
nwclear
nwrandom 4, prob(.5) name(u) undirected
nwtomata u, mat(U)
clear
set obs 4
forvalues i = 1/4 {
	gen n`i' = 111 * `i' + _n / 10
}
datasignature
local sig "`r(datasignature)'"
capture nwload u
assert _rc == 110
datasignature
assert "`r(datasignature)'" == "`sig'"
assert c(k) == 4
nwload u, labelonly
forvalues i = 1/4 {
	assert n`i' == float(111 * `i' + _n / 10)
}
capture nwload u
assert _rc == 110
* nwsave keeps them, in memory and in the file
nwsave uservars, replace
forvalues i = 1/4 {
	assert n`i' == float(111 * `i' + _n / 10)
}
nwuse uservars, nwclear
forvalues i = 1/4 {
	assert n`i' == float(111 * `i' + _n / 10)
}
assert_ties u U
* a command that loads a new network with the same node names
nwrandom 4, prob(.5) name(later) xvars
nwname later
assert r(nodes) == 4
forvalues i = 1/4 {
	assert n`i' == float(111 * `i' + _n / 10)
}
forvalues i = 1/4 {
	assert n`i' == float(111 * `i' + _n / 10)
}
* with overwrite they are replaced; the copies are nwload's own afterwards
nwload u, overwrite
nwtomata u, mat(U)
assert n1[2] == 0 | n1[2] == 1
nwload u
local mark : char n1[nwload]
assert "`mark'" == "u"
* copies made by nwload are not saved, and nwsave leaves them in memory
nwsave copies, replace
confirm variable n1 n2 n3 n4, exact
preserve
use copies.nwdta, clear
capture confirm variable n1, exact
assert _rc == 111
restore
nwload u, labelonly
capture confirm variable n1, exact
assert _rc == 111

* variables a network was declared from stay the user's
nwclear
clear
set obs 4
gen v1 = 0
gen v2 = (_n == 3)
gen v3 = 0
gen v4 = 0
label variable v2 "typed by me"
nwset v1 v2 v3 v4, name(fromvars)
nwload fromvars
nwload fromvars, labelonly
assert v2 == (_n == 3)
local mark : char v2[nwload]
assert "`mark'" == ""
* a network on other nodes: its variables are added, v1-v4 stay
nwset, mat(G) name(other) labs(n1,n2,n3,n4) directed
nwload other
assert v2 == (_nwnode == "v3") if substr(_nwnode, 1, 1) == "v"
confirm variable v1 v2 v3 v4 n1 n2 n3 n4, exact
nwload fromvars
confirm variable v1 v2 v3 v4, exact
local lb : variable label v2
assert "`lb'" == "typed by me"
capture confirm variable n1, exact
assert _rc == 111
nwsave fromvars, replace
nwuse fromvars, nwclear
assert v2 == (_nwnode == "v3") if substr(_nwnode, 1, 1) == "v"
nwload fromvars
* a second network on the same nodes does not overwrite them
nwset, mat((0,0,0,1 \ 0,0,0,0 \ 0,0,0,0 \ 0,0,0,0)) name(same) labs(v1,v2,v3,v4) directed
capture nwload same
assert _rc == 110
assert v2 == (_nwnode == "v3") if substr(_nwnode, 1, 1) == "v"
* once changed they are not overwritten
replace v1 = 8 if substr(_nwnode, 1, 1) == "v"
capture nwload fromvars
assert _rc == 110
assert v1 == 8 if substr(_nwnode, 1, 1) == "v"

cd "`root'"
di "PASS test_edge_saveload"
